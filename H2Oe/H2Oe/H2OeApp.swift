import DataProvider
import SwiftUI
import SwiftData

@main
struct H2OeApp: App {
    
    //SwiftData
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(CurrentScheme.models)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false) // config: how and where to store: stored on disk

        do {
            //create modelContainer
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer) //modelContainer is now in SwiftUI-Environment.
        // enables @Environment(\.modelContext) and @Query
    }
}
