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
    
    public actor DataHandler {
        private let container: ModelContainer
        
        public init(modelContainer: ModelContainer) {
            self.container = modelContainer
        }
        
        @discardableResult
        public func newItem(date: Date) async throws -> PersistentIdentifier {
            return try await MainActor.run {
                let item = Item(timestamp: date)
                container.mainContext.insert(item)
                try container.mainContext.save()
                return item.persistentModelID
            }
        }
        
        public func updateItem(id: PersistentIdentifier, timestamp: Date) async throws {
            try await MainActor.run {
                let fetch = FetchDescriptor<Item>()
                let items = try container.mainContext.fetch(fetch)
                guard let item = items.first(where: { $0.persistentModelID == id }) else {
                    throw DataHandlerError.itemNotFound(id: id)
                    return
                }
                item.timestamp = timestamp
                try container.mainContext.save()
            }
        }
        
        public func deleteItem(id: PersistentIdentifier) async throws {
            try await MainActor.run {
                let fetch = FetchDescriptor<Item>()
                let items = try container.mainContext.fetch(fetch)
                guard let item = items.first(where: { $0.persistentModelID == id }) else {
                    throw DataHandlerError.itemNotFound(id: id)
                }
                container.mainContext.delete(item)
                try container.mainContext.save()
            }
        }
    }
}

// MARK: - DataHandler creator, environment key and preview container (file scope)

// a function to create a handler ...for use in H2OeApp - used for View dependencies where concurrency and sendable is requrired
public func makeDataHandlerFactory(using container: ModelContainer) -> @Sendable () async -> SchemaV1.DataHandler {
  return { SchemaV1.DataHandler(modelContainer: container) }
}

public struct DataHandlerKey: EnvironmentKey {
  public static let defaultValue: @Sendable () async -> SchemaV1.DataHandler? = { nil }
}

extension EnvironmentValues {
  public var createDataHandler: @Sendable () async -> SchemaV1.DataHandler? {
    get { self[DataHandlerKey.self] }
    set { self[DataHandlerKey.self] = newValue }
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
