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
    @State private var viewModel: HabitListViewModel?
    
    @State private var selectedTab: Tab = .home
    @State private var showAddSheet = false
    @State private var showProfileSheet = false
    
    // Yeni Veriler
    @State private var newHabitName = ""
    @State private var newHabitTarget = 30 // Varsayılan hedef 30 gün
    
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
                        HomeView(viewModel: viewModel)
                            .tag(Tab.home)
                        ContentUnavailableView("Akış", systemImage: "safari", description: Text("Yakında."))
                            .tag(Tab.feed)
                        ContentUnavailableView("Arkadaşlar", systemImage: "person.2", description: Text("Yakında."))
                            .tag(Tab.friends)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                
                CustomTabBar(selectedTab: $selectedTab).padding(.bottom, 10)
            }
            .toolbar(.hidden, for: .navigationBar)
            
            // YENİ EKLEME EKRANI (Hedef Seçicili)
            .sheet(isPresented: $showAddSheet) {
                NavigationStack {
                    Form {
                        Section("Alışkanlık") {
                            TextField("Örn: Kitap Oku", text: $newHabitName)
                        }
                        
                        Section("Hedef (Gün)") {
                            Stepper(value: $newHabitTarget, in: 7...365, step: 1) {
                                Text("\(newHabitTarget) Günlük Zincir")
                            }
                        }
                    }
                    .navigationTitle("Yeni Hedef")
                    .toolbar {
                        Button("Kaydet") {
                            if !newHabitName.isEmpty {
                                // ViewModel'e hedefi de gönderiyoruz
                                viewModel?.addHabit(name: newHabitName, colorHex: "000000", target: newHabitTarget)
                                newHabitName = ""
                                newHabitTarget = 30 // Sıfırla
                                showAddSheet = false
                            }
                        }
                    }
                }
                .presentationDetents([.height(300)]) // Yüksekliği biraz artırdık
            }
        }
        .onAppear {
            viewModel = HabitListViewModel(modelContext: modelContext)
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
