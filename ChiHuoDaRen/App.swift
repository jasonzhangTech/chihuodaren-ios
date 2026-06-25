import SwiftData
import SwiftUI

@main
struct ChiHuoDaRenApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FoodLog.self,
            Dish.self,
            FoodPhoto.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create local store: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

