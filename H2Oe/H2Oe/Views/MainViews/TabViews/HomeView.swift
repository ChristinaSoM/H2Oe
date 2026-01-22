//
//  HomeView.swift
//  H2Oe
//
//  Created by Christina Moser on 25.11.25.

import SwiftUI
import SwiftData
import DataProvider

struct HomeView: View {
    let stations: [StationDetails]
    let isLoading: Bool
    let errorText: String?
    
    @Query private var favorites: [SchemaV1.FavoriteStation]
    
    @State private var selectedStation: StationDetails?
    @State private var pushStation: StationDetails?
    @State private var mapRebuildToken = UUID()
    
    private var favoriteHzbnrs: Set<Int> {
        Set(favorites.map(\.hzbnr))
    }
    
    var body: some View {
        
        NavigationStack {
            VStack(alignment: .leading, spacing: 6) {
                
                Text("All water level measuring stations for Lower Austria are displayed here. For more information, simply tap on the station name.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 2)
                
                statusView
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)
                
                mapCard
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .frame(maxHeight: .infinity)
            }
            .padding(.top, 16)
            .padding(.bottom, 8)
            .navigationTitle("H2Ö")
            .navigationSubtitle("FLOOD INFORMATION FOR LOWER AUSTRIA")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(Color.cyan.opacity(0.15), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(item: $pushStation) { station in //if pushStation not nil -> navigation to detailView
                StationDetailView(station: station)
            }
            .sheet(item: $selectedStation) { station in  //is triggered as soon an new selectedSTation is tapped
                StationOverviewView(
                    station: station,
                    onMoreDetails: { station in
                        selectedStation = nil //sheet is closed
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { //wait 0.15 sec before setting pushStation -> which leads to navigation to detailView
                            pushStation = station
                        }
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .padding(.top, -90)
        .onAppear {
            mapRebuildToken = UUID()
        }
        .onChange(of: favorites.count) { _, _ in
            mapRebuildToken = UUID()
        }
    }
    
    
    private var statusView: some View {
        Group {
            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Loading stations…")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(.ultraThinMaterial, in: Capsule())
            } else if let errorText {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(errorText)
                        .font(.footnote)
                        .lineLimit(2)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(.ultraThinMaterial, in: Capsule())
            } else {
                EmptyView()
            }
        }
    }
    
    
    private var mapCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
            
            MapView(
                stations: stations,
                onSelectStation: { selectedStation = $0 },
                favoriteHzbnrs: favoriteHzbnrs
            )
            .id(mapRebuildToken)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.separator, lineWidth: 0.5)
        )
    }
}
    



//#Preview {
//    HomeView(stations: <#FeatureCollection?#>, isLoading: <#Bool#>, errorText: <#String?#>)
//        .modelContainer(DataProvider.previewContainer)
//}



