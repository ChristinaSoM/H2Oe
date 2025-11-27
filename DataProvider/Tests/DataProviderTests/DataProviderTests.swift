//
//  DataProviderTests.swift
//  DataProvider
//
//  Created by Christina Moser on 25.11.25.
//

import XCTest
import SwiftData
@testable import DataProvider



enum ContainerForTest {
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


final class DataProviderTests: XCTestCase {
    
    // MARK: - Creation
    
    @MainActor
    func testNewItem() async throws {
        // Arrange
        let container = try ContainerForTest.temp(#function)
        let handler = CurrentScheme.DataHandler(modelContainer: container)
        
        // Act
        let date = Date(timeIntervalSince1970: 0)
        try await handler.newItem(date: date)
        
        // Assert
        let fetchDescriptor = FetchDescriptor<CurrentScheme.Item>()
        let items = try container.mainContext.fetch(fetchDescriptor)
        
        XCTAssertNotNil(items.first, "The item should be created and fetched successfully.")
        XCTAssertEqual(items.count, 1, "There should be exactly one item in the store.")
        
        if let firstItem = items.first {
            XCTAssertEqual(firstItem.timestamp, date, "The item's timestamp should match the initially provided date.")
        } else {
            XCTFail("Expected to find an item but none was found.")
        }
    }
    
    @MainActor
    func testCreateTimestampIsSetOnCreation() async throws {
        // Arrange
        let container = try ContainerForTest.temp(#function)
        let handler = CurrentScheme.DataHandler(modelContainer: container)
        
        // Use a reference time to verify createTimestamp is around now
        let beforeCreation = Date()
        
        // Act
        try await handler.newItem(date: Date(timeIntervalSince1970: 0))
        
        // Assert
        let fetchDescriptor = FetchDescriptor<CurrentScheme.Item>()
        let items = try container.mainContext.fetch(fetchDescriptor)
        
        guard let firstItem = items.first else {
            XCTFail("Expected to find an item but none was found.")
            return
        }
        
        let createTimestamp = firstItem.createTimestamp
        let afterFetch = Date()
        
        // Check that createTimestamp is between beforeCreation and afterFetch
        XCTAssertGreaterThanOrEqual(
            createTimestamp,
            beforeCreation,
            "createTimestamp should not be earlier than the time before creation."
        )
        XCTAssertLessThanOrEqual(
            createTimestamp,
            afterFetch,
            "createTimestamp should not be later than the time after fetching."
        )
    }
    
    // MARK: - Update
    
    @MainActor
    func testUpdateItemChangesTimestamp() async throws {
        // Arrange
        let container = try ContainerForTest.temp(#function)
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
        
        XCTAssertEqual(items.count, 1, "There should still be exactly one item in the store.")
        guard let firstItem = items.first else {
            XCTFail("Expected to find an item after update but none was found.")
            return
        }
        
        XCTAssertEqual(firstItem.timestamp, updatedDate, "The item's timestamp should be updated to the new value.")
        XCTAssertNotEqual(firstItem.timestamp, originalDate, "The timestamp should no longer be the original one.")
    }
    
    @MainActor
    func testCreateTimestampUnchangedAfterUpdate() async throws {
        // Arrange
        let container = try ContainerForTest.temp(#function)
        let handler = CurrentScheme.DataHandler(modelContainer: container)
        
        let originalDate = Date(timeIntervalSince1970: 0)
        let updatedDate = Date(timeIntervalSince1970: 200)
        
        // Create item
        let id = try await handler.newItem(date: originalDate)
        
        // Fetch and remember createTimestamp
        var fetchDescriptor = FetchDescriptor<CurrentScheme.Item>()
        var items = try container.mainContext.fetch(fetchDescriptor)
        guard let firstItemBeforeUpdate = items.first else {
            XCTFail("Expected to find an item before update but none was found.")
            return
        }
        let originalCreateTimestamp = firstItemBeforeUpdate.createTimestamp
        
        // Act – update the timestamp
        try await handler.updateItem(id: id, timestamp: updatedDate)
        
        // Assert – createTimestamp should be unchanged
        fetchDescriptor = FetchDescriptor<CurrentScheme.Item>()
        items = try container.mainContext.fetch(fetchDescriptor)
        
        guard let firstItemAfterUpdate = items.first else {
            XCTFail("Expected to find an item after update but none was found.")
            return
        }
        
        XCTAssertEqual(
            firstItemAfterUpdate.createTimestamp,
            originalCreateTimestamp,
            "createTimestamp should remain unchanged after updating the item."
        )
        XCTAssertEqual(
            firstItemAfterUpdate.timestamp,
            updatedDate,
            "The timestamp should be updated to the new value."
        )
    }
    
    @MainActor
    func testUpdateItemOnDeletedItemDoesNothing() async throws {
        // Arrange
        let container = try ContainerForTest.temp(#function)
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
        
        XCTAssertEqual(items.count, 0, "No item should exist after deleting and trying to update the same id.")
    }
    
    // MARK: - Delete
    
    @MainActor
    func testDeleteItemRemovesItem() async throws {
        // Arrange
        let container = try ContainerForTest.temp(#function)
        let handler = CurrentScheme.DataHandler(modelContainer: container)
        
        let date = Date(timeIntervalSince1970: 0)
        let id = try await handler.newItem(date: date)
        
        // Sanity check before delete
        var fetchDescriptor = FetchDescriptor<CurrentScheme.Item>()
        var items = try container.mainContext.fetch(fetchDescriptor)
        XCTAssertEqual(items.count, 1, "There should be one item before deletion.")
        
        // Act
        try await handler.deleteItem(id: id)
        
        // Assert
        fetchDescriptor = FetchDescriptor<CurrentScheme.Item>()
        items = try container.mainContext.fetch(fetchDescriptor)
        
        XCTAssertEqual(items.count, 0, "The item should be removed from the store after deletion.")
    }
    
    @MainActor
    func testDeleteItemOnAlreadyDeletedIdDoesNotCrash() async throws {
        // Arrange
        let container = try ContainerForTest.temp(#function)
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
        
        XCTAssertEqual(items.count, 0, "Deleting the same id twice should not recreate an item.")
    }
    
    // MARK: - Multiple Items
    
    @MainActor
    func testUpdatingOneItemDoesNotAffectOthers() async throws {
        // Arrange
        let container = try ContainerForTest.temp(#function)
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
        
        XCTAssertEqual(items.count, 2, "There should be exactly two items in the store.")
        
        // Sort items for deterministic order
        let sortedItems = items.sorted { $0.timestamp < $1.timestamp }
        
        // Find items by id
        guard let item1 = sortedItems.first(where: { $0.persistentModelID == id1 }) else {
            XCTFail("Expected to find item 1.")
            return
        }
        guard let item2 = sortedItems.first(where: { $0.persistentModelID == id2 }) else {
            XCTFail("Expected to find item 2.")
            return
        }
        
        XCTAssertEqual(item1.timestamp, updatedDate1, "Item 1 should have the updated timestamp.")
        XCTAssertEqual(item2.timestamp, date2, "Item 2 should keep its original timestamp.")
    }
    
    @MainActor
    func testDeletingOneItemDoesNotDeleteOthers() async throws {
        // Arrange
        let container = try ContainerForTest.temp(#function)
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
        
        XCTAssertEqual(items.count, 1, "There should be exactly one item left after deleting one.")
        
        guard let remainingItem = items.first else {
            XCTFail("Expected to find the remaining item but none was found.")
            return
        }
        
        XCTAssertEqual(remainingItem.persistentModelID, id2, "The remaining item should be the second one.")
        XCTAssertEqual(remainingItem.timestamp, date2, "The remaining item should keep its original timestamp.")
    }
}
