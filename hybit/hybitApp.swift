//
//  hybitApp.swift
//  hybit
//
//  Created by Mert Gurlek on 7.02.2026.
//

import SwiftUI
import SwiftData

@main
struct hybitApp: App {
    // Shared DataManager'dan container'ı alıyoruz
    let container = DataManager.shared.modelContainer
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // SwiftData'yı tüm uygulamaya enjekte et
        .modelContainer(container)
    }
}
