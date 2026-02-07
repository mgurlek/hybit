//
//  HabitListViewModel.swift
//  hybit
//
//  Created by Mert Gurlek on 7.02.2026.
//
import WidgetKit
import Foundation
import SwiftData
import SwiftUI

@Observable
class HabitListViewModel {
    var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Alışkanlık Ekleme
    func addHabit(name: String, colorHex: String, target: Int, notificationTime: Date?, random: Bool) {
        let habit = Habit(
            name: name,
            hexColor: colorHex,
            targetStreak: target,
            notificationTime: notificationTime,
            allowRandomNotifications: random
        )
        
        modelContext.insert(habit)
        saveContext()
        
        // Bildirimi Planla
        NotificationManager.shared.scheduleNotification(for: habit)
    }
    
    // MARK: - Alışkanlık Tamamla / Geri Al
    func toggleHabit(_ habit: Habit) {
        let today = Date()
        
        // 1. Durumu Kontrol Et (Mantıksal Gün Kullanarak)
        // Not: Habit.swift içinde tanımladığımız Date uzantısını kullanıyoruz.
        if let completions = habit.completions,
           let existingCompletion = completions.first(where: { $0.date.isSameLogicalDay(as: today) }) {
            
            // A. GERİ ALMA (Undo)
            modelContext.delete(existingCompletion)
            
            // Geri alındığı için bildirimi tekrar kur (Bugün henüz bitmedi, bildirim gelmeli)
            NotificationManager.shared.scheduleNotification(for: habit)
            
        } else {
            // B. TAMAMLAMA (Done)
            let completion = Completion(date: today, habit: habit)
            modelContext.insert(completion)
            
            // İş yapıldı, bugünkü bildirimi sustur!
            NotificationManager.shared.cancelNotification(for: habit)
        }
        
        saveContext()
    }
    
    // MARK: - Bildirimleri Tazele (Uygulama açılınca)
    // ContentView.swift tarafında çağrılan fonksiyon bu
    func refreshNotifications(for habits: [Habit]) {
        let today = Date()
        
        for habit in habits {
            // Eğer alışkanlığın bildirim saati varsa
            if habit.notificationTime != nil {
                
                // Bugün yapılmış mı kontrol et
                let isDoneToday = (habit.completions ?? []).contains { $0.date.isSameLogicalDay(as: today) }
                
                if !isDoneToday {
                    // Yapılmamışsa: Bildirimi kur (Silindiyse geri gelir)
                    NotificationManager.shared.scheduleNotification(for: habit)
                } else {
                    // Yapılmışsa: Bildirimi iptal et (Garanti olsun)
                    NotificationManager.shared.cancelNotification(for: habit)
                }
            }
        }
    }
    
    // MARK: - Alışkanlık Silme
    func deleteHabit(_ habit: Habit) {
        NotificationManager.shared.cancelNotification(for: habit)
        modelContext.delete(habit)
        saveContext()
    }
    
    
    // MARK: - Kaydetme Yardımcısı
    func saveContext() {
        do {
            try modelContext.save()
            
            // --- EKLENEN KISIM ---
            // Veritabanında bir değişiklik (Ekleme/Silme/İşaretleme) olduğunda Widget'ı uyandır
            WidgetCenter.shared.reloadAllTimelines()
            // ---------------------
            
        } catch {
            print("Kaydetme hatası: \(error)")
        }
    }
}
