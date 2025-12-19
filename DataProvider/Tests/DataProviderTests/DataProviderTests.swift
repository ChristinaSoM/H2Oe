//
//  DataProviderTests.swift
//  DataProvider
//
//  Created by Christina Moser on 25.11.25.
//

import Foundation
import Testing
import SwiftData
@testable import DataProvider


struct SwiftDataContainerForTest  {
  static func temp(_ name: String, delete: Bool = true) throws -> ModelContainer {
    let url = URL.temporaryDirectory.appending(component: name)
    if delete, FileManager.default.fileExists(atPath: url.path) {
      try FileManager.default.removeItem(at: url)
    }
    let schema = Schema(CurrentScheme.models)
    let configuration = ModelConfiguration(url: url)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    return container
  }
}


@MainActor
struct DataProviderTests {
    
    @Test func testNewItem() async throws {
        // Arrange
        let container = try SwiftDataContainerForTest.temp(#function)
        let handler = CurrentScheme.DataHandler(modelContainer: container)
        
        // Act
        let date = Date(timeIntervalSince1970: 0)
        try await handler.newItem(date: date)
        
        // Assert
        let fetchDescriptor = FetchDescriptor<CurrentScheme.Item>()
        let items = try container.mainContext.fetch(fetchDescriptor)
        
        try #require(items.first != nil)
        #expect(items.count == 1)
        
        let firstItem = items.first!
        #expect(firstItem.timestamp == date)
    }
    
    @Test
    func testCreateTimestampIsSetOnCreation() async throws {
        // Arrange
        let container = try SwiftDataContainerForTest.temp(#function)
        let handler = CurrentScheme.DataHandler(modelContainer: container)
        
        // Use a reference time to verify createTimestamp is around now
        let beforeCreation = Date()
        
        // Act
        try await handler.newItem(date: Date(timeIntervalSince1970: 0))
        
        // Assert
        let fetchDescriptor = FetchDescriptor<CurrentScheme.Item>()
        let items = try container.mainContext.fetch(fetchDescriptor)
        
        try #require(items.first != nil)
        let firstItem = items.first!
        
        let createTimestamp = firstItem.createTimestamp
        let afterFetch = Date()
        
        // Check that createTimestamp is between beforeCreation and afterFetch
        #expect(createTimestamp >= beforeCreation)
        #expect(createTimestamp <= afterFetch)
    }
    
    // MARK: - Update
    
    @Test
    func testUpdateItemChangesTimestamp() async throws {
        // Arrange
        let container = try SwiftDataContainerForTest.temp(#function)
        let handler = CurrentScheme.DataHandler(modelContainer: container)
        
        let originalDate = Date(timeIntervalSince1970: 0)
        let updatedDate = Date(timeIntervalSince1970: 100)
        
        // Create initial item
        let id = try await handler.newItem(date: originalDate)
        
        // Act
        try await handler.updateItem(id: id, timestamp: updatedDate)
        
        // Assert
        let fetchDescriptor = FetchDescriptor<CurrentScheme.Item>()
        let items = try container.mainContext.fetch(fetchDescriptor)
        
        #expect(items.count == 1)
        try #require(items.first != nil)
        let firstItem = items.first!
        
        #expect(firstItem.timestamp == updatedDate)
        #expect(firstItem.timestamp != originalDate)
    }
    
    @Test
    func testCreateTimestampUnchangedAfterUpdate() async throws {
        // Arrange
        let container = try SwiftDataContainerForTest.temp(#function)
        let handler = CurrentScheme.DataHandler(modelContainer: container)
        
        let originalDate = Date(timeIntervalSince1970: 0)
        let updatedDate = Date(timeIntervalSince1970: 200)
        
        // Create item
        let id = try await handler.newItem(date: originalDate)
        
        // Fetch and remember createTimestamp
        var fetchDescriptor = FetchDescriptor<CurrentScheme.Item>()
        var items = try container.mainContext.fetch(fetchDescriptor)
        try #require(items.first != nil)
        let firstItemBeforeUpdate = items.first!
        let originalCreateTimestamp = firstItemBeforeUpdate.createTimestamp
        
        // Act – update the timestamp
        try await handler.updateItem(id: id, timestamp: updatedDate)
        
        // Assert – createTimestamp should be unchanged
        fetchDescriptor = FetchDescriptor<CurrentScheme.Item>()
        items = try container.mainContext.fetch(fetchDescriptor)
        try #require(items.first != nil)
        let firstItemAfterUpdate = items.first!
        
        #expect(firstItemAfterUpdate.createTimestamp == originalCreateTimestamp)
        #expect(firstItemAfterUpdate.timestamp == updatedDate)
    }
    
    @Test
    func testUpdateItemOnDeletedItemDoesNothing() async throws {
        // Arrange
        let container = try SwiftDataContainerForTest.temp(#function)
        let handler = CurrentScheme.DataHandler(modelContainer: container)
        
        let originalDate = Date(timeIntervalSince1970: 0)
        let updatedDate = Date(timeIntervalSince1970: 200)
        
        // Create and immediately delete the item
        let id = try await handler.newItem(date: originalDate)
        try await handler.deleteItem(id: id)
        
        // Act – updating a deleted item should not crash and not recreate the item
        try await handler.updateItem(id: id, timestamp: updatedDate)
        
        // Assert – store should still be empty
        let fetchDescriptor = FetchDescriptor<CurrentScheme.Item>()
        let items = try container.mainContext.fetch(fetchDescriptor)
        
        #expect(items.count == 0)
    }
    
    // MARK: - Delete
    
    @Test
    func testDeleteItemRemovesItem() async throws {
        // Arrange
        let container = try SwiftDataContainerForTest.temp(#function)
        let handler = CurrentScheme.DataHandler(modelContainer: container)
        
        let date = Date(timeIntervalSince1970: 0)
        let id = try await handler.newItem(date: date)
        
        // Sanity check before delete
        var fetchDescriptor = FetchDescriptor<CurrentScheme.Item>()
        var items = try container.mainContext.fetch(fetchDescriptor)
        #expect(items.count == 1)
        
        // Act
        try await handler.deleteItem(id: id)
        
        // Assert
        fetchDescriptor = FetchDescriptor<CurrentScheme.Item>()
        items = try container.mainContext.fetch(fetchDescriptor)
        
        #expect(items.count == 0)
    }
    
    @Test
    func testDeleteItemOnAlreadyDeletedIdDoesNotCrash() async throws {
        // Arrange
        let container = try SwiftDataContainerForTest.temp(#function)
        let handler = CurrentScheme.DataHandler(modelContainer: container)
        
        let date = Date(timeIntervalSince1970: 0)
        let id = try await handler.newItem(date: date)
        
        // First delete
        try await handler.deleteItem(id: id)
        
        // Act – second delete on the same id (no item should be found)
        try await handler.deleteItem(id: id)
        
        // Assert – still no items, but operation should be safe
        let fetchDescriptor = FetchDescriptor<CurrentScheme.Item>()
        let items = try container.mainContext.fetch(fetchDescriptor)
        
        #expect(items.count == 0)
    }
    
    // MARK: - Multiple Items
    
    @Test
    func testUpdatingOneItemDoesNotAffectOthers() async throws {
        // Arrange
        let container = try SwiftDataContainerForTest.temp(#function)
        let handler = CurrentScheme.DataHandler(modelContainer: container)
        
        let date1 = Date(timeIntervalSince1970: 0)
        let date2 = Date(timeIntervalSince1970: 50)
        let updatedDate1 = Date(timeIntervalSince1970: 100)
        
        let id1 = try await handler.newItem(date: date1)
        let id2 = try await handler.newItem(date: date2)
        
        // Act – update only the first item
        try await handler.updateItem(id: id1, timestamp: updatedDate1)
        
        // Assert
        let fetchDescriptor = FetchDescriptor<CurrentScheme.Item>()
        let items = try container.mainContext.fetch(fetchDescriptor)
        
        #expect(items.count == 2)
        
        // Sort items for deterministic order
        let sortedItems = items.sorted { $0.timestamp < $1.timestamp }
        
        // Find items by id
        try #require(sortedItems.first(where: { $0.persistentModelID == id1 }) != nil)
        try #require(sortedItems.first(where: { $0.persistentModelID == id2 }) != nil)
        
        let item1 = sortedItems.first(where: { $0.persistentModelID == id1 })!
        let item2 = sortedItems.first(where: { $0.persistentModelID == id2 })!
        
        #expect(item1.timestamp == updatedDate1)
        #expect(item2.timestamp == date2)
    }
    
    @Test
    func testDeletingOneItemDoesNotDeleteOthers() async throws {
        // Arrange
        let container = try SwiftDataContainerForTest.temp(#function)
        let handler = CurrentScheme.DataHandler(modelContainer: container)
        
        let date1 = Date(timeIntervalSince1970: 0)
        let date2 = Date(timeIntervalSince1970: 50)
        
        let id1 = try await handler.newItem(date: date1)
        let id2 = try await handler.newItem(date: date2)
        
        // Act – delete only the first item
        try await handler.deleteItem(id: id1)
        
        // Assert
        let fetchDescriptor = FetchDescriptor<CurrentScheme.Item>()
        let items = try container.mainContext.fetch(fetchDescriptor)
        
        #expect(items.count == 1)
        
        try #require(items.first != nil)
        let remainingItem = items.first!
        
        #expect(remainingItem.persistentModelID == id2)
        #expect(remainingItem.timestamp == date2)
    }
}
