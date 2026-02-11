//
//  GlassModifiers.swift
//  hybit
//
//  Created by Mert Gurlek on 9.02.2026.
//
//  Adaptive glass effects - iOS 26+ gets Liquid Glass, older versions get classic materials

import SwiftUI

// MARK: - Adaptive Glass View Extensions

extension View {
    
    /// Applies glass effect on iOS 26+, falls back to ultraThinMaterial on older versions
    /// - Parameter cornerRadius: Corner radius for the glass shape
    /// - Returns: Modified view with adaptive glass background
    @ViewBuilder
    func adaptiveGlassBackground(cornerRadius: CGFloat = 20) -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(in: .rect(cornerRadius: cornerRadius))
        } else {
            self
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
    
    /// Applies glass effect with overlay border on iOS 26+, material + border on older versions
    /// - Parameters:
    ///   - cornerRadius: Corner radius for the glass shape
    ///   - borderOpacity: Opacity of the border stroke
    /// - Returns: Modified view with glass background and border
    @ViewBuilder
    func adaptiveGlassCard(cornerRadius: CGFloat = 36) -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(in: .rect(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.5), .white.opacity(0.1), .black.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        } else {
            self
                .background(.ultraThinMaterial)
                .background(
                    LinearGradient(
                        colors: [.white.opacity(0.1), .white.opacity(0.02), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .white.opacity(0.1), .black.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        }
    }
    
    /// Applies thin material background - glass on iOS 26+, thinMaterial on older
    /// - Parameter cornerRadius: Corner radius for the shape
    /// - Returns: Modified view with adaptive thin material
    @ViewBuilder
    func adaptiveThinMaterial(cornerRadius: CGFloat = 24) -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular.tint(.gray.opacity(0.1)), in: .rect(cornerRadius: cornerRadius))
        } else {
            self
                .background(.thinMaterial)
        }
    }
    
    /// Applies glass-like presentation background on iOS 26+, ultraThinMaterial on older
    /// Note: Sheets automatically get glass effect on iOS 26 when using material backgrounds
    @ViewBuilder
    func adaptivePresentationBackground() -> some View {
        if #available(iOS 26, *) {
            // iOS 26 sheets automatically adopt glass look with materials
            self.presentationBackground(.regularMaterial)
        } else {
            self.presentationBackground(.ultraThinMaterial)
        }
    }
}
