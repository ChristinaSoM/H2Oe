//
//  ItemView.swift
//  H2Oe
//
//  Created by Christina Moser on 27.11.25.
//

import SwiftUI
import SwiftData
import DataProvider

struct ItemView: View {
    @Environment(\.modelContext) private var modelContext
    let item: Item
    var body: some View {
        VStack {
            Text("\(item.timestamp.timeIntervalSince1970)")
            
            HStack {
                Button("Update Timestamp") {
                    item.timestamp = .now
                    save()
                }
                
                Button("Delete") {
                    modelContext.delete(item)
                    save()
                }
            }
        }
        .buttonStyle(.bordered)
    }
    
    
    @MainActor
    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Save failed: \(error)")
        }
    }
}

struct ItemViewPreviewContainer: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.createTimestamp) private var items: [Item]

    var body: some View {
        VStack {
            if let item = items.first {
                ItemView(item: item)
            } else {
                Text("No items")
            }
        }
        .task {
            // Seed only if empty
            if items.isEmpty {
                modelContext.insert(Item(timestamp: .now))
                try? modelContext.save()
            }
        }
    }
}

#Preview {
    ItemViewPreviewContainer()
        .modelContainer(DataProvider.previewContainer)
}

