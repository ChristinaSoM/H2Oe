//
//  ContentView.swift
//  H2Oe
//
//  Created by Christina Moser on 25.11.25.
//

import SwiftUI
import SwiftData
import DataProvider

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.createDataHandler) private var createDataHandler
    @Query(sort: \Item.createTimestamp, animation: .smooth) private var items: [Item]


    var body: some View {
        VStack {
            NavigationSplitView {
                List {
                    ForEach(items) { item in
                        // VStack {
                        //Text("\(item.timestamp.timeIntervalSince1970)")
                        // ItemView(item: item) // don't change after update
                        // }
                        NavigationLink {
                            Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        } label: {
                            Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button(action: addItem) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
            } detail: {
                Text("Select an item")
            }
            
            Spacer()
            
            VStack {
                Text("Total items: \(items.count)")
                
                Spacer()
                
                // add MapView here
                MapView()
            }
        }
    }

    @MainActor
    private func addItem() {
      let createDataHandler = createDataHandler
      Task.detached {
        if let dataHandler = await createDataHandler() {
          try await dataHandler.newItem(date: .now)
        }
      }
    }

    @MainActor
    private func deleteItems(_ offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            modelContext.delete(item)
        }
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context after deletion: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(DataProvider.previewContainer)
}
