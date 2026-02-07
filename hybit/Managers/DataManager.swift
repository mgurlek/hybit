//
//  DataManager.swift
//  hybit
//
//  Created by Mert Gurlek on 7.02.2026.
//

import Foundation
import SwiftData

@MainActor
class DataManager {
    static let shared = DataManager()
    
    let modelContainer: ModelContainer
    
    private init() {
        let schema = Schema([
            Habit.self,
            Completion.self
        ])
        
        // YÖNTEM DEĞİŞİKLİĞİ: "groupContainer" yerine doğrudan dosya URL'si veriyoruz.
        // Bu yöntem çok daha garantidir.
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gurtech.hybit") else {
            fatalError("App Group klasörü bulunamadı! Lütfen 'Signing & Capabilities' ayarlarını kontrol et.")
        }
        
        // Veritabanı dosyasının tam adresi
        let databaseURL = url.appendingPathComponent("default.store")
        
        // Konfigürasyon
        let modelConfiguration = ModelConfiguration(url: databaseURL)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: modelConfiguration)
        } catch {
            fatalError("Veritabanı başlatılamadı: \(error)")
        }
    }
}
