//
//  ButtonsView.swift
//  H2Oe
//
//  Created by Christina Moser on 27.11.25.
//

import SwiftUI
import SwiftData
import DataProvider

struct FavoriteButton: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SchemaV1.FavoriteStation.name, animation: .smooth)
    private var favorites: [SchemaV1.FavoriteStation]
    
    let name: String
    let hzbnr: Int
    let unit: String
    let value: Double
    let lastTimeOfMeasurement: Date
    
    //check current station
    private var isFavorite: Bool {
        favorites.contains(where: { $0.hzbnr == hzbnr })
        
    }
    
    var body: some View {
        Button { toggleFavorite() } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.title3)
                .foregroundStyle(isFavorite ? .blue : .gray)
        }
        .buttonStyle(.plain)
    }
    
    @MainActor
    private func toggleFavorite() {
        do {
            let descriptor = FetchDescriptor<SchemaV1.FavoriteStation>(
                predicate: #Predicate { $0.hzbnr == hzbnr}
            )
            
            if let existing = try modelContext.fetch(descriptor).first {
                modelContext.delete(existing)
            } else {
                modelContext.insert(
                    SchemaV1.FavoriteStation(
                        name: name,
                        hzbnr: hzbnr,
                        unit: unit,
                        isFavorite: true,
                        initialValue: value,
                        lastTimeOfMeasurement: lastTimeOfMeasurement,
                    )
                )
            }
            
            try modelContext.save()
        } catch {
            print("Favorite toggle failed: \(error)")
        }
    }
}
