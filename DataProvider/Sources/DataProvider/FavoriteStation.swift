//
//  FavoriteStation.swift
//  DataProvider
//
//  Created by Christina Moser on 14.01.26.
//

import Foundation
import SwiftData

public typealias FavoriteStation = SchemaV1.FavoriteStation

extension SchemaV1 {
    @Model
    public final class FavoriteStation {
        
        @Attribute(.unique) public var hzbnr: Int
        public var name: String
        public var unit: String
        public var value: [Double]
        public var isFavorite: Bool
        public var lastTimeOfMeasurement: Date

        public init(
            name: String,
            hzbnr: Int,
            unit: String,
            isFavorite: Bool = false,
            initialValue: Double,
            lastTimeOfMeasurement: Date
        ) {
            self.hzbnr = hzbnr
            self.name = name
            self.unit = unit
            self.isFavorite = isFavorite
            self.lastTimeOfMeasurement = lastTimeOfMeasurement
            self.value = [initialValue]
        }
    }
}
