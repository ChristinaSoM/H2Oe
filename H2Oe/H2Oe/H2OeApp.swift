//
//  H2OeApp.swift
//  H2Oe
//
//  Created by Christina Moser on 25.11.25.
//

import DataProvider
import SwiftUI
import SwiftData

@main
struct H2OeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(CurrentScheme.models)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.createDataHandler, makeDataHandlerFactory(using: sharedModelContainer))
        }
        .modelContainer(sharedModelContainer)
    }
}
