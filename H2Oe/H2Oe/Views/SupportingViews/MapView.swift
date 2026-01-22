//
//  MapView.swift
//  H2Oe
//
//  Created by Christina Moser on 27.11.25.
//

import MapKit
import SwiftUI

struct MapView: View {
    
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 48.2, longitude: 15.8),  //center of NÖ
            span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2.8)
        )
    )
    @State private var selectedStationId: StationDetails.ID?
    
    let stations: [StationDetails]
    let onSelectStation: (StationDetails) -> Void
    let favoriteHzbnrs: Set<Int>
    
    
    var body: some View {
        Map(position: $position, interactionModes: .zoom, selection: $selectedStationId) {
            ForEach(stations) { station in
                let coordinate = CLLocationCoordinate2D(latitude: station.lat, longitude: station.lon)
                let isFav = favoriteHzbnrs.contains(station.hzbnr)
                
                Marker(station.name, coordinate: coordinate)
                    .tint(isFav ? .blue : .cyan)
                    .tag(station.id)
                
                //                Annotation(station.name, coordinate: coordinate, anchor: .top) {
                //                    HStack(spacing: 8) {
                //                        Text(station.name)
                //                            .font(.caption)
                //                            .lineLimit(1)
                //
                //                        Image(systemName: "info.circle")
                //                                    .font(.caption)
                //                                    .foregroundStyle(.secondary)
                //                    }
                //                    .padding(.horizontal, 10)
                //                    .padding(.vertical, 6)
                //                    .background(.ultraThickMaterial)
                //                    .clipShape(Capsule())
                //                    .overlay(
                //                        Capsule().strokeBorder(.separator, lineWidth: 0.5)
                //                    )
                //                    .contentShape(Capsule())
                //                    .onTapGesture {
                //                        onSelectStation(station)
                //                    }
                //                }
                //                .annotationTitles(.hidden)
                
            }
        }
        .onChange(of: selectedStationId) { _, newId in
            guard let newId,let station = stations.first(where: { $0.id == newId }) else { return }
            
            onSelectStation(station)
        }
        .mapStyle(.hybrid)
    }
}
