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
    var targetStreak: Int
    var notificationTime: Date?
    var allowRandomNotifications: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \Completion.habit)
    var completions: [Completion]? = []
    
    init(name: String, hexColor: String, iconSymbol: String = "star.fill", targetStreak: Int = 30, notificationTime: Date? = nil, allowRandomNotifications: Bool = false) {
        self.id = UUID().uuidString
        self.name = name
        self.creationDate = Date()
        self.hexColor = hexColor
        self.iconSymbol = iconSymbol
        self.targetStreak = targetStreak
        self.notificationTime = notificationTime
        self.allowRandomNotifications = allowRandomNotifications
    }
    
    // GÜNCELLENMİŞ MANTIK: Sanal Gün (04:00'e kadar dünü sayar)
    var currentStreak: Int {
        let sortedCompletions = (completions ?? []).sorted { $0.date > $1.date }
        var streak = 0
        let calendar = Calendar.current
        
        // ŞİMDİ EXTENSION'I TANIYACAK
        let todayLogical = Date().logicalDate
        
        // 1. Bugün (veya dün gece 04:00'e kadar) yapılmış mı?
        let isDoneToday = sortedCompletions.contains { $0.date.isSameLogicalDay(as: Date()) }
        
        var checkDate = isDoneToday ? todayLogical : calendar.date(byAdding: .day, value: -1, to: todayLogical)!
        
        if !isDoneToday {
             let isDoneYesterday = sortedCompletions.contains { $0.date.isSameLogicalDay(as: checkDate) }
             if !isDoneYesterday { return 0 }
        }

        while true {
            let targetDate = checkDate
            let found = sortedCompletions.contains { $0.date.isSameLogicalDay(as: targetDate) }
            
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

// MARK: - DATE EXTENSION (Buraya taşıdık, artık Widget da görecek)
extension Date {
    // Hybit için "Mantıksal Gün"
    // Eğer saat sabah 04:00'ten önceyse, bu tarih bir önceki güne aittir.
    var logicalDate: Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: self)
        
        if hour < 4 {
            return calendar.date(byAdding: .day, value: -1, to: self)!
        }
        return self
    }
    
    // İki tarihin "Hybit Mantığına Göre" aynı gün olup olmadığını kontrol et
    func isSameLogicalDay(as otherDate: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self.logicalDate, inSameDayAs: otherDate.logicalDate)
    }
}
