//
//  NotificationManager.swift
//  hybit
//
//  Created by Mert Gurlek on 7.02.2026.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    // 1. İzin İsteme
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("Bildirim izni alındı.")
            } else if let error = error {
                print("İzin hatası: \(error.localizedDescription)")
            }
        }
    }
    
    // 2. Bildirim Planlama
    func scheduleNotification(for habit: Habit) {
        // Önce eski bildirimleri temizle (Çakışma olmasın)
        cancelNotification(for: habit)
        
        // Eğer saati yoksa işlem yapma
        guard let time = habit.notificationTime else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Hybit: \(habit.name)"
        content.body = randomMotivationMessage() // Her seferinde farklı motive etsin
        content.sound = .default
        
        // --- KRİTİK NOKTA: EN ÜSTE SABİTLEME ---
        // Bu ayar bildirimin "Zamana Duyarlı" olduğunu söyler (Focus modlarını deler)
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
            content.relevanceScore = 1.0 // En yüksek öncelik (En tepede göster)
        }
        
        // A. SABİT SAAT (Her Gün)
        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: habit.id, // ID ile takip ediyoruz
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
        
        // B. RASTGELE BİLDİRİM (Eğer seçildiyse)
        if habit.allowRandomNotifications {
            scheduleRandomNotification(for: habit, baseContent: content)
        }
        
        // Test için konsola yazdır (İsteğe bağlı)
        print("Bildirim kuruldu: \(habit.name) - Saat: \(dateComponents.hour!):\(dateComponents.minute!)")
    }
    
    // Rastgele Bildirim Mantığı
    private func scheduleRandomNotification(for habit: Habit, baseContent: UNMutableNotificationContent) {
        // Rastgele bildirim için içerik kopyala ama başlığı değiştir
        let randomContent = baseContent
        randomContent.title = "🎲 Sürpriz: \(habit.name)"
        randomContent.body = "Beklenmedik bir an! Hadi seriyi bozma."
        
        // Sabah 09:00 ile Akşam 21:00 arası rastgele bir saat seç
        let randomHour = Int.random(in: 9...21)
        let randomMinute = Int.random(in: 0...59)
        
        var dateComponents = DateComponents()
        dateComponents.hour = randomHour
        dateComponents.minute = randomMinute
        
        // Bu bildirim her gün tekrarlar (Ama saati her gün değişmez, iOS kısıtlaması)
        // İpucu: Tam rastgelelik için kullanıcı uygulamayı her açtığında burayı tetikleyeceğiz.
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "\(habit.id)-random", // Farklı ID
            content: randomContent,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // 3. Bildirim İptali (Habit silinirse veya bildirim kapanırsa)
    func cancelNotification(for habit: Habit) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [habit.id, "\(habit.id)-random"])
        print("Bildirim iptal edildi: \(habit.name)")
    }
    
    // 4. TEST İÇİN: Bekleyen Bildirimleri Listele (BUNU EKLEDİM)
    func checkPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("\n--- 🔔 BEKLEYEN BİLDİRİMLER (\(requests.count)) ---")
            for request in requests {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let date = trigger.nextTriggerDate() {
                    print("📌 ID: \(request.identifier) | Zaman: \(date.formatted(date: .omitted, time: .shortened))")
                } else {
                    print("📌 ID: \(request.identifier) | Tetikleyici: \(String(describing: request.trigger))")
                }
            }
            print("-------------------------------------------\n")
        }
    }
    
    // Motive Edici Mesajlar
    private func randomMotivationMessage() -> String {
        let messages = [
            "Zinciri kırma, bugün senin günün!",
            "Küçük bir adım, büyük bir sonuç.",
            "Kendine verdiğin sözü tutma vakti.",
            "Sadece 5 dakikanı alacak, hadi!",
            "Gelecekteki sen buna teşekkür edecek."
        ]
        return messages.randomElement() ?? "Hadi yapalım!"
    }
}
