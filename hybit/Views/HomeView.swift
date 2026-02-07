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
            HabitDetailView(habit: habit, viewModel: viewModel)
        }
    }
}

// MARK: - Liquid Glass Kart Tasarımı
struct HabitCarouselCard: View {
    let habit: Habit
    var viewModel: HabitListViewModel?
    
    // Bugün yapıldı mı kontrolü
    var isCompletedToday: Bool {
        guard let completions = habit.completions else { return false }
        return completions.contains { $0.date.isSameLogicalDay(as: Date()) }
    }
    
    var body: some View {
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
                    // Tamamlandıysa hafif parlasın
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
            
            // 3. Alt Kısım: İsim
            Text(habit.name)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .padding(.bottom, 24)
            
            // 4. Aksiyon Butonu (GÜNCELLENEN KISIM)
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
                
                // --- CANLI BUTON EFEKTİ ---
                .background(
                    ZStack {
                        if isCompletedToday {
                            // AKTİF: Parlak Gradient (Kristal Beyaz)
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            // PASİF: Sönük Cam
                            Color.primary.opacity(0.05)
                        }
                    }
                )
                .foregroundStyle(isCompletedToday ? Color(uiColor: .systemBackground) : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                
                // Kenarlık
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                // --- GLOW (PARLAMA) EFEKTİ ---
                // Tamamlandığında etrafına ışık yayar
                .shadow(
                    color: isCompletedToday ? Color.primary.opacity(0.4) : .clear,
                    radius: 15,
                    x: 0,
                    y: 0
                )
            }
            .padding(24)
        }
        // --- KART GÖVDESİ ---
        .background(.ultraThinMaterial)
        .background(
            LinearGradient(
                colors: [.white.opacity(0.1), .white.opacity(0.02), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.6), .white.opacity(0.1), .black.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}
