//
//  ForecastResponse.swift
//  H2Oe
//
//  Models for the H2Oe Prognose-API: discharge Q plus HQ flood-exceedance
//  forecast per horizon (0/24/48/72 h). Decoded from the JSON returned by
//  GET /predict (single station) and GET /predict_batch (many stations).
//

import Foundation

/// Per-HQ-level flood-exceedance probability plus the VAL-tuned yes/no flag.
nonisolated struct ForecastHQLevel: Decodable, Hashable, Sendable {
    let prob: Double
    let flag: Bool
    let threshold: Double
}

/// One horizon of a forecast: discharge Q (m3/s) and, when the serving model
/// carries the HQ head, the flood-exceedance per HQ level (HQ1/HQ5/HQ30/HQ100).
nonisolated struct ForecastPrediction: Decodable, Identifiable, Hashable, Sendable {
    var id: Int { horizonH }
    let station: String
    let issueTime: Date
    let validTime: Date
    let horizonH: Int
    let qPred: Double
    let hq: [String: ForecastHQLevel]?

    private enum CodingKeys: String, CodingKey {
        case station
        case issueTime = "issue_time"
        case validTime = "valid_time"
        case horizonH = "horizon_h"
        case qPred = "q_pred"
        case hq
    }
}

/// Response of the single-station endpoint `GET /predict`.
nonisolated struct ForecastResponse: Decodable, Sendable {
    let station: String
    let issuedAt: Date
    let cached: Bool
    let count: Int
    let predictions: [ForecastPrediction]

    private enum CodingKeys: String, CodingKey {
        case station
        case issuedAt = "issued_at"
        case cached
        case count
        case predictions
    }
}

/// One station's entry in the batch response. `ok == false` carries `error`
/// (e.g. an unknown station or a temporarily unavailable live feed) while the
/// rest of the batch still succeeds.
nonisolated struct StationForecast: Decodable, Identifiable, Hashable, Sendable {
    var id: String { station }
    let station: String
    let ok: Bool
    let cached: Bool?
    let predictions: [ForecastPrediction]?
    let error: String?

    /// HZB number parsed from the station stem ("Q207241__..." -> 207241).
    var hzbnr: Int? {
        guard station.hasPrefix("Q") else { return nil }
        return Int(station.dropFirst().prefix { $0.isNumber })
    }
}

/// Response of the multi-station endpoint `GET /predict_batch` (the app's
/// primary path: one request for all live stations on app open).
nonisolated struct BatchForecastResponse: Decodable, Sendable {
    let issuedAt: Date
    let count: Int
    let okCount: Int
    let results: [StationForecast]

    private enum CodingKeys: String, CodingKey {
        case issuedAt = "issued_at"
        case count
        case okCount = "ok_count"
        case results
    }

    /// Successful forecasts keyed by HZB number for O(1) lookup in the UI.
    var byHzbnr: [Int: StationForecast] {
        var out: [Int: StationForecast] = [:]
        for result in results where result.ok {
            if let hzbnr = result.hzbnr { out[hzbnr] = result }
        }
        return out
    }
}

/// Parses the API's ISO-8601-style timestamps. The service emits naive UTC
/// ("2026-08-22T22:00:00"); the offset/fractional variants are tolerated too.
enum ForecastDateParser {
    /// The service emits naive UTC ("2026-08-22T22:00:00"); offset/fractional
    /// variants are tolerated too. Formatters are built per call (like
    /// GeosphereDateParser) to avoid non-Sendable shared static state.
    nonisolated static func date(from raw: String) -> Date? {
        let naive = DateFormatter()
        naive.calendar = Calendar(identifier: .gregorian)
        naive.locale = Locale(identifier: "en_US_POSIX")
        naive.timeZone = TimeZone(secondsFromGMT: 0)
        naive.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = naive.date(from: raw) { return date }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: raw) { return date }

        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: raw)
    }
}
