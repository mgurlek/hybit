//
//  LiquidGlassStyle.swift
//  hybit
//
//  Created by Mert Gurlek on 13.02.2026.
//

import SwiftUI

struct LiquidGlassModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(24)
            .background(.regularMaterial) // Adaptive Material (Light/Dark compliant)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5) // Adaptive Border
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05),
                radius: 15, x: 0, y: 5
            ) // Adaptive Shadow
    }
}

extension View {
    /// Applies the Native Apple Card style
    func liquidGlass() -> some View {
        self.modifier(LiquidGlassModifier())
    }
    
    /// Applies the standard system background (Adaptive)
    func monochromeBackground() -> some View {
        self.background(Color(uiColor: .systemGroupedBackground)) // Subtle base for cards
            .ignoresSafeArea()
    }
}
