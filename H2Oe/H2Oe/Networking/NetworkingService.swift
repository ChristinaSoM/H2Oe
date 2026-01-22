//
//  NetworkingService.swift
//  H2Oe
//
//  Created by Christina Moser on 19.12.25.
//

import Alamofire
import Foundation


private let wfsBaseURL = "https://gis.lfrz.gv.at/wmsgw/"

private var wfsApiKey: String {
    guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "WFS_API_KEY") as? String else {
        fatalError("plist file not found")
    }
    return apiKey
}

///Data source: Bundesministerium für Land- und Forstwirtschaft, Klima- und Umweltschutz, Regionen und Wasserwirtschaft
///https://gis.lfrz.gv.at/wmsgw/?key=a64a0c9c9a692ed7041482cb6f03a40a&VERSION=2.0.0&REQUEST=GetCapabilities&SERVICE=WFS
///https://geoportal.inspire.gv.at/metadatensuche/inspire/api/records/9f700f35-c02f-42d3-99b8-28f23ee9bba5
private var wfsParameters: [String: String] {
    [
        "key": wfsApiKey,
        "SERVICE": "WFS",
        "REQUEST": "GetFeature",
        "VERSION": "2.0.0",
        "TYPENAMES": "pegelaktuell",
        "SRSNAME": "EPSG:4326",
        "OUTPUTFORMAT": "application/json",
        /// Currently, it is acceptable for me that only stations containing parameters and values are displayed:
        "CQL_FILTER": "hydrodienst='Niederösterreich' AND parameter='Q' AND wert IS NOT NULL",
    ]
}


func fetchCurrentQStations(completionHandler: @escaping (Result<FeatureCollection, Error>) -> Void) {
    AF.request(
        wfsBaseURL,
        method: .get,
        parameters: wfsParameters,
        encoding: URLEncoding.default
    )
    .validate(statusCode: 200..<300)  //if error/no success: no decoding
    .responseDecodable(of: FeatureCollection.self) { response in   //JSONDecoder()

        switch response.result {
        case .success(let data):
            print("Decoded features: \(data.features.count)")
            completionHandler(.success(data))

        case .failure(let error):
            if let statusCode = response.response?.statusCode {
                print("HTTP status: \(statusCode)")
            }
            
            if let afError = error.asAFError {
                        print("AFError: \(afError)")
                        if let underlying = afError.underlyingError {
                            print("Underlying error: \(underlying)")
                        }
                    } else {
                        print("Error: \(error)")
                    }

            if let data = response.data,
               let text = String(data: data, encoding: .utf8) {
                print("Body:\n\(text)")
            }

            completionHandler(.failure(error))
        }
    }
}


private let geosphereBaseURL = "https://dataset.api.hub.geosphere.at/v1/station/historical/klima-v2-10min"

/// Formats a Date as YYYY-MM-DD in UTC (what API expects for start/end).
private func formatAsYYYYMMDDUTC(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}


func fetchHistoricalGeosphereStations(
    stationIds: [Int],
    start: Date,
    parameters: [String] = ["ff","p","rf","rr","rrm","sh","so","tb10","tb20","tl"],
    completionHandler: @escaping (Result<GeosphereFeatureCollection, Error>) -> Void
) {
    let startStr = formatAsYYYYMMDDUTC(start)
    let endStr = formatAsYYYYMMDDUTC(Date()) // always today

    // Geosphere endpoint expects comma-separated station_ids and parameters
    let params: [String: String] = [
        "station_ids": stationIds.map(String.init).joined(separator: ","),
        "start": startStr,
        "end": endStr,
        "parameters": parameters.joined(separator: ","),
        "output_format": "geojson"
    ]

    AF.request(
        geosphereBaseURL,
        method: .get,
        parameters: params,
        encoding: URLEncoding.default
    )
    .validate(statusCode: 200..<300)
    .responseDecodable(of: GeosphereFeatureCollection.self) { response in
        switch response.result {
        case .success(let data):
            completionHandler(.success(data))

        case .failure(let error):
            if let statusCode = response.response?.statusCode {
                print("HTTP status: \(statusCode)")
            }

            if let afError = error.asAFError {
                print("AFError: \(afError)")
                if let underlying = afError.underlyingError {
                    print("Underlying error: \(underlying)")
                }
            } else {
                print("Error: \(error)")
            }

            if let data = response.data,
               let text = String(data: data, encoding: .utf8) {
                print("Body:\n\(text)")
            }

            completionHandler(.failure(error))
        }
    }
}

