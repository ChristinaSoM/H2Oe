//
//  ContentView.swift
//  H2Oe
//
//  Created by Christina Moser on 12.01.26.
//
// https://www.youtube.com/watch?v=Yg3cmpKNieU

import SwiftUI
import SwiftData
import DataProvider


enum Tabs {
    case home, favorites, stations, info
}

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \SchemaV1.FavoriteStation.name, animation: .smooth)
    private var favorites: [SchemaV1.FavoriteStation]
    
    @State private var stations: [StationDetails] = []
    @State private var errorText: String?
    @State private var isLoading = false
    @State private var selectedTab: Tabs = .home
    

    var body: some View {
        TabView (selection: $selectedTab) {
            Tab("Map", systemImage: "map", value: Tabs.home) {
                HomeView(stations: stations, isLoading: isLoading, errorText: errorText)
            }
            
            Tab("Favorites", systemImage: "star", value: Tabs.favorites) {
                FavoritesView()
            }
            
            Tab("Stations", systemImage: "antenna.radiowaves.left.and.right", value: Tabs.stations) {
                StationsListView(stations: stations)
            }
            
            Tab("Info", systemImage: "info.circle", value: Tabs.info) {
                InfoView()
            }
        }
        .task { //executes if view appears
            await loadingData()
        }
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }

    @MainActor
    private func loadingData() async {
        guard stations.isEmpty else { return }
        guard !isLoading else { return }

        isLoading = true
        errorText = nil

        await withCheckedContinuation { continuation in   //wait until continuation.resume() is called
            fetchCurrentQStations { result in
                DispatchQueue.main.async {
                    isLoading = false
                    switch result {
                    case .success(let data):
                        stations = data.features
                        Task { @MainActor in  //extra task for not blocking the UI
                            await updateFavoritesFromStations(stations)
                        }
                    case .failure(let error):
                        stations = []
                        errorText = error.localizedDescription
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    @MainActor
    private func updateFavoritesFromStations(_ stations: [StationDetails]) async {
        do {
            let repo = FavoriteStationRepository(context: modelContext)

            //set of hzbnr ids for fast lookups
            let favHzbnrs = Set(favorites.map(\.hzbnr))

            for s in stations where favHzbnrs.contains(s.hzbnr) {
                try repo.updateFavoriteStation(
                    name: s.name,
                    hzbnr: s.hzbnr,
                    unit: s.unit,
                    newValue: s.value,
                    lastTimeOfMeasurement: s.timeOfMeasurement,
                    isFavorite: true
                )
            }
        } catch {
            print("Failed to refresh favorite values: \(error)")
        }
    }
}



#Preview {
    ContentView()
}

