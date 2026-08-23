//
//  NetworkingService.swift
//  H2Oe
//
//  Created by Christina Moser on 19.12.25.
//

import Alamofire
import Foundation


// Current gauge readings for Austria via the LFRZ "pegel_aktuell" OGC API
// Features service (the former wmsgw WFS gateway was retired). No API key is
// required. Data source: Bundesministerium für Land- und Forstwirtschaft,
// Klima- und Umweltschutz, Regionen und Wasserwirtschaft (CC BY 4.0).
private let pegelBaseURL = "https://gis.lfrz.gv.at/api/geodata/i000501/ogc/features/v1/collections/i000501:pegel_aktuell/items"

private var pegelParameters: [String: String] {
    [
        "f": "json",
        "limit": "1000",
        "filter-lang": "cql2-text",
        // Only Lower-Austrian discharge (Q) stations that currently report a value.
        "filter": "parameter='Q' AND hydrodienst='Niederösterreich' AND wert IS NOT NULL",
    ]
}


func fetchCurrentQStations(completionHandler: @escaping (Result<FeatureCollection, Error>) -> Void) {
    AF.request(
        pegelBaseURL,
        method: .get,
        parameters: pegelParameters,
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

