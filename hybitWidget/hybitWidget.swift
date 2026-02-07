//
//  hybitWidget.swift
//  hybitWidget
//
//  Created by Mert Gurlek on 7.02.2026.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - TIMELINE PROVIDER
struct Provider: AppIntentTimelineProvider {
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), habit: nil, state: .loading)
    }

    func snapshot(for configuration: SelectHabitIntent, in context: Context) async -> SimpleEntry {
        let allHabits = await fetchHabits()
        return SimpleEntry(date: Date(), habit: allHabits.first, state: allHabits.isEmpty ? .empty : .loaded)
    }

    func timeline(for configuration: SelectHabitIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let allHabits = await fetchHabits()
        
        var selectedHabitData: Habit? = nil
        var state: WidgetState = .loading
        
        // 1. Seçim
        if let chosenHabitID = configuration.selectedHabit?.id {
            selectedHabitData = allHabits.first { $0.id == chosenHabitID }
        }
        // 2. Otomatik
        if selectedHabitData == nil {
            selectedHabitData = allHabits.first
        }
        // 3. Durum
        if allHabits.isEmpty {
            state = .empty
        } else if selectedHabitData != nil {
            state = .loaded
        }
        
        let entry = SimpleEntry(date: Date(), habit: selectedHabitData, state: state)
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 15)))
    }
    
    @MainActor
    private func fetchHabits() -> [Habit] {
        let context = DataManager.shared.modelContainer.mainContext
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.creationDate, order: .reverse)])
        do {
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }
}

enum WidgetState { case loading, empty, loaded }

struct SimpleEntry: TimelineEntry {
    let date: Date
    let habit: Habit?
    let state: WidgetState
}

// MARK: - GÖRÜNÜM BİLEŞENLERİ

// 1. Yuvarlak Gün Hücresi
struct WidgetDayCircle: View {
    let date: Date
    let habit: Habit
    
    var isCompleted: Bool {
        guard let completions = habit.completions else { return false }
        return completions.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var dayNumber: String {
        "\(Calendar.current.component(.day, from: date))"
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if isCompleted {
                    // DOLU: Koyu renk (Siyah/Koyu Gri) - Cam üzerinde harika durur
                    Circle().fill(Color.primary.opacity(0.8))
                    Text(dayNumber)
                        .font(.system(size: geo.size.width * 0.45, weight: .bold))
                        .foregroundStyle(Color(uiColor: .systemBackground)) // Rengi tersine çevirir
                } else {
                    // BOŞ: Çok ince ve silik çizgi
                    Circle()
                        .stroke(Color.primary.opacity(isToday ? 0.6 : 0.15), lineWidth: isToday ? 2 : 1)
                    
                    Text(dayNumber)
                        .font(.system(size: geo.size.width * 0.45, weight: .bold))
                        .foregroundStyle(Color.primary.opacity(isToday ? 0.8 : 0.3))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// 2. Küçük Widget
struct SmallWidgetView: View {
    let habit: Habit
    var days: [Date] { (0..<20).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: Date()) } }
    let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 5)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .lastTextBaseline) {
                Text("\(habit.currentStreak)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.9)) // Hafif şeffaflık
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                Text("SERİ")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 6)
                
                Spacer()
            }
            .padding(.top, 10) // Kenar boşluklarını kapattığımız için elle boşluk veriyoruz
            .padding(.leading, 10)
            
            Text(habit.name.uppercased())
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .padding(.bottom, 8)
                .padding(.leading, 10)
            
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(days, id: \.self) { day in
                    WidgetDayCircle(date: day, habit: habit)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 3. Orta Widget
struct MediumWidgetView: View {
    let habit: Habit
    var days: [Date] { (0..<28).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: Date()) } }
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("\(habit.currentStreak)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                Text("SERİ")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                
                Text(habit.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .padding(.top, 2)
                    .foregroundStyle(.primary.opacity(0.8))
                
                Spacer()
            }
            .frame(width: 90)
            .padding(.vertical, 15)
            .padding(.leading, 15)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(days, id: \.self) { day in
                    WidgetDayCircle(date: day, habit: habit)
                }
            }
            .padding(.trailing, 15)
        }
    }
}

// MARK: - ANA GÖRÜNÜM (Liquid Glass Ayarı Burası)
struct hybitWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            if let habit = entry.habit {
                switch family {
                case .systemSmall: SmallWidgetView(habit: habit)
                case .systemMedium: MediumWidgetView(habit: habit)
                case .accessoryRectangular: Text(habit.name)
                default: Text("...")
                }
            } else {
                VStack {
                    Image(systemName: "plus").font(.largeTitle)
                    Text("Hedef Ekle").font(.caption.bold())
                }
            }
        }
        // ✨ KRİTİK NOKTA: DOCK EFEKTİ İÇİN DOĞRU KOD ✨
        .containerBackground(for: .widget) {
            // .ultraThinMaterial: En şeffaf, en "camsı" materyaldir.
            // Simülatörde GRİ görünebilir, GERÇEK CİHAZDA cam olur.
            Rectangle().fill(.ultraThinMaterial)
        }
    }
}

@main
struct hybitWidget: Widget {
    let kind: String = "hybitWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectHabitIntent.self, provider: Provider()) { entry in
            hybitWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Hybit Takip")
        .description("Alışkanlık serini takip et.")
        // ✨ BU ÇOK ÖNEMLİ: Kenar boşluklarını kapatıyoruz ki cam efekti tam otursun
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
