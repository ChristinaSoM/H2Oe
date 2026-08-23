//
//  StoredForecast.swift
//  DataProvider
//
//  Last-known Prognose-API forecast persisted alongside a favourite station
//  (SwiftData Codable attribute), so favourites keep their most recent q/HQ
//  values offline — mirroring how the station's measured values are stored.
//

import Foundation

public struct StoredForecast: Codable, Hashable, Sendable {

    /// One horizon: discharge Q plus optional HQ flood-exceedance flags.
    public struct Point: Codable, Hashable, Sendable {
        public let horizonH: Int
        public let qPred: Double
        public let floodFlags: [String: Bool]?   // e.g. ["HQ1": true, "HQ5": false]

        public init(horizonH: Int, qPred: Double, floodFlags: [String: Bool]? = nil) {
            self.horizonH = horizonH
            self.qPred = qPred
            self.floodFlags = floodFlags
        }
    }

    public let issuedAt: Date
    public let points: [Point]

    public init(issuedAt: Date, points: [Point]) {
        self.issuedAt = issuedAt
        self.points = points
    }
}
