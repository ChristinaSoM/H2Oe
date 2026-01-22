//
//  StationOverviewData.swift
//  H2Oe
//
//  Created by Christina Moser on 16.01.26.
//


import SwiftUI
import MapKit

struct StationOverviewView: View {
    
    let station: StationDetails
    let onMoreDetails: (StationDetails) -> Void  //callback function (back to homeview and pushStation navigation and close sheet) if user wants more information
    
    @State private var position: MapCameraPosition
    
    //position depends on station -> therefore:
    init(station: StationDetails, onMoreDetails: @escaping (StationDetails) -> Void) {
        self.station = station
        self.onMoreDetails = onMoreDetails
        
        let center = CLLocationCoordinate2D(latitude: station.lat, longitude: station.lon)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 1_000, longitudinalMeters: 1_000)
        _position = State(initialValue: .region(region))
    }
    
    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: station.lat, longitude: station.lon)
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 14) {
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack{
                        Text(station.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.top, 10)
                            .padding(.bottom, 2)
                        
                        Spacer()
                        
                        FavoriteButton(
                            name: station.name,
                            hzbnr: station.hzbnr,
                            unit: station.unit,
                            value: station.value,
                            lastTimeOfMeasurement: station.timeOfMeasurement
                        )
                    }
                }
                VStack(alignment: .leading) {
                    Text("HZBNR \(String(station.hzbnr))")
                        .font(.footnote)
                        .foregroundStyle(.primary)
                    
                    HStack {
                        
                        Text("Waterbody")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text(station.waterBody)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        
                    }
                }
            }
            
            infoCard {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Measured flow rate")
                            .font(.footnote)
                            .foregroundStyle(.primary)
                        
                        Text("\(station.value, specifier: "%.2f") \(station.unit)")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                
                Divider().padding(.vertical, 2)
                
                HStack {
                    Text("Timestamp")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(station.timeOfMeasurement.formatted(date: .abbreviated, time: .shortened))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            
            mapCard
            
            navigationToDetails
            
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }



    private func infoCard(@ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.separator, lineWidth: 0.5)
        )
    }

    private var mapCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Location")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)

                Map(position: $position, interactionModes: [.zoom, .rotate, .pan]) {
                    Marker(station.name, coordinate: coordinate)
                        .tint(.cyan)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.separator, lineWidth: 0.5)
            )
        }
    }
    
    private var navigationToDetails: some View {
        Button {
            onMoreDetails(station)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "info.circle")
                    .font(.headline)
                    .foregroundStyle(.cyan)

                Text("More details")
                    .font(.headline)
                    .foregroundStyle(.cyan)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.cyan.opacity(0.8))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule().strokeBorder(.separator, lineWidth: 0.6)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(.bottom, 8)
    }
}
