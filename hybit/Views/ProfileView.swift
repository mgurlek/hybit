//
//  ProfileView.swift
//  hybit
//
//  Created by Mert Gurlek on 12.02.2026.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query(sort: \Habit.creationDate, order: .reverse) var habits: [Habit]
    
    // MARK: - Hesaplanan İstatistikler
    
    private var totalHabits: Int { habits.count }
    
    private var totalCompletions: Int {
        habits.reduce(0) { $0 + ($1.completions?.count ?? 0) }
    }
    
    private var longestStreak: Int {
        habits.map { $0.currentStreak }.max() ?? 0
    }
    
    private var activeDays: Int {
        let allDates = habits.flatMap { $0.completions ?? [] }.map {
            Calendar.current.startOfDay(for: $0.date)
        }
        return Set(allDates).count
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                
                // MARK: - Profil Başlığı
                profileHeader
                
                // MARK: - İstatistikler
                statsSection
                
                // MARK: - Hedefler Özeti
                if !habits.isEmpty {
                    habitsOverview
                }
                
                // MARK: - Çıkış Yap
                signOutSection
                
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 60)
        }
        .scrollIndicators(.hidden)
    }
    
    // MARK: - Profil Başlığı
    
    private var profileHeader: some View {
        VStack(spacing: 20) {
            // Avatar
            ZStack {
                if let urlString = AuthManager.shared.currentProfile?.profileImageURL,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        case .failure:
                            placeholderAvatar
                        @unknown default:
                            placeholderAvatar
                        }
                    }
                } else {
                    placeholderAvatar
                }
            }
            
            // İsim
            VStack(spacing: 6) {
                if let profile = AuthManager.shared.currentProfile {
                    Text(profile.fullName)
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundStyle(.primary)
                    
                    Text("@\(profile.username)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    Text("Hybit Kullanıcısı")
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundStyle(.primary)
                    
                    Text("Giriş yapılmadı")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
    
    private var placeholderAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.primary.opacity(0.05))
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
            
            Image(systemName: "person.fill")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.primary.opacity(0.3))
        }
    }
    
    // MARK: - İstatistikler
    
    private var statsSection: some View {
        VStack(spacing: 0) {
            // Üst satır: Ana metrik (büyük)
            HStack(spacing: 0) {
                statItem(value: "\(longestStreak)", label: "EN UZUN SERİ")
                
                // Dikey ayırıcı
                Rectangle()
                    .fill(Color.primary.opacity(0.06))
                    .frame(width: 1)
                    .padding(.vertical, 20)
                
                statItem(value: "\(totalCompletions)", label: "TAMAMLAMA")
            }
            
            // Yatay ayırıcı
            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            // Alt satır
            HStack(spacing: 0) {
                statItem(value: "\(totalHabits)", label: "HEDEF")
                
                Rectangle()
                    .fill(Color.primary.opacity(0.06))
                    .frame(width: 1)
                    .padding(.vertical, 20)
                
                statItem(value: "\(activeDays)", label: "AKTİF GÜN")
            }
        }
        .adaptiveThinMaterial(cornerRadius: 28)
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .default))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
            
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.tertiary)
                .tracking(1.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
    }
    
    // MARK: - Hedefler Özeti
    
    private var habitsOverview: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("HEDEFLERİN")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.tertiary)
                .tracking(2)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                ForEach(Array(habits.enumerated()), id: \.element.id) { index, habit in
                    HStack(spacing: 14) {
                        // İkon
                        Image(systemName: habit.iconSymbol)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color.primary.opacity(0.05))
                            .clipShape(Circle())
                        
                        // İsim
                        Text(habit.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        // Seri
                        HStack(spacing: 4) {
                            Text("\(habit.currentStreak)")
                                .font(.system(size: 15, weight: .bold, design: .default))
                                .foregroundStyle(.primary)
                            
                            Image(systemName: "flame")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    
                    // Ayırıcı (son eleman hariç)
                    if index < habits.count - 1 {
                        Rectangle()
                            .fill(Color.primary.opacity(0.04))
                            .frame(height: 1)
                            .padding(.leading, 68)
                    }
                }
            }
            .adaptiveThinMaterial(cornerRadius: 22)
        }
    }
    
    // MARK: - Topluluk
    
    // MARK: - Çıkış Yap
    
    private var signOutSection: some View {
        Button(role: .destructive) {
            AuthManager.shared.signOut()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Çıkış Yap")
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.horizontal, 22)
    }
}
