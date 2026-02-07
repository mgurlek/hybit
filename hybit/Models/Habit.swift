//
//  Habit.swift
//  hybit
//
//  Created by Mert Gurlek on 7.02.2026.
//

import Foundation
import SwiftData

@Model
final class Habit {
    @Attribute(.unique) var id: String
    var name: String
    var creationDate: Date
    var hexColor: String
    var iconSymbol: String
    var targetStreak: Int // YENİ: Hedeflenen Zincir Sayısı
    
    @Relationship(deleteRule: .cascade, inverse: \Completion.habit)
    var completions: [Completion]? = []
    
    init(name: String, hexColor: String, iconSymbol: String = "star.fill", targetStreak: Int = 30) {
        self.id = UUID().uuidString
        self.name = name
        self.creationDate = Date()
        self.hexColor = hexColor
        self.iconSymbol = iconSymbol
        self.targetStreak = targetStreak
    }
    
    // Hesaplanan Özellik: Mevcut Zincir
    var currentStreak: Int {
        let sortedCompletions = (completions ?? []).sorted { $0.date > $1.date }
        var streak = 0
        let calendar = Calendar.current
        
        let today = Date()
        let isDoneToday = sortedCompletions.contains { calendar.isDate($0.date, inSameDayAs: today) }
        
        var checkDate = isDoneToday ? today : calendar.date(byAdding: .day, value: -1, to: today)!
        
        if !isDoneToday {
             let isDoneYesterday = sortedCompletions.contains { calendar.isDate($0.date, inSameDayAs: checkDate) }
             if !isDoneYesterday { return 0 }
        }

        while true {
            let targetDate = checkDate
            let found = sortedCompletions.contains { calendar.isDate($0.date, inSameDayAs: targetDate) }
            
            if found {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        
        return streak
    }
}
