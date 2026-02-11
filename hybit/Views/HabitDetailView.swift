//
//  HabitDetailView.swift
//  hybit
//
//  Created by Mert Gurlek on 7.02.2026.
//

import SwiftUI
import SwiftData

struct HabitDetailView: View {
    let habit: Habit
    var viewModel: HabitListViewModel? // Kaydetme ve silme işlemleri için
    @Environment(\.dismiss) private var dismiss
    
    // Silme onayı
    @State private var showDeleteConfirmation = false
    
    // --- BİLDİRİM AYARLARI İÇİN STATE'LER ---
    @State private var isNotificationEnabled: Bool = false
    @State private var notificationTime: Date = Date()
    @State private var isRandom: Bool = false
    
    // Takvim Sütunları (7 Gün)
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 35) {
                    
                    // 1. Üst İstatistikler (Hedef vs Mevcut)
                    HStack(spacing: 40) {
                        StatView(title: "Mevcut Zincir", value: "\(habit.currentStreak)", isBig: true)
                        StatView(title: "Hedef", value: "\(habit.targetStreak)", isBig: false)
                    }
                    .padding(.top, 20)
                    
                    Divider()
                    
                    // 2. Minimal Takvim (Bu Ay)
                    VStack(alignment: .leading, spacing: 20) {
                        Text(Date().formatted(.dateTime.month(.wide).year()))
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .padding(.leading)
                        
                        LazyVGrid(columns: columns, spacing: 15) {
                            // Haftanın Günleri Başlıkları
                            ForEach(["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"], id: \.self) { day in
                                Text(day)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                            }
                            
                            // Günler Grid'i
                            ForEach(daysInCurrentMonth(), id: \.self) { date in
                                DayCircle(date: date, habit: habit)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                    
                    // 3. YENİ: BİLDİRİM AYARLARI
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Bildirim Ayarları")
                            .font(.headline)
                            .padding(.leading)
                        
                        VStack(spacing: 15) {
                            Toggle("Bildirimleri Aç", isOn: $isNotificationEnabled)
                                .tint(.primary)
                            
                            if isNotificationEnabled {
                                Divider()
                                
                                DatePicker("Bildirim Saati", selection: $notificationTime, displayedComponents: .hourAndMinute)
                                
                                Toggle("Rastgele Saatlerde Hatırlat", isOn: $isRandom)
                                    .tint(.orange)
                            }
                        }
                        .padding()
                        .adaptiveThinMaterial(cornerRadius: 15)
                        .padding(.horizontal)
                    }
                    
                    Divider()
                    
                    // 4. SİLME BUTONU
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Bu Hedefi Sil")
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(habit.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(.primary)
                }
            }
            // SİLME ONAY UYARISI
            .alert("Hedefi Sil?", isPresented: $showDeleteConfirmation) {
                Button("Vazgeç", role: .cancel) { }
                Button("Sil", role: .destructive) {
                    viewModel?.deleteHabit(habit)
                    dismiss()
                }
            } message: {
                Text("'\(habit.name)' hedefini ve tüm verilerini silmek istediğine emin misin?")
            }
            // EKRAN AÇILDIĞINDA MEVCUT AYARLARI YÜKLE
            .onAppear {
                loadCurrentNotificationSettings()
            }
            // DEĞİŞİKLİK YAPILDIĞINDA OTOMATİK KAYDET VE BİLDİRİMLERİ GÜNCELLE
            .onChange(of: isNotificationEnabled) { _, _ in updateHabitNotification() }
            .onChange(of: notificationTime) { _, _ in updateHabitNotification() }
            .onChange(of: isRandom) { _, _ in updateHabitNotification() }
        }
    }
    
    // MARK: - Bildirim Fonksiyonları
    
    private func loadCurrentNotificationSettings() {
        if let time = habit.notificationTime {
            self.isNotificationEnabled = true
            self.notificationTime = time
        } else if habit.allowRandomNotifications {
            self.isNotificationEnabled = true
        } else {
            self.isNotificationEnabled = false
        }
        self.isRandom = habit.allowRandomNotifications
    }
    
    private func updateHabitNotification() {
        // 1. Eski bildirimi sistemden iptal et
        NotificationManager.shared.cancelNotification(for: habit)
        
        // 2. Modeli güncelle
        if isNotificationEnabled {
            habit.notificationTime = notificationTime
            habit.allowRandomNotifications = isRandom
            
            // 3. Yeni bildirimi kur
            NotificationManager.shared.scheduleNotification(for: habit)
        } else {
            habit.notificationTime = nil
            habit.allowRandomNotifications = false
        }
        
        // 4. Veritabanına kaydet (ve widget'ları tetikle)
        viewModel?.saveContext()
    }
    
    // MARK: - Yardımcı Fonksiyonlar
    
    // Bu ayın günlerini getiren yardımcı fonksiyon
    func daysInCurrentMonth() -> [Date] {
        let calendar = Calendar.current
        _ = calendar.dateInterval(of: .month, for: Date())!
        
        var days: [Date] = []
        let range = calendar.range(of: .day, in: .month, for: Date())!
        let components = calendar.dateComponents([.year, .month], from: Date())
        
        for day in range {
            var newComponents = components
            newComponents.day = day
            if let date = calendar.date(from: newComponents) {
                days.append(date)
            }
        }
        return days
    }
}

// Minimal İstatistik Bileşeni
struct StatView: View {
    let title: String
    let value: String
    let isBig: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: isBig ? 48 : 32, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
    }
}

// Takvimdeki Yuvarlak (Dolu/Boş)
struct DayCircle: View {
    let date: Date
    let habit: Habit
    
    var isCompleted: Bool {
        guard let completions = habit.completions else { return false }
        return completions.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    var isFuture: Bool {
        return date > Date()
    }
    
    var body: some View {
        ZStack {
            if isCompleted {
                // DOLU DAİRE (Yapıldı)
                Circle()
                    .fill(Color.primary)
                    .frame(width: 30, height: 30)
                
                // İçine gün numarası (Beyaz)
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(uiColor: .systemBackground))
            } else {
                // BOŞ DAİRE (Yapılmadı veya Gelecek)
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 2)
                    .frame(width: 30, height: 30)
                
                // İçine gün numarası (Gri)
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
