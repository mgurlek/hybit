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

// MARK: - Toggle Intent (iOS 17+ Interactive Widget)
struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Alışkanlığı İşaretle"
    static var description: IntentDescription = IntentDescription("Bugünkü alışkanlığı tamamlandı olarak işaretle.")
    
    @Parameter(title: "Alışkanlık ID")
    var habitId: String
    
    init() {
        self.habitId = ""
    }
    
    init(habitId: String) {
        self.habitId = habitId
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let context = DataManager.shared.modelContainer.mainContext
        let descriptor = FetchDescriptor<Habit>()
        
        do {
            let habits = try context.fetch(descriptor)
            if let habit = habits.first(where: { $0.id == habitId }) {
                // Toggle mantığı
                let today = Date()
                let alreadyCompleted = habit.completions?.contains {
                    $0.date.isSameLogicalDay(as: today)
                } ?? false
                
                if alreadyCompleted {
                    // Bugün zaten tamamlandı, geri al
                    habit.completions?.removeAll { $0.date.isSameLogicalDay(as: today) }
                } else {
                    // Bugün tamamlandı olarak işaretle
                    let completion = Completion(date: today, habit: habit)
                    context.insert(completion)
                    if habit.completions == nil {
                        habit.completions = []
                    }
                    habit.completions?.append(completion)
                }
                
                try context.save()
            }
        } catch {
            print("Toggle hatası: \(error)")
        }
        
        // Widget'ı yenile
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result()
    }
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
