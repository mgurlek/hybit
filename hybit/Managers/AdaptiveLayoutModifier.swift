//
//  AdaptiveLayoutModifier.swift
//  hybit
//
//  Created by Mert Gurlek on 9.02.2026.
//
//  Provides adaptive layouts for iPhone, iPad, and Mac

import SwiftUI

// MARK: - Device Type Detection

enum DeviceLayout {
    case phone          // iPhone compact
    case phoneLandscape // iPhone landscape
    case padPortrait    // iPad portrait
    case padLandscape   // iPad landscape or Mac
    
    var columnCount: Int {
        switch self {
        case .phone, .phoneLandscape: return 1
        case .padPortrait: return 2
        case .padLandscape: return 3
        }
    }
    
    var usesGrid: Bool {
        switch self {
        case .phone, .phoneLandscape: return false
        case .padPortrait, .padLandscape: return true
        }
    }
}

// MARK: - Environment Key for Layout

struct DeviceLayoutKey: EnvironmentKey {
    static let defaultValue: DeviceLayout = .phone
}

extension EnvironmentValues {
    var deviceLayout: DeviceLayout {
        get { self[DeviceLayoutKey.self] }
        set { self[DeviceLayoutKey.self] = newValue }
    }
}

// MARK: - Layout Detection Modifier

struct AdaptiveLayoutModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var currentLayout: DeviceLayout {
        // Mac veya iPad landscape
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            return .padLandscape
        }
        // iPad portrait
        if horizontalSizeClass == .regular && verticalSizeClass == .compact {
            return .padPortrait
        }
        // iPad portrait (farklı durum)
        if horizontalSizeClass == .regular {
            return .padPortrait
        }
        // iPhone landscape
        if verticalSizeClass == .compact {
            return .phoneLandscape
        }
        // iPhone portrait (varsayılan)
        return .phone
    }
    
    func body(content: Content) -> some View {
        content
            .environment(\.deviceLayout, currentLayout)
    }
}

extension View {
    /// Applies adaptive layout detection to the view hierarchy
    func adaptiveLayout() -> some View {
        modifier(AdaptiveLayoutModifier())
    }
}

// MARK: - Adaptive Grid Helper

struct AdaptiveHabitGrid<Content: View>: View {
    @Environment(\.deviceLayout) private var layout
    let items: [Habit]
    let content: (Habit) -> Content
    
    init(items: [Habit], @ViewBuilder content: @escaping (Habit) -> Content) {
        self.items = items
        self.content = content
    }
    
    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 20), count: layout.columnCount)
    }
    
    var body: some View {
        if layout.usesGrid {
            // iPad/Mac: Grid düzeni
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(items, id: \.id) { item in
                        content(item)
                            .aspectRatio(0.75, contentMode: .fit)
                    }
                }
                .padding()
            }
        } else {
            // iPhone: Carousel düzeni (mevcut)
            TabView {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    content(item)
                        .tag(index)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .padding(.bottom, 80)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}
