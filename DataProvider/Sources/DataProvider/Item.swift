//
//  Item.swift
//  H2Oe
//
//  Created by Christina Moser on 25.11.25.
//  Data Model


import Foundation
import SwiftData
import SwiftUI

public typealias Item = SchemaV1.Item

extension SchemaV1 {
    @Model  // SwiftData PersistentModel
    public final class Item {
        public var timestamp: Date
        public var createTimestamp: Date
        
        public init(timestamp: Date) {
            self.timestamp = timestamp
            createTimestamp = .now
        }
    }
}


public let previewContainer: ModelContainer = {
  let schema = Schema(CurrentScheme.models)
  let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
  do {
    return try ModelContainer(for: schema, configurations: [modelConfiguration])
  } catch {
    fatalError("Could not create ModelContainer: \(error)")
  }
}()
