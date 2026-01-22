//
//  GeosphereParameterCard.swift
//  H2Oe
//
//  Created by Christina Moser on 21.01.26.
//


import SwiftUI
import Charts
import DataProvider

struct GeosphereParameterCard: View {
    let title: String
    let unit: String
    let latestValue: Double?
    let latestTime: Date?
    let points: [TimeValuePoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Spacer()

                VStack(alignment: .leading) {
                    if let latestValue {
                        Text("\(latestValue, specifier: "%.2f") \(unit)")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    } else {
                        Text("— \(unit)")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }

                    if let latestTime {
                        Text(latestTime.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if points.isEmpty {
                Text("No data in selected range.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Chart(points) { p in
                    LineMark(
                        x: .value("Time", p.time),
                        y: .value("Value", p.value)
                    )
                }
                .frame(height: 160)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
