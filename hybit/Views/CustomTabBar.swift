//
//  CustomTabBar.swift
//  hybit
//
//  Created by Mert Gurlek on 7.02.2026.
//

import SwiftUI

enum Tab: String, CaseIterable {
    case home = "house.fill"
    case feed = "safari.fill" // Akış ikonu
    case friends = "person.2.fill" // Arkadaş ikonu
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    
    @Namespace private var namespace
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.rawValue)
                            .font(.title2) // Boyut sabit
                            .fontWeight(.medium) // DİKKAT: Kalınlık artık sabit (Değişmiyor)
                            
                        
                        // Seçim Noktası
                        if selectedTab == tab {
                            Circle()
                                .fill(Color.primary.opacity(0.8))
                                .frame(width: 5, height: 5)
                                .matchedGeometryEffect(id: "TAB_DOT", in: namespace)
                        } else {
                            // Yer tutucu
                            Circle().fill(.clear).frame(width: 5, height: 5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    // Sadece renk değişiyor: Siyah vs Gri
                    .foregroundStyle(selectedTab == tab ? Color.primary : Color(uiColor: .systemGray))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background {
            // Liquid Glass Efekti
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
            }
        }
        .clipShape(Capsule())
        .padding(.horizontal, 50)
        .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
    }
}
