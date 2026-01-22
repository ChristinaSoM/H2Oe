//
//  FavoritesView.swift
//  H2Oe
//
//  Created by Christina Moser on 12.01.26.
//

import SwiftUI
import SwiftData
import DataProvider

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    
    //When favorites are added/removed, this list updates immediately -> .smooth. Sort by name
    @Query(sort: \SchemaV1.FavoriteStation.name, animation: .smooth)
    private var favorites: [SchemaV1.FavoriteStation]

    var body: some View {
        NavigationStack {
            List {
                if favorites.isEmpty {
                    Text("No favorites yet. Tap the star on a station.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(favorites, id: \SchemaV1.FavoriteStation.hzbnr) { fav in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(fav.name)
                                    .font(.headline)

                                Text("HZBNR: \(String(fav.hzbnr))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if let latest = fav.value.last {
                                    Text("Flow rate: \(latest, specifier: "%.2f") \(fav.unit)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Flow rate: — \(fav.unit)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Text("Measured at: \(fav.lastTimeOfMeasurement.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            FavoriteButton(
                                name: fav.name,
                                hzbnr: fav.hzbnr,
                                unit: fav.unit,
                                value: fav.value.last ?? 0,
                                lastTimeOfMeasurement: fav.lastTimeOfMeasurement
                            )
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Favorites")
        }
    }
}
