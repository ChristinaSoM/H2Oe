//
//  StationLocation.swift
//  H2Oe
//
//  Created by Christina Moser on 27.11.25.
//

import MapKit

struct StationLocation: Identifiable {
    let id = UUID()
    var name: String
    var coordinate: CLLocationCoordinate2D
}
