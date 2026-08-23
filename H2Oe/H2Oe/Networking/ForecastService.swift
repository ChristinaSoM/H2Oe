//
//  ForecastService.swift
//  H2Oe
//
//  Client for the H2Oe Prognose-API (Ridge discharge/HQ forecast).
//  Primary path: fetchForecastsBatch(...) -> one request for all live stations
//  on app open, so the server's per-IP rate limit is never hit. The single
//  fetchForecast(...) is only a fallback (e.g. a favourite missing from the
//  batch, retried when its detail view opens). Every failure maps to a
//  ForecastError with a user-facing message.
//

import Alamofire
import Foundation

private let prognoseBaseURL = "https://h2oe-prognose.duckdns.org"

/// A forecast request failure, always carrying a message for the UI to show.
nonisolated enum ForecastError: LocalizedError, Sendable {
    case rateLimited
    case serviceUnavailable(Int)
    case timedOut
    case offline
    case transport(String)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .rateLimited:
            return "Too many requests — please wait a moment and try again."
        case .serviceUnavailable(let code):
            return "Forecast service unavailable (HTTP \(code)). Please try again later."
        case .timedOut:
            return "The forecast service took too long to respond. Please check your connection and try again."
        case .offline:
            return "No internet connection. Connect to a network to load the forecast."
        case .transport(let message):
            return "Could not reach the forecast service: \(message)"
        case .decoding(let message):
            return "Unexpected forecast response: \(message)"
        }
    }
}

/// Decoder configured for the API's ISO-8601-style (UTC) timestamps.
private let forecastDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
        let raw = try decoder.singleValueContainer().decode(String.self)
        guard let date = ForecastDateParser.date(from: raw) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath,
                      debugDescription: "Unrecognized date: \(raw)")
            )
        }
        return date
    }
    return decoder
}()

private func mapForecastError(_ error: AFError, statusCode: Int?) -> ForecastError {
    if statusCode == 429 { return .rateLimited }
    if let code = statusCode, code >= 500 { return .serviceUnavailable(code) }
    if case .responseSerializationFailed = error { return .decoding(error.localizedDescription) }
    if let urlError = error.underlyingError as? URLError {
        switch urlError.code {
        case .timedOut:
            return .timedOut
        case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost,
             .cannotFindHost, .dnsLookupFailed, .dataNotAllowed:
            return .offline
        default:
            break
        }
    }
    return .transport(error.localizedDescription)
}

/// Batch forecast for many stations in ONE request (primary path).
/// - Parameters:
///   - hzbnrs: HZB numbers of the stations to forecast.
///   - horizon: optional single lead time (0/24/48/72 h); omit for all four.
func fetchForecastsBatch(
    hzbnrs: [Int],
    horizon: Int? = nil,
    completionHandler: @escaping (Result<BatchForecastResponse, ForecastError>) -> Void
) {
    guard !hzbnrs.isEmpty else {
        completionHandler(.failure(.transport("no stations requested")))
        return
    }

    var parameters: [String: String] = [
        "stations": hzbnrs.map(String.init).joined(separator: ",")
    ]
    if let horizon { parameters["horizon"] = String(horizon) }

    AF.request(
        prognoseBaseURL + "/predict_batch",
        method: .get,
        parameters: parameters,
        encoding: URLEncoding.default
    )
    .validate(statusCode: 200..<300)
    .responseDecodable(of: BatchForecastResponse.self, decoder: forecastDecoder) { response in
        switch response.result {
        case .success(let data):
            completionHandler(.success(data))
        case .failure(let error):
            completionHandler(.failure(mapForecastError(error, statusCode: response.response?.statusCode)))
        }
    }
}

/// Single-station forecast — fallback only (e.g. a favourite missing from the
/// batch, retried on opening its detail view).
func fetchForecast(
    hzbnr: Int,
    horizon: Int? = nil,
    completionHandler: @escaping (Result<ForecastResponse, ForecastError>) -> Void
) {
    var parameters: [String: String] = ["station": String(hzbnr)]
    if let horizon { parameters["horizon"] = String(horizon) }

    AF.request(
        prognoseBaseURL + "/predict",
        method: .get,
        parameters: parameters,
        encoding: URLEncoding.default
    )
    .validate(statusCode: 200..<300)
    .responseDecodable(of: ForecastResponse.self, decoder: forecastDecoder) { response in
        switch response.result {
        case .success(let data):
            completionHandler(.success(data))
        case .failure(let error):
            completionHandler(.failure(mapForecastError(error, statusCode: response.response?.statusCode)))
        }
    }
}
