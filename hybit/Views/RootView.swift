//
//  RootView.swift
//  hybit
//
//  Created by Mert Gurlek on 12.02.2026.
//

import SwiftUI

struct RootView: View {
    var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            switch authManager.authState {
            case .loading:
                // Uygulama açılışı — oturum durumu kontrol ediliyor
                ZStack {
                    Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Yükleniyor...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
            case .signedOut:
                LoginView(authManager: authManager)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                
            case .verifying:
                VerifyView(authManager: authManager)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                
            case .profileNeeded:
                OnboardingView(authManager: authManager)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                
            case .signedIn:
                ContentView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.smooth(duration: 0.35), value: authManager.authState)
    }
}
