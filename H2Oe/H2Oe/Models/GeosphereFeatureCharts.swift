//
//  Untitled.swift
//  H2Oe
//
//  Created by Christina Moser on 21.01.26.
//


import Foundation

struct TimeValuePoint: Identifiable, Hashable {
    let id = UUID()
    let time: Date
    let value: Double
}

extension GeosphereFeature {
    
    /// Returns a time series
    func seriesPoints(for parameterKey: String,timestamps: [Date]) -> [TimeValuePoint] {
        
        guard let series = parameters[parameterKey] else { return [] }
        
        let count = min(timestamps.count, series.data.count)
        
        var points: [TimeValuePoint] = []
        //optimizes storage:
        points.reserveCapacity(count)
        
        for i in 0..<count {
            if let v = series.data[i] {
                points.append(TimeValuePoint(time: timestamps[i], value: v))
            }
        }
        
        return points
    }
    
    func latestValueAndTime(for parameterKey: String, timestamps: [Date]) -> (value: Double, time: Date)? {
        guard let series = parameters[parameterKey] else { return nil }
        
        let count = min(series.data.count, timestamps.count)
        guard count > 0 else { return nil }
        
        // find last non-nil value
        for i in stride(from: count - 1, through: 0, by: -1) {
            if let v = series.data[i] {
                return (v, timestamps[i])
            }
        }
        return nil
    }
    
    static let englishParameterNames: [String: String] = [
        "ff": "Wind speed",
        "p": "Air pressure",
        "rf": "Relative humidity",
        "rr": "Precipitation amount",
        "rrm": "Precipitation duration",
        "sh": "Snow depth (total)",
        "so": "Sunshine duration",
        "tb10": "Soil temperature (-10 cm)",
        "tb20": "Soil temperature (-20 cm)",
        "tl": "Air temperature"
    ]
    
    func displayNameEN(for parameterKey: String) -> String {
        if let en = Self.englishParameterNames[parameterKey] { return en }
        if let apiName = parameters[parameterKey]?.name { return apiName }
        return parameterKey
    }
    
    func unit(for parameterKey: String) -> String? {
        parameters[parameterKey]?.unit
    }
}
