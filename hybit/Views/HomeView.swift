//
//  HomeView.swift
//  hybit
//
//  Created by Mert Gurlek on 7.02.2026.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Habit.creationDate, order: .reverse) var habits: [Habit]
    var viewModel: HabitListViewModel?
    @State private var selectedIndex = 0
    
    // Detay sayfası için state
    @State private var selectedHabitForDetail: Habit?
    
    var body: some View {
        ZStack {
            if habits.isEmpty {
                ContentUnavailableView("Hedef Yok", systemImage: "circle.grid.cross", description: Text("Ekle butonuna bas."))
            } else {
                TabView(selection: $selectedIndex) {
                    ForEach(Array(habits.enumerated()), id: \.element.id) { index, habit in
                        HabitCarouselCard(habit: habit, viewModel: viewModel)
                            .tag(index)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                            .padding(.bottom, 80)
                            // KARTA TIKLAYINCA DETAYI AÇ
                            .onTapGesture {
                                selectedHabitForDetail = habit
                            }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        // Sheet olarak detay sayfasını aç
        .sheet(item: $selectedHabitForDetail) { habit in
            HabitDetailView(habit: habit)
        }
    }
}

// MARK: - Monokrom Kart Tasarımı (BU KISIM EKSİKTİ)
struct HabitCarouselCard: View {
    let habit: Habit
    var viewModel: HabitListViewModel?
    
    var isCompletedToday: Bool {
        guard let completions = habit.completions else { return false }
        return completions.contains { Calendar.current.isDate($0.date, inSameDayAs: Date()) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. Üst İkon
            HStack {
                Image(systemName: habit.iconSymbol)
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .padding(12)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(Circle())
                
                Spacer()
                
                Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundStyle(isCompletedToday ? .primary : .tertiary)
            }
            .padding(24)
            
            Spacer()
            
            // 2. Sayaç
            VStack(spacing: 4) {
                Text("\(habit.currentStreak)")
                    .font(.system(size: 80, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                
                Text("GÜNLÜK SERİ")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .tracking(2)
            }
            
            Spacer()
            
            // 3. İsim
            Text(habit.name)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .padding(.bottom, 24)
            
            // 4. Alt Buton
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                withAnimation(.snappy) {
                    viewModel?.toggleHabit(habit)
                }
            } label: {
                HStack {
                    Image(systemName: isCompletedToday ? "checkmark" : "circle")
                    Text(isCompletedToday ? "Tamamlandı" : "Bugün İşaretle")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isCompletedToday ? Color.primary : Color(uiColor: .secondarySystemBackground))
                .foregroundStyle(isCompletedToday ? Color(uiColor: .systemBackground) : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(24)
        }
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
    }
}
