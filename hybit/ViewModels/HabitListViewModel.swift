//
//  HabitListViewModel.swift
//  hybit
//
//  Created by Mert Gurlek on 7.02.2026.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class HabitListViewModel {
    var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // Yeni Alışkanlık Ekleme (Hedefli)
    func addHabit(name: String, colorHex: String, target: Int) {
        let habit = Habit(name: name, hexColor: colorHex, targetStreak: target)
        modelContext.insert(habit)
        saveContext()
    }
    
    // Alışkanlığı Tamamla / Geri Al
    func toggleHabit(_ habit: Habit) {
        let calendar = Calendar.current
        let today = Date()
        
        if let completions = habit.completions,
           let existingCompletion = completions.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            // Bugün zaten yapılmış, geri al (Sil)
            modelContext.delete(existingCompletion)
        } else {
            // Bugün yapılmamış, yeni kayıt ekle
            let completion = Completion(date: today, habit: habit)
            modelContext.insert(completion)
        }
        
        saveContext()
    }
    
    // Alışkanlık Silme
    func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)
        saveContext()
    }
    
    // EKSİK OLAN FONKSİYON BU:
    func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Kaydetme hatası: \(error)")
        }
    }
}
