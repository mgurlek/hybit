//
//  CustomTabBar.swift
//  hybit
//
//  Created by Mert Gurlek on 7.02.2026.
//

import SwiftUI

// Eğer Tab enum'ı başka yerdeyse buradakini silebilirsin.
enum Tab {
    case home, feed, friends
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        HStack(spacing: 0) {
            // 1. SOL: Akış (Feed)
            TabBarButton(icon: "safari.fill", tab: .feed, selectedTab: $selectedTab)
            
            // 2. ORTA: Ana Ekran (Home)
            TabBarButton(icon: "house.fill", tab: .home, selectedTab: $selectedTab)
            
            // 3. SAĞ: Arkadaşlar (Friends)
            TabBarButton(icon: "person.2.fill", tab: .friends, selectedTab: $selectedTab)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        
        // --- LIQUID GLASS EFEKTİ ---
        .background(.ultraThinMaterial)
        .background(
            LinearGradient(
                colors: [.white.opacity(0.15), .white.opacity(0.05), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 35, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.1), .black.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
        .padding(.horizontal, 40)
        .padding(.bottom, 10)
    }
}

struct TabBarButton: View {
    let icon: String
    let tab: Tab
    @Binding var selectedTab: Tab
    
    var isSelected: Bool {
        selectedTab == tab
    }
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 6) {
                // İKON
                Image(systemName: icon)
                    .font(.system(size: 24, weight: isSelected ? .bold : .medium))
                    // DÜZELTME BURADA: Color.primary diyerek kesin siyah/beyaz yapıyoruz
                    .foregroundStyle(Color.primary)
                    .opacity(isSelected ? 1.0 : 0.4)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .shadow(color: isSelected ? Color.primary.opacity(0.3) : .clear, radius: 8)
                
                // NOKTA
                if isSelected {
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 4, height: 4)
                        .transition(.scale.combined(with: .opacity))
                        .shadow(color: Color.primary.opacity(0.5), radius: 2)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        // KRİTİK DÜZELTME: Bu satır varsayılan mavi rengi iptal eder
        .buttonStyle(.plain)
    }
}
