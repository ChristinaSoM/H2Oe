//
//  FloodWarning.swift
//  H2Oe
//
//  Flood-warning severity for a station, derived from the forecast's HQ
//  flood-exceedance flags (see ForecastPrediction.hq). Warnings start at HQ5 —
//  HQ1 is routine high water. Higher return period = rarer = more severe:
//  HQ5 (watch) < HQ30 (warning) < HQ100+ (severe). Colour runs yellow → orange
//  → red; every level also carries an SF Symbol so severity never rests on
//  colour alone (WCAG 1.4.1).
//

import SwiftUI
import DataProvider

nonisolated enum FloodWarningLevel: Int, Comparable, CaseIterable, Sendable {
    case none = 0
    case moderate   // >= HQ5
    case high       // >= HQ30
    case severe     // >= HQ100

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Warning band for an HQ return period in years. Warnings begin at HQ5.
    static func forReturnPeriod(_ years: Int) -> FloodWarningLevel {
        switch years {
        case ..<5: return .none
        case 5 ..< 30: return .moderate
        case 30 ..< 100: return .high
        default: return .severe
        }
    }

    /// Vivid yellow→orange→red scale, tuned down from the pure hues for legibility.
    var tint: Color {
        switch self {
        case .none: return .green
        case .moderate: return Color(red: 0.88, green: 0.63, blue: 0.00) // amber
        case .high: return Color(red: 0.90, green: 0.42, blue: 0.09)     // orange
        case .severe: return Color(red: 0.78, green: 0.12, blue: 0.12)   // red
        }
    }

    /// SF Symbol reinforcing severity independent of colour.
    var symbolName: String {
        switch self {
        case .none: return "checkmark.circle.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .severe: return "exclamationmark.octagon.fill"
        }
    }
}

/// A station's worst flood warning across all forecast horizons.
nonisolated struct FloodWarning: Hashable, Sendable {

    let level: FloodWarningLevel
    /// Highest exceeded HQ return period in years (nil when there is no warning).
    let returnPeriod: Int?

    static let none = FloodWarning(level: .none, returnPeriod: nil)

    var isWarning: Bool { level != .none }

    var tint: Color { level.tint }
    var symbolName: String { level.symbolName }

    /// Short tag, e.g. "HQ30". "No warning" when clear.
    var shortLabel: String {
        guard let returnPeriod else { return "No warning" }
        return "HQ\(returnPeriod)"
    }

    /// Sentence for headers/accessibility, e.g. "Flood warning: HQ30 exceeded".
    var title: String {
        switch level {
        case .none: return "No flood warning"
        case .moderate: return "Flood watch: HQ\(returnPeriod ?? 5) exceeded"
        case .high, .severe: return "Flood warning: HQ\(returnPeriod ?? 100) exceeded"
        }
    }

    /// Derives the worst warning from a station forecast. Only HQ levels whose
    /// flag is set and whose return period is >= 5 (HQ5) count as a warning.
    init(forecast: StationForecast?) {
        var maxYears: Int?
        for prediction in forecast?.predictions ?? [] {
            guard let hq = prediction.hq else { continue }
            for (key, hqLevel) in hq where hqLevel.flag {
                guard let years = FloodWarning.returnPeriod(fromKey: key), years >= 5 else { continue }
                maxYears = Swift.max(maxYears ?? years, years)
            }
        }
        self.returnPeriod = maxYears
        self.level = maxYears.map(FloodWarningLevel.forReturnPeriod) ?? .none
    }

    /// Derives the worst warning from a persisted (offline) forecast — used where
    /// only the last-known StoredForecast is available (e.g. the favourites list).
    init(stored: StoredForecast?) {
        var maxYears: Int?
        for point in stored?.points ?? [] {
            for (key, flag) in point.floodFlags ?? [:] where flag {
                guard let years = FloodWarning.returnPeriod(fromKey: key), years >= 5 else { continue }
                maxYears = Swift.max(maxYears ?? years, years)
            }
        }
        self.returnPeriod = maxYears
        self.level = maxYears.map(FloodWarningLevel.forReturnPeriod) ?? .none
    }

    private init(level: FloodWarningLevel, returnPeriod: Int?) {
        self.level = level
        self.returnPeriod = returnPeriod
    }

    /// Parses the integer return period from an HQ key ("HQ5", "hq30", "HQ_100" → 5/30/100).
    static func returnPeriod(fromKey key: String) -> Int? {
        let digits = key.filter(\.isNumber)
        return digits.isEmpty ? nil : Int(digits)
    }
}
