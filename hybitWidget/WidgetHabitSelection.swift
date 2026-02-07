import WidgetKit
import AppIntents
import SwiftData

// 1. Kullanıcının Hangi Alışkanlığı Seçeceğini Belirleyen Yapı
struct SelectHabitIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Alışkanlık Seç"
    static var description: IntentDescription = IntentDescription("Hangi alışkanlığın grafiğini görmek istediğini seç.")

    // Kullanıcıya sunulacak liste
    @Parameter(title: "Alışkanlık")
    var selectedHabit: HabitEntity?
}

// 2. Alışkanlıkları Listeye Dönüştüren Köprü (Entity)
struct HabitEntity: AppEntity {
    let id: String
    let name: String
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Alışkanlık"
    static var defaultQuery = HabitQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

// 3. Veritabanından Alışkanlıkları Çeken Sorgu (Query)
struct HabitQuery: EntityQuery {
    
    func entities(for identifiers: [String]) async throws -> [HabitEntity] {
        // DÜZELTME 1: 'await' eklendi. (Ana iş parçacığını beklemesi için)
        let habits = await fetchHabits()
        return habits.filter { identifiers.contains($0.id) }
    }
    
    func suggestedEntities() async throws -> [HabitEntity] {
        // DÜZELTME 1: 'await' eklendi.
        let habits = await fetchHabits()
        return habits
    }
    
    func defaultResult() async -> HabitEntity? {
        return try? await suggestedEntities().first
    }
    
    // Yardımcı: Veritabanından çekme
    @MainActor
    private func fetchHabits() -> [HabitEntity] {
        // DataManager.shared'a güvenli erişim
        let context = DataManager.shared.modelContainer.mainContext
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.creationDate, order: .reverse)])
        
        do {
            let habits = try context.fetch(descriptor)
            
            // DÜZELTME 2: .uuidString silindi. Senin ID'n zaten String olduğu için direkt kullanıyoruz.
            return habits.map {
                HabitEntity(id: $0.id, name: $0.name)
            }
        } catch {
            return []
        }
    }
}
