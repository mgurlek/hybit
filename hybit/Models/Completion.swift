//
//  Completion.swift
//  hybit
//
//  Created by Mert Gurlek on 7.02.2026.
//

import Foundation
import SwiftData

@Model
final class Completion {
    var date: Date
    
    // Alışkanlık ile ilişki (Habit modelindeki 'completions' ile ters ilişki)
    var habit: Habit?
    
    // DÜZELTME BURADA: init fonksiyonuna 'habit' parametresini ekledik.
    init(date: Date, habit: Habit) {
        self.date = date
        self.habit = habit
    }
}
