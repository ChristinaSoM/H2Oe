//
//  FloodWarningBadge.swift
//  H2Oe
//
//  Compact flood-warning pill (icon + HQ tag) on the app's glass material,
//  tinted by severity. Icon + text carry the meaning so it stays readable
//  without colour. Renders nothing for a clear station unless `showsClear`.
//

import SwiftUI

struct FloodWarningBadge: View {
    let warning: FloodWarning
    var showsClear: Bool = false

    var body: some View {
        if warning.isWarning || showsClear {
            HStack(spacing: 6) {
                Image(systemName: warning.symbolName)
                    .font(.caption.weight(.bold))
                Text(warning.shortLabel)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(warning.tint)
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(warning.tint.opacity(0.5), lineWidth: 1))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(warning.title)
        }
    }
}
