//
//  StationListView.swift
//  H2Oe
//
//  Created by Christina Moser on 27.11.25.
//

import SwiftUI
import SwiftData
import DataProvider

struct StationsListView: View {
    
    let stations: [StationDetails]
    @State private var searchString = ""
    
    private var sortedStations: [StationDetails] {
        stations.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
    
    private var filteredStations: [StationDetails] {
        let query = searchString.trimmingCharacters(in: .whitespacesAndNewlines)  //ignore whitespaces at the beginning/end
        guard !query.isEmpty else { return sortedStations }
        
        return sortedStations.filter { station in
            station.name.localizedCaseInsensitiveContains(query) ||
            station.waterBody.localizedCaseInsensitiveContains(query) ||
            String(station.hzbnr).contains(query)
        }
    }
    
    var body: some View {
        
        NavigationStack {
            List {
                if stations.isEmpty {
                    Text("No stations available.")
                        .foregroundStyle(.secondary)
                } else if filteredStations.isEmpty {
                    Text("No results. Try another search term.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredStations) { station in
                        NavigationLink {
                            StationDetailView(station: station)
                        } label: {
                            rowItem(station)
                        }
                    }
                }
            }
            .navigationTitle("Measuring stations")
            .navigationSubtitle(stationCount)
            .safeAreaInset(edge: .top) { //search bar is fixed
                searchBar
            }
        }
    }
    
    private var stationCount: String {
        if searchString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(stations.count) stations"
        } else {
            return "\(filteredStations.count) of \(stations.count) stations"
        }
    }

    
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search", text: $searchString)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .submitLabel(.search)  //submit button on keyboard
            
            if !searchString.isEmpty {
                Button {
                    searchString = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule().strokeBorder(.separator, lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
    
    
    private func rowItem(_ station: StationDetails) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(station.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                VStack(spacing: 10) {
                    HStack {
                        Text("HZBNR")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(String(station.hzbnr))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Text("Water body")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(station.waterBody)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                HStack(spacing: 6) {
                    Text("Measured:")
                        .font(.footnote)
                        .foregroundStyle(.primary)
                    
                    Text("\(station.value, specifier: "%.2f") \(station.unit)")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 6) {
                    Text("Timestamp:")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    Text(station.timeOfMeasurement.formatted(date: .abbreviated, time: .shortened))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            FavoriteButton(
                name: station.name,
                hzbnr: station.hzbnr,
                unit: station.unit,
                value: station.value,
                lastTimeOfMeasurement: station.timeOfMeasurement,
            )
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

#Preview {
    StationsListView(stations: [])
}
