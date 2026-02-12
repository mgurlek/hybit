//
//  HomeView.swift
//  hybit
//
//  Created by Mert Gurlek on 7.02.2026.
//
import WidgetKit
import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Habit.creationDate, order: .reverse) var habits: [Habit]
    var viewModel: HabitListViewModel?
    
    // Detay sayfası için state
    @State private var selectedHabitForDetail: Habit?
    
    var body: some View {
        ZStack {
            if habits.isEmpty {
                ContentUnavailableView("Hedef Yok", systemImage: "circle.grid.cross", description: Text("Ekle butonuna bas."))
            } else {
                // Adaptive layout: iPhone'da carousel, iPad/Mac'te grid
                AdaptiveHabitGrid(items: habits) { habit in
                    HabitCarouselCard(habit: habit, viewModel: viewModel)
                        .onTapGesture {
                            selectedHabitForDetail = habit
                        }
                }
            }
        }
        .adaptiveLayout() // Cihaz tipini algıla
        // Sheet olarak detay sayfasını aç
        .sheet(item: $selectedHabitForDetail) { habit in
            HabitDetailView(habit: habit, viewModel: viewModel)
        }
    }
}

// MARK: - Liquid Glass Kart Tasarımı
struct HabitCarouselCard: View {
    let habit: Habit
    var viewModel: HabitListViewModel?
    
    // Swipe gesture state
    @State private var dragOffset: CGFloat = 0
    private let swipeThreshold: CGFloat = -80
    private let maxDrag: CGFloat = -120 // Üst sınır
    
    // Bugün yapıldı mı kontrolü
    var isCompletedToday: Bool {
        guard let completions = habit.completions else { return false }
        return completions.contains { $0.date.isSameLogicalDay(as: Date()) }
    }
    
    // Swipe ilerleme oranı (0...1)
    private var swipeProgress: CGFloat {
        min(1.0, abs(dragOffset) / abs(swipeThreshold))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // MARK: - Kart Altındaki Aksiyon Alanı
            HStack(spacing: 8) {
                Image(systemName: isCompletedToday ? "arrow.uturn.backward" : "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text(isCompletedToday ? "Geri Al" : "Tamamla")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .opacity(swipeProgress)
            .scaleEffect(0.8 + (swipeProgress * 0.2))
            .padding(.bottom, 12)
            
            // MARK: - Ana Kart
            VStack(spacing: 0) {
                // 1. Üst Kısım: İkon ve Durum
                HStack {
                    Image(systemName: habit.iconSymbol)
                        .font(.title2)
                        .foregroundStyle(.primary)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                   
                    Spacer()
                   
                    Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                        .font(.title)
                        .foregroundStyle(.primary)
                        .opacity(isCompletedToday ? 1.0 : 0.3)
                        .shadow(color: isCompletedToday ? .primary.opacity(0.5) : .clear, radius: 5)
                }
                .padding(24)
               
                Spacer()
               
                // 2. Orta Kısım: Dev Sayaç
                VStack(spacing: 4) {
                    Text("\(habit.currentStreak)")
                        .font(.system(size: 80, weight: .heavy))
                        .foregroundStyle(.primary)
                        .shadow(color: Color.black.opacity(isCompletedToday ? 0.0 : 0.2), radius: 2, x: 0, y: 2)
                        .id("streak_\(habit.currentStreak)")
                        .transition(.blurReplace)
                   
                    Text("GÜNLÜK SERİ")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .tracking(2)
                }
               
                Spacer()
               
                // 3. Alt Kısım: İsim + Swipe İpucu
                VStack(spacing: 16) {
                    Text(habit.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: isCompletedToday ? "checkmark" : "chevron.up")
                            .font(.system(size: 12, weight: .bold))
                        Text(isCompletedToday ? "Tamamlandı" : "Yukarı kaydır")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.tertiary)
                    .opacity(dragOffset < -10 ? 0 : 1)
                }
                .padding(.bottom, 30)
            }
            .adaptiveGlassCard(cornerRadius: 36)
            // Swipe transform — kartı yukarı kaydır
            .offset(y: dragOffset * 0.6)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
        // MARK: - Swipe Gesture
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    if value.translation.height < 0 {
                        // Sınırlandırılmış drag (rubber band etkisi)
                        let clamped = max(maxDrag, value.translation.height)
                        withAnimation(.interactiveSpring()) {
                            dragOffset = clamped
                        }
                    }
                }
                .onEnded { value in
                    let clampedTranslation = max(maxDrag, value.translation.height)
                    
                    if clampedTranslation < swipeThreshold {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        withAnimation(.snappy) {
                            viewModel?.toggleHabit(habit)
                        }
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dragOffset = 0
                    }
                }
        )
    }
}
