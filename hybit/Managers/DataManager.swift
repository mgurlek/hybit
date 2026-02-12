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
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: DataManager.appGroupID) {
            let databaseURL = containerURL.appendingPathComponent("default.store")
            print("📦 DataManager path: \(databaseURL.path)")
            
            let localConfig = ModelConfiguration(url: databaseURL)
            
            do {
                modelContainer = try ModelContainer(for: schema, configurations: localConfig)
                print("✅ DataManager: Veritabanı başlatıldı (App Group)")
                return
            } catch {
                print("⚠️ App Group DB hatası: \(error)")
                // Bozuk veritabanını sil ve tekrar dene
                Self.deleteCorruptStore(at: databaseURL)
                do {
                    modelContainer = try ModelContainer(for: schema, configurations: localConfig)
                    print("✅ DataManager: Temiz veritabanı oluşturuldu")
                    return
                } catch {
                    print("❌ Temiz DB de başarısız: \(error)")
                }
            }
        } else {
            print("⚠️ App Group bulunamadı, varsayılan konum kullanılıyor")
        }
        
        // Fallback: varsayılan konum
        do {
            let defaultConfig = ModelConfiguration()
            modelContainer = try ModelContainer(for: schema, configurations: defaultConfig)
            print("✅ DataManager: Varsayılan konumda başlatıldı")
        } catch {
            fatalError("Veritabanı başlatılamadı: \(error)")
        }
    }
    
    /// Bozuk veritabanı dosyalarını sil
    private static func deleteCorruptStore(at url: URL) {
        let fm = FileManager.default
        let extensions = ["", "-wal", "-shm"]
        for ext in extensions {
            let fileURL = URL(fileURLWithPath: url.path + ext)
            try? fm.removeItem(at: fileURL)
        }
        print("🗑️ Bozuk veritabanı silindi: \(url.lastPathComponent)")
    }
}
