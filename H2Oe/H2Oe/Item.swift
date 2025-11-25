//
//  Item.swift
//  H2Oe
//
//  Created by Christina Moser on 25.11.25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
