//
//  hybitWidget.swift
//  hybitWidget
//
//  Created by Mert Gurlek on 7.02.2026.
//

import WidgetKit
import SwiftUI
import SwiftData

// 1. Zaman Çizelgesi Sağlayıcısı
struct Provider: TimelineProvider {
    // DataManager'dan container'ı alıyoruz
    let modelContainer = DataManager.shared.modelContainer

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), habits: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let habits = fetchHabits()
        let entry = SimpleEntry(date: Date(), habits: habits)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let habits = fetchHabits()
        let entry = SimpleEntry(date: Date(), habits: habits)
        
        // 1 saat sonra veya veri değişince yenile
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
    
    // DÜZELTME 1: @MainActor kaldırıldı.
    // Arka planda güvenli çalışması için kendi Context'ini yaratıyor.
    private func fetchHabits() -> [Habit] {
        // Arka plan thread'i için yeni, geçici bir context oluştur
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.creationDate)])
        return (try? context.fetch(descriptor)) ?? []
    }
}

// 2. Widget Veri Modeli
struct SimpleEntry: TimelineEntry {
    let date: Date
    let habits: [Habit]
}

// 3. Widget Arayüzü
struct hybitWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bugün")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 2)
            
            if entry.habits.isEmpty {
                Text("Hedef yok")
                    .font(.caption2)
                    .italic()
            } else {
                ForEach(entry.habits.prefix(3)) { habit in
                    HStack {
                        Circle()
                            .fill(Color(hex: habit.hexColor))
                            .frame(width: 8, height: 8)
                        
                        Text(habit.name)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                        
                        Spacer()
                        
                        let isDone = isCompletedToday(habit)
                        Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isDone ? Color.green : Color.gray.opacity(0.5))
                            .font(.system(size: 14))
                    }
                }
            }
            Spacer()
        }
        // DÜZELTME 2: 'systemBackground' yerine standart SwiftUI rengi kullanıldı.
        // Bu sayede macOS'te hata vermez.
        .containerBackground(for: .widget) {
            Color.white.opacity(0.1) // Veya Color.black vs.
        }
    }
    
    func isCompletedToday(_ habit: Habit) -> Bool {
        guard let completions = habit.completions else { return false }
        return completions.contains { Calendar.current.isDate($0.date, inSameDayAs: Date()) }
    }
}

// 4. Widget Konfigürasyonu
@main
struct hybitWidget: Widget {
    let kind: String = "hybitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            hybitWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Zincir Takip")
        .description("Günlük hedeflerini takip et.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
