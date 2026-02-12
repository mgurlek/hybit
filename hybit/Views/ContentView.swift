//
//  ContentView.swift
//  hybit
//
//  Created by Mert Gurlek on 7.02.2026.
//
import WidgetKit
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    // YENİ: Uygulamanın durumunu (Aktif/Arka Plan) takip etmek için
    @Environment(\.scenePhase) var scenePhase
    
    @State private var viewModel: HabitListViewModel?
    
    @State private var selectedTab: Tab = .home
    @State private var showAddSheet = false
    
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
                        Button { /* TODO: Bildirim sayfası */ } label: {
                            Image(systemName: "bell")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(Color.primary)
                        }
                    }
                    .padding(.horizontal).padding(.bottom, 10)
                    
                    // İÇERİK
                    TabView(selection: $selectedTab) {
                        
                        ContentUnavailableView("Arkadaşlar", systemImage: "person.2", description: Text("Yakında."))
                            .tag(Tab.friends)
                        
                        ContentUnavailableView("Akış", systemImage: "safari", description: Text("Yakında."))
                            .tag(Tab.feed)
                        
                        HomeView(viewModel: viewModel)
                            .tag(Tab.home)
                        
                        ProfileView()
                            .tag(Tab.profile)
                        
                        SettingsView()
                            .tag(Tab.settings)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                
                CustomTabBar(selectedTab: $selectedTab).padding(.bottom, 10)
            }
            .toolbar(.hidden, for: .navigationBar)
            
            // --- LIQUID GLASS SHEET ---
            .sheet(isPresented: $showAddSheet) {
                AddHabitView(viewModel: viewModel)
                    .presentationDetents([.fraction(0.85)])
                    .presentationCornerRadius(40)
                    .adaptivePresentationBackground()
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
        case .friends: return "Arkadaşlar"
        case .feed: return "Akış"
        case .home: return "Hybit"
        case .profile: return "Profil"
        case .settings: return "Ayarlar"
        }
    }
}
