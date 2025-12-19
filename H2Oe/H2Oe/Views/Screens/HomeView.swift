//
//  HomeView.swift
//  H2Oe
//
//  Created by Christina Moser on 25.11.25.
//

import SwiftUI
import SwiftData
import DataProvider

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext // for deleting DataSwift items
    @Query(sort: \Item.createTimestamp, animation: .smooth) private var items: [Item]  // for automatic fetches and UI updates


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
            
            StationDetailView()
            
            Spacer()
            
            VStack {
                Text("Total items: \(items.count)")
                
                Spacer()
                
                // add the station map component here
                MapView()
            }
        }
    }

    @MainActor
    private func addItem() {
        let item = Item(timestamp: .now)
        modelContext.insert(item)
        try? modelContext.save()
    }

    @MainActor
    private func deleteItems(_ offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context after deletion: \(error)")
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(DataProvider.previewContainer)
}
