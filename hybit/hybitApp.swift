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
    // Veritabanı (SwiftData) kurulumu
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Habit.self,
            Completion.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.gurtech.hybit") // Widget ile paylaşım için
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("ModelContainer oluşturulamadı: \(error)")
        }
    }()
    
    // --- YENİ: Uygulama Başlarken İzin İste ---
    init() {
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
