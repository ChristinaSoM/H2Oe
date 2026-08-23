//
//  FloodWarningBadge.swift
//  H2Oe
//
//  Compact flood-warning pill on the app's glass material, tinted by severity.
//  Icon + text carry the meaning so it stays readable without colour (WCAG
//  1.4.1). Two sources:
//    • init(forecast:) — the live ForecastStore entry (map, detail, list, sheet)
//    • init(stored:)   — the persisted offline forecast (favourites list)
//  States: a warning (HQ5+) -> yellow/orange/red; forecast present & clear ->
//  green "No warning" (only when showsWhenClear); no/failed forecast -> grey
//  "Forecast unavailable" (only when showsWhenClear). In compact contexts it
//  renders nothing unless there is a warning.
//

import SwiftUI
import DataProvider

struct FloodWarningBadge: View {
    private let warning: FloodWarning
    private let available: Bool
    private let showsWhenClear: Bool

    init(forecast: StationForecast?, showsWhenClear: Bool = false) {
        self.warning = FloodWarning(forecast: forecast)
        self.available = (forecast?.ok ?? false) && !(forecast?.predictions?.isEmpty ?? true)
        self.showsWhenClear = showsWhenClear
    }

    init(stored: StoredForecast?, showsWhenClear: Bool = false) {
        self.warning = FloodWarning(stored: stored)
        self.available = !(stored?.points.isEmpty ?? true)
        self.showsWhenClear = showsWhenClear
    }

    var body: some View {
        if warning.isWarning {
            pill(symbol: warning.symbolName, text: warning.shortLabel,
                 tint: warning.tint, label: warning.title)
        } else if showsWhenClear && available {
            pill(symbol: "checkmark.circle.fill", text: "No warning",
                 tint: .green, label: "No flood warning")
        } else if showsWhenClear {
            pill(symbol: "clock.badge.questionmark", text: "Forecast unavailable",
                 tint: .secondary, label: "Forecast currently unavailable")
        }
    }

    private func pill(symbol: String, text: String, tint: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.caption.weight(.bold))
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(tint)
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .frame(minHeight: 28)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(tint.opacity(0.5), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}
