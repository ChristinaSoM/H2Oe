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
        case geometry
        case properties
    }

    private enum GeometryKeys: String, CodingKey {
        case coordinates
    }

    private enum PropertiesKeys: String, CodingKey {
        case hzbnr
        case gewaesser
        case hydrodienst
        case messstelle
        case parameter
        case wert
        case einheit
        case zeitpunkt
    }

    init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: RootKeys.self)

        id = try root.decode(String.self, forKey: .id)

        // GeoJSON geometry carries the coordinate pair as [lon, lat].
        let geometry = try root.nestedContainer(keyedBy: GeometryKeys.self, forKey: .geometry)
        let coordinates = try geometry.decode([Double].self, forKey: .coordinates)
        guard coordinates.count >= 2 else {
            throw DecodingError.dataCorruptedError(
                forKey: .coordinates,
                in: geometry,
                debugDescription: "Expected a [lon, lat] coordinate pair"
            )
        }
        lon = coordinates[0]
        lat = coordinates[1]

        let props = try root.nestedContainer(keyedBy: PropertiesKeys.self, forKey: .properties)

        hzbnr = try props.decode(Int.self, forKey: .hzbnr)
        waterBody = try props.decode(String.self, forKey: .gewaesser)
        hydroService = try props.decodeIfPresent(String.self, forKey: .hydrodienst)
        measuringPoint = try props.decode(String.self, forKey: .messstelle)
        parameter = try props.decode(String.self, forKey: .parameter)
        unit = try props.decode(String.self, forKey: .einheit)
        value = try props.decode(Double.self, forKey: .wert)

        let timeString = try props.decode(String.self, forKey: .zeitpunkt)

        /// Timestamps arrive as ISO-8601 with an offset ("…+02:00"); tolerate a
        /// fractional-seconds variant too.
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

        name = measuringPoint
    }
}
