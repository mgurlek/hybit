//
//  AppDesignSystem.swift
//  hybit
//
//  Created by Mert Gurlek on 13.02.2026.
//

import SwiftUI
import Combine

// MARK: - Design System Modifier
struct AppStyleContainerModifier: ViewModifier {
    // Simulating iOS 26 check
    // In reality, we use this flag to toggle the "Future" design
    var isLiquidGlass: Bool = true 
    
    func body(content: Content) -> some View {
        if isLiquidGlass {
            content
                .padding()
                .background(.ultraThinMaterial) // Liquid Glass effect
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        } else {
            // Legacy / Standard Style
            content
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

extension View {
    func appStyleContainer() -> some View {
        self.modifier(AppStyleContainerModifier())
    }
}

// MARK: - Adaptive Keyboard Container
struct AdaptiveKeyboardContainer<Content: View>: View {
    @State private var keyboardHeight: CGFloat = 0
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background fills entire screen
                Color.clear
                
                content
                    .padding(.bottom, keyboardHeight > 0 ? keyboardHeight : 0)
                    .animation(.easeOut(duration: 0.25), value: keyboardHeight)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom) // We handle it manually
        }
        .onReceive(Publishers.keyboardHeight) { height in
            self.keyboardHeight = height
        }
    }
}

// MARK: - Keyboard Publisher Helper
extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { notification -> CGFloat in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
            }
        
        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
        
        return Merge(willShow, willHide)
            .eraseToAnyPublisher()
    }
}
