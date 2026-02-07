import Foundation
import SwiftData

@MainActor
class DataManager {
    static let shared = DataManager()
    
    let modelContainer: ModelContainer
    
    private init() {
        // Modelleri artık tanıyor
        let schema = Schema([
            Habit.self,
            Completion.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            "HybitDatabase",
            isStoredInMemoryOnly: false,
            // App Group ID'n buraya:
            groupContainer: .identifier("group.com.gurtech.hybit")
        )
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: modelConfiguration)
        } catch {
            fatalError("ModelContainer oluşturulamadı: \(error)")
        }
    }
}
