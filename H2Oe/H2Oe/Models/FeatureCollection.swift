//
//  QStations.swift
//  H2Oe
//
//  Created by Christina Moser on 19.12.25.
//

import Foundation

nonisolated struct FeatureCollection: Decodable, Sendable {
    let features: [StationDetails]
}

nonisolated struct StationDetails: Decodable, Identifiable, Hashable, Sendable {

    let id: String
    let dbmsnr: Int
    let name: String
    let hzbnr: Int
    let unit: String
    let waterBody: String
    let hydroService: String?
    let measuringPoint: String
    let parameter: String
    let value: Double
    let timeOfMeasurement: Date
    let lon: Double
    let lat: Double

    private enum RootKeys: String, CodingKey {
        case id
        case properties
    }

    private enum PropertiesKeys: String, CodingKey {
        case dbmsnr
        case hzbnr
        case gewaesser
        case hydrodienst
        case messstelle
        case parameter
        case wert
        case einheit
        case zeitpunkt
        case lon
        case lat
    }

    init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: RootKeys.self)

        id = try root.decode(String.self, forKey: .id)

        let props = try root.nestedContainer(keyedBy: PropertiesKeys.self, forKey: .properties)
        
        dbmsnr = try props.decode(Int.self, forKey: .dbmsnr)
        hzbnr = try props.decode(Int.self, forKey: .hzbnr)

        waterBody = try props.decode(String.self, forKey: .gewaesser)
        hydroService = try props.decodeIfPresent(String.self, forKey: .hydrodienst)

        measuringPoint = try props.decode(String.self, forKey: .messstelle)
        parameter = try props.decode(String.self, forKey: .parameter)

        unit = try props.decode(String.self, forKey: .einheit)

        let valueString = try props.decode(String.self, forKey: .wert)
            .replacingOccurrences(of: ",", with: ".")

        guard let parsedValue = Double(valueString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .wert,
                in: props,
                debugDescription: "Value is not convertible to Double"
            )
        }
        value = parsedValue

        let timeString = try props.decode(String.self, forKey: .zeitpunkt)

        /// formatter that converts between dates and their ISO 8601 string representations
        let formatterWithFraction = ISO8601DateFormatter()
        formatterWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let formatterNoFraction = ISO8601DateFormatter()
        formatterNoFraction.formatOptions = [.withInternetDateTime]

        if let date = formatterWithFraction.date(from: timeString) ?? formatterNoFraction.date(from: timeString) {
            timeOfMeasurement = date
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .zeitpunkt,
                in: props,
                debugDescription: "Invalid ISO8601 date format: \(timeString)"
            )
        }

        let lonString = try props.decode(String.self, forKey: .lon)
            .replacingOccurrences(of: ",", with: ".")

        let latString = try props.decode(String.self, forKey: .lat)
            .replacingOccurrences(of: ",", with: ".")

        guard let lonDouble = Double(lonString),
              let latDouble = Double(latString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .lon,
                in: props,
                debugDescription: "Coordinates not convertible to Double"
            )
        }

        lon = lonDouble
        lat = latDouble

        name = measuringPoint
    }
}
