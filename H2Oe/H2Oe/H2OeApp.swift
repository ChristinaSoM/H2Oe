import DataProvider
import SwiftUI
import SwiftData

@main
struct H2OeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(CurrentScheme.models)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false) // stored on disk

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            let createHandler = makeDataHandlerFactory(using: sharedModelContainer)
            HomeView()
                .environment(\.createDataHandler, createHandler)
        }
        .modelContainer(sharedModelContainer)
    }
}
