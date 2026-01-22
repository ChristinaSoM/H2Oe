//
//  GeosphereFeatureCollection.swift
//  H2Oe
//
//  Created by Christina Moser on 21.01.26.
//

import Foundation

//nonisolated: not bound to actor isolation
nonisolated struct GeosphereFeatureCollection: Decodable, Sendable {
    let timestamps: [Date]
    let features: [GeosphereFeature]
    
    private enum CodingKeys: String, CodingKey {
        case timestamps
        case features
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        let timestampStrings = try c.decode([String].self, forKey: .timestamps)

        timestamps = try timestampStrings.map { try GeosphereDateParser.parse($0) }

        
        features = try c.decode([GeosphereFeature].self, forKey: .features)
    }
}


nonisolated struct GeosphereFeature: Decodable, Identifiable, Hashable, Sendable {
    var id: Int { stationId }
    let stationId: Int
    let geometry: GeospherePointGeometry
    let parameters: [String: GeosphereParameterSeries]
    var lon: Double { geometry.lon }
    var lat: Double { geometry.lat }

    private enum CodingKeys: String, CodingKey {
        case geometry
        case properties
    }

    private enum PropertiesKeys: String, CodingKey {
        case parameters
        case station
    }

    init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: CodingKeys.self)

        geometry = try root.decode(GeospherePointGeometry.self, forKey: .geometry)

        let props = try root.nestedContainer(keyedBy: PropertiesKeys.self, forKey: .properties)
        stationId = try props.decode(Int.self, forKey: .station)

        parameters = try props.decode([String: GeosphereParameterSeries].self, forKey: .parameters)
    }
}

nonisolated struct GeospherePointGeometry: Decodable, Hashable, Sendable {
    let coordinates: [Double]

    var lat: Double { coordinates.count >= 2 ? coordinates[0] : .nan }
    var lon: Double { coordinates.count >= 2 ? coordinates[1] : .nan }

    private enum CodingKeys: String, CodingKey {
        case coordinates
    }
}


nonisolated struct GeosphereParameterSeries: Decodable, Hashable, Sendable {
    let name: String
    let unit: String
    let data: [Double?]

    private enum CodingKeys: String, CodingKey {
        case name
        case unit
        case data
    }
}


enum GeosphereDateParser {
    nonisolated static func parse(_ s: String) throws -> Date {
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]

        if let d = f1.date(from: s) ?? f2.date(from: s) {
            return d
        }

        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd'T'HH:mmXXXXX"

        if let d = df.date(from: s) {
            return d
        }

        throw DecodingError.dataCorrupted(
            .init(codingPath: [], debugDescription: "Invalid timestamp format: \(s)")
        )
    }
}

