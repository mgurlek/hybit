//
//  AddHabitView.swift
//  hybit
//
//  Created by Mert Gurlek on 12.02.2026.
//

import SwiftUI

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    
    var viewModel: HabitListViewModel?
    
    @State private var habitName = ""
    @State private var habitTarget = 30
    @State private var hasNotification = false
    @State private var enableRandomNotification = false
    @State private var selectedTime = Date()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 1. İSİM ALANI
                    VStack(alignment: .leading, spacing: 12) {
                        Text("HEDEFİN ADI")
                            .font(.caption2).fontWeight(.black).foregroundStyle(.secondary)
                            .padding(.leading, 4)
                        
                        TextField("Örn: Kitap Oku...", text: $habitName)
                            .font(.system(size: 22, weight: .semibold))
                            .padding()
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    
                    // 2. HEDEF ZİNCİR
                    targetSection
                    
                    // 3. BİLDİRİM KUTUSU
                    notificationSection
                }
                .padding()
                .padding(.top, 10)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Yeni Hedef")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Başla") {
                        guard !habitName.isEmpty else { return }
                        viewModel?.addHabit(
                            name: habitName,
                            colorHex: "000000",
                            target: habitTarget,
                            notificationTime: hasNotification ? selectedTime : nil,
                            random: hasNotification ? enableRandomNotification : false
                        )
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(habitName.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Hedef Zincir
    
    private var targetSection: some View {
        VStack(spacing: 15) {
            Text("HEDEF ZİNCİR")
                .font(.caption2).fontWeight(.black).foregroundStyle(.secondary)
            
            HStack(spacing: 25) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if habitTarget > 7 {
                        withAnimation(.snappy) { habitTarget -= 1 }
                    }
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 55, height: 55)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
                .foregroundStyle(.primary)
                
                VStack(spacing: 0) {
                    Text("\(habitTarget)")
                        .font(.system(size: 56, weight: .black))
                        .contentTransition(.numericText(countsDown: false))
                    Text("GÜN")
                        .font(.caption).fontWeight(.bold).foregroundStyle(.secondary)
                }
                .frame(width: 110)
                
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if habitTarget < 365 {
                        withAnimation(.snappy) { habitTarget += 1 }
                    }
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 55, height: 55)
                        .background(Color.primary)
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .adaptiveThinMaterial(cornerRadius: 24)
    }
    
    // MARK: - Bildirim
    
    private var notificationSection: some View {
        VStack(spacing: 0) {
            // Toggle Satırı
            Toggle(isOn: $hasNotification) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(hasNotification ? .white : .primary)
                        .padding(10)
                        .background(hasNotification ? Color.primary : Color.gray.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading) {
                        Text("Hatırlatıcı")
                            .font(.headline)
                        Text("Belirli bir saatte bildirim al")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            
            // Genişleyen Alan
            if hasNotification {
                VStack(spacing: 0) {
                    Divider()
                    
                    // Random Toggle
                    Toggle(isOn: $enableRandomNotification) {
                        HStack {
                            Image(systemName: "dice.fill")
                                .foregroundStyle(enableRandomNotification ? .white : .primary)
                                .padding(10)
                                .background(enableRandomNotification ? Color.primary : Color.gray.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                Text("Sürpriz Yap")
                                    .font(.headline)
                                Text("Rastgele bir anda dürt")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    
                    Divider()
                    
                    // Saat Seçici
                    DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding(.vertical, 5)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .adaptiveThinMaterial(cornerRadius: 24)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: hasNotification)
    }
}
