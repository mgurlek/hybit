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
    private let swipeThreshold: CGFloat = -80 // Negative = upward
    
    // Bugün yapıldı mı kontrolü
    var isCompletedToday: Bool {
        guard let completions = habit.completions else { return false }
        return completions.contains { $0.date.isSameLogicalDay(as: Date()) }
    }
    
    var body: some View {
        ZStack {
            // MARK: - Ana Kart İçeriği
            VStack(spacing: 0) {
                // 1. Üst Kısım: İkon ve Durum
                HStack {
                    // İkon Kutusu
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
                   
                    // Sağ Üst Durum İkonu
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
                        .font(.system(size: 80, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary)
                        .shadow(color: Color.black.opacity(isCompletedToday ? 0.0 : 0.2), radius: 2, x: 0, y: 2)
                        .contentTransition(.numericText())
                   
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
                    
                    // Swipe ipucu göstergesi
                    HStack(spacing: 8) {
                        Image(systemName: isCompletedToday ? "checkmark" : "chevron.up")
                            .font(.system(size: 14, weight: .semibold))
                        Text(isCompletedToday ? "Tamamlandı" : "Yukarı kaydır")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(isCompletedToday ? .primary : .secondary)
                    .opacity(isCompletedToday ? 0.8 : 0.5)
                    // Swipe sırasında ipucunu gizle
                    .opacity(dragOffset < -20 ? 0 : 1)
                }
                .padding(.bottom, 30)
            }
            
            // MARK: - Swipe Feedback Overlay
            if dragOffset < -20 {
                VStack {
                    Spacer()
                    
                    // Swipe progress göstergesi
                    Image(systemName: isCompletedToday ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.primary)
                        .scaleEffect(min(1.0, abs(dragOffset) / abs(swipeThreshold)))
                        .opacity(min(1.0, abs(dragOffset) / abs(swipeThreshold)))
                    
                    Text(isCompletedToday ? "Geri Al" : "Tamamla")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .opacity(min(1.0, abs(dragOffset) / abs(swipeThreshold)))
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.primary.opacity(0.05))
            }
        }
        // --- KART GÖVDESİ ---
        .adaptiveGlassCard(cornerRadius: 36)
        // Swipe transform
        .offset(y: dragOffset * 0.3)
        .scaleEffect(1 + (dragOffset * 0.001))
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        // MARK: - Swipe Gesture
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    // Sadece yukarı swipe (negatif translation)
                    if value.translation.height < 0 {
                        withAnimation(.interactiveSpring()) {
                            dragOffset = value.translation.height
                        }
                    }
                }
                .onEnded { value in
                    if value.translation.height < swipeThreshold {
                        // Threshold aşıldı - toggle yap
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        withAnimation(.snappy) {
                            viewModel?.toggleHabit(habit)
                        }
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                    
                    // Kartı eski yerine döndür
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dragOffset = 0
                    }
                }
        )
    }
}
