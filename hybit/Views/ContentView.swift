//
//  ContentView.swift
//  hybit
//
//  Created by Mert Gurlek on 7.02.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    // YENİ: Uygulamanın durumunu (Aktif/Arka Plan) takip etmek için
    @Environment(\.scenePhase) var scenePhase
    
    @State private var viewModel: HabitListViewModel?
    
    @State private var selectedTab: Tab = .home
    @State private var showAddSheet = false
    @State private var showProfileSheet = false
    
    // --- VERİ GİRİŞ DEĞİŞKENLERİ ---
    @State private var newHabitName = ""
    @State private var newHabitTarget = 30
    @State private var hasNotification = false
    @State private var selectedTime = Date()
    @State private var enableRandomNotification = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // ÜST BAR
                    HStack {
                        Button { showAddSheet = true } label: {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(Color.primary)
                        }
                        Spacer()
                        Text(navTitle).font(.headline).fontWeight(.semibold)
                        Spacer()
                        Button { showProfileSheet = true } label: {
                            Image(systemName: "person.circle")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(Color.gray)
                        }
                    }
                    .padding(.horizontal).padding(.bottom, 10)
                    
                    // İÇERİK
                    TabView(selection: $selectedTab) {
                        
                        ContentUnavailableView("Akış", systemImage: "safari", description: Text("Yakında."))
                            .tag(Tab.feed)
                        
                        HomeView(viewModel: viewModel)
                            .tag(Tab.home)
                        
                        ContentUnavailableView("Arkadaşlar", systemImage: "person.2", description: Text("Yakında."))
                            .tag(Tab.friends)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                
                CustomTabBar(selectedTab: $selectedTab).padding(.bottom, 10)
            }
            .toolbar(.hidden, for: .navigationBar)
            
            // --- LIQUID GLASS SHEET ---
            .sheet(isPresented: $showAddSheet) {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 20) {
                            
                            // 1. İSİM ALANI (Glass Card)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("HEDEFİN ADI")
                                    .font(.caption2).fontWeight(.black).foregroundStyle(.secondary)
                                    .padding(.leading, 4)
                                
                                TextField("Örn: Kitap Oku...", text: $newHabitName)
                                    .font(.system(size: 22, weight: .semibold))
                                    .padding()
                                    // İÇ CAM EFEKTİ (Thin Material)
                                    .background(.thinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                            
                            // 2. HEDEF ZİNCİR (Glass Card)
                            VStack(spacing: 15) {
                                Text("HEDEF ZİNCİR")
                                    .font(.caption2).fontWeight(.black).foregroundStyle(.secondary)
                                
                                HStack(spacing: 25) {
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        if newHabitTarget > 7 { newHabitTarget -= 1 }
                                    } label: {
                                        Image(systemName: "minus")
                                            .frame(width: 55, height: 55)
                                            .background(.thinMaterial) // Buton içi cam
                                            .clipShape(Circle())
                                    }
                                    .foregroundStyle(.primary)
                                    
                                    VStack(spacing: 0) {
                                        Text("\(newHabitTarget)")
                                            .font(.system(size: 56, weight: .black, design: .rounded))
                                            .contentTransition(.numericText())
                                        Text("GÜN")
                                            .font(.caption).fontWeight(.bold).foregroundStyle(.secondary)
                                    }
                                    .frame(width: 110)
                                    
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        if newHabitTarget < 365 { newHabitTarget += 1 }
                                    } label: {
                                        Image(systemName: "plus")
                                            .frame(width: 55, height: 55)
                                            .background(Color.primary) // Dolu Siyah
                                            .foregroundStyle(Color(uiColor: .systemBackground))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity)
                            .background(.thinMaterial) // KUTU ARKASI CAM
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            
                            // 3. BİLDİRİM KUTUSU (Liquid Animation)
                            VStack(spacing: 0) {
                                // A. Ana Toggle Satırı
                                Toggle(isOn: $hasNotification) {
                                    HStack {
                                        Image(systemName: "bell.badge.fill")
                                            .foregroundStyle(hasNotification ? .white : .primary)
                                            .padding(10)
                                            // Aktifse Siyah, Pasifse Cam
                                            .background(hasNotification ? Color.primary : Color.gray.opacity(0.1))
                                            .clipShape(Circle())
                                            // İkon değişimi için animasyon
                                            .animation(.snappy, value: hasNotification)
                                        
                                        VStack(alignment: .leading) {
                                            Text("Hatırlatıcı")
                                                .font(.headline)
                                            Text("Belirli bir saatte bildirim al")
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding()
                                
                                // B. Genişleyen Alan (Liquid Effect)
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
                                    // AKIŞKAN GEÇİŞ EFEKTİ (Liquid Transition)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                }
                            }
                            .background(.thinMaterial) // KUTU ARKASI CAM
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            // ESNEME ANİMASYONU: Kutu büyürken yaylanarak büyür
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: hasNotification)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: enableRandomNotification)
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
                            Button("Vazgeç") { showAddSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Başla") {
                                if !newHabitName.isEmpty {
                                    viewModel?.addHabit(
                                        name: newHabitName,
                                        colorHex: "000000",
                                        target: newHabitTarget,
                                        notificationTime: hasNotification ? selectedTime : nil,
                                        random: hasNotification ? enableRandomNotification : false
                                    )
                                    // Sıfırla
                                    newHabitName = ""
                                    newHabitTarget = 30
                                    hasNotification = false
                                    enableRandomNotification = false
                                    showAddSheet = false
                                }
                            }
                            .fontWeight(.bold)
                            .disabled(newHabitName.isEmpty)
                        }
                    }
                }
                .presentationDetents([.fraction(0.85)])
                .presentationCornerRadius(40)
                // ANA CAM KATMANI (Buzlu Cam)
                .presentationBackground(.ultraThinMaterial)
            }
        }
        .onAppear {
            viewModel = HabitListViewModel(modelContext: modelContext)
            
            // GÜNCELLEME 1: Uygulama ilk açıldığında bildirimleri kontrol et
            if let habits = try? modelContext.fetch(FetchDescriptor<Habit>()) {
                viewModel?.refreshNotifications(for: habits)
            }
            // TEST: Bekleyenleri konsola yaz
            NotificationManager.shared.checkPendingNotifications()
        }
        // GÜNCELLEME 2: Arka plandan öne gelince bildirimleri tekrar kontrol et
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                if let habits = try? modelContext.fetch(FetchDescriptor<Habit>()) {
                    viewModel?.refreshNotifications(for: habits)
                }
                NotificationManager.shared.checkPendingNotifications()
            }
        }
    }
    
    var navTitle: String {
        switch selectedTab {
        case .home: return "Hybit"
        case .feed: return "Akış"
        case .friends: return "Arkadaşlar"
        }
    }
}
