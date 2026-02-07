//
//  hybitWidget.swift
//  hybitWidget
//
//  Created by Mert Gurlek on 7.02.2026.
//

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    // @MainActor: Bu fonksiyonun ana iş parçacığında çalışmasını sağlar (Hatayı Çözen Kısım)
    @MainActor
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), habits: [])
    }

    @MainActor
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        // DataManager.shared artık güvenle çağrılabilir
        let habits = fetchHabits()
        let entry = SimpleEntry(date: Date(), habits: habits)
        completion(entry)
    }

    @MainActor
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Verileri Çek
        let habits = fetchHabits()
        
        // Timeline oluştur (Şimdilik sadece anlık durumu gösteriyoruz)
        let entry = SimpleEntry(date: Date(), habits: habits)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 15))) // 15 dk sonra yenile
        completion(timeline)
    }
    
    // Veritabanından Alışkanlıkları Çeken Yardımcı Fonksiyon
    @MainActor
    private func fetchHabits() -> [Habit] {
        // DataManager.shared'a erişim artık güvenli
        let context = DataManager.shared.modelContainer.mainContext
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.creationDate, order: .reverse)])
        
        do {
            let habits = try context.fetch(descriptor)
            return habits
        } catch {
            print("Widget veri çekme hatası: \(error)")
            return []
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let habits: [Habit]
}

struct hybitWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bugünün Hedefleri")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
            
            if entry.habits.isEmpty {
                Text("Henüz hedef yok.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                // İlk 3 alışkanlığı gösterelim
                ForEach(entry.habits.prefix(3), id: \.id) { habit in
                    HStack {
                        Image(systemName: isDoneToday(habit) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isDoneToday(habit) ? .green : .gray)
                        Text(habit.name)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                        Spacer()
                    }
                }
            }
            Spacer()
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(uiColor: .systemGroupedBackground)
        }
    }
    
    // Alışkanlık bugün yapıldı mı kontrolü
    func isDoneToday(_ habit: Habit) -> Bool {
        guard let completions = habit.completions else { return false }
        return completions.contains { Calendar.current.isDate($0.date, inSameDayAs: Date()) }
    }
}

struct hybitWidget: Widget {
    let kind: String = "hybitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                hybitWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                hybitWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Hybit Takip")
        .description("Alışkanlıklarını ana ekrandan takip et.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// Preview (Önizleme) için Mock Data
#Preview(as: .systemSmall) {
    hybitWidget()
} timeline: {
    SimpleEntry(date: .now, habits: [
        Habit(name: "Kitap Oku", hexColor: "000000"),
        Habit(name: "Su İç", hexColor: "000000")
    ])
}
