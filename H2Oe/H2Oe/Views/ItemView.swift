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
  @Environment(\.createDataHandler) private var createDataHandler
  let item: Item
  var body: some View {
    VStack {
      Text("\(item.timestamp.timeIntervalSince1970)")
      HStack {
        Button("Update Timestamp") {
          let id = item.id
          let date = Date.now
          let createDataHandler = createDataHandler
          Task.detached {
            if let dataHandler = await createDataHandler() {
              try? await dataHandler.updateItem(id: id, timestamp: date)
            }
          }
        }
        Button("Delete") {
          let id = item.id
          let createDataHandler = createDataHandler
          Task.detached {
            if let dataHandler = await createDataHandler() {
              try? await dataHandler.deleteItem(id: id)
            }
          }
        }
      }
    }
    .buttonStyle(.bordered)
  }
}

#if DEBUG
struct ItemViewPreviewContainer: View {
    @Environment(\.createDataHandler) var createDataHandler
    @Query var items: [Item]
    var body: some View {
        VStack {
            if let item = items.first {
                ItemView(item: item)
            }
        }
        .task {
            if let dataHander = await createDataHandler() {
                let _ = try? await dataHander.newItem(date: .now)
            }
        }
    }
}
#endif

#Preview {
  return ItemViewPreviewContainer()
    .environment(\.createDataHandler, makeDataHandlerFactory(using: DataProvider.previewContainer))
    .modelContainer(DataProvider.previewContainer)
}
