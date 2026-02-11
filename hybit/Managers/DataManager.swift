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
    
    // App Group ID (widget ile paylaşım için)
    static let appGroupID = "group.com.gurtech.hybit"
    
    private init() {
        let schema = Schema([
            Habit.self,
            Completion.self
        ])
        
        // App Group container URL
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: DataManager.appGroupID) else {
            fatalError("App Group klasörü bulunamadı! Lütfen 'Signing & Capabilities' ayarlarını kontrol et.")
        }
        
        // Orijinal veritabanı adını kullan (migration sorunu olmasın)
        let databaseURL = containerURL.appendingPathComponent("default.store")
        
        // Önce CloudKit olmadan dene (daha güvenli)
        let localConfig = ModelConfiguration(url: databaseURL)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: localConfig)
            print("✅ DataManager: Veritabanı başlatıldı")
        } catch {
            print("❌ DataManager hatası: \(error)")
            // Son çare: Varsayılan konumda dene
            do {
                let defaultConfig = ModelConfiguration()
                modelContainer = try ModelContainer(for: schema, configurations: defaultConfig)
                print("⚠️ DataManager: Varsayılan konumda başlatıldı")
            } catch {
                fatalError("Veritabanı başlatılamadı: \(error)")
            }
        }
    }
}

