//
//  FloodWarningBadge.swift
//  H2Oe
//
//  Compact flood-warning pill on the app's glass material, tinted by severity.
//  Icon + text carry the meaning so it stays readable without colour (WCAG
//  1.4.1). Derives its state from the station forecast:
//    • a warning (HQ5+)      -> yellow/orange/red pill
//    • forecast present, clear -> green "No warning" (only when showsWhenClear)
//    • no/failed forecast    -> grey "Forecast unavailable" (only when showsWhenClear)
//  In compact contexts (lists) it renders nothing unless there is a warning.
//

import SwiftUI

struct FloodWarningBadge: View {
    let forecast: StationForecast?
    var showsWhenClear: Bool = false

    var body: some View {
        let warning = FloodWarning(forecast: forecast)
        let available = (forecast?.ok ?? false) && !(forecast?.predictions?.isEmpty ?? true)

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
