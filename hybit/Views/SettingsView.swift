//
//  SettingsView.swift
//  hybit
//
//  Created by Mert Gurlek on 12.02.2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // UI-only toggles (gelecekte UserDefaults/CloudKit ile senkronize edilecek)
    @AppStorage("notifications_enabled") private var notificationsEnabled = true
    @AppStorage("icloud_sync_enabled") private var iCloudSyncEnabled = true
    
    @State private var showResetAlert = false
    
    // Uygulama bilgileri
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        Form {
            
            // MARK: - Genel
            Section {
                // Bildirimler
                Toggle(isOn: $notificationsEnabled) {
                    Label {
                        Text("Bildirimler")
                    } icon: {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(.orange)
                    }
                }
                .tint(.primary)
            } header: {
                Text("Genel")
            }
            
            // MARK: - Veri & Gizlilik
            Section {
                // iCloud Sync
                Toggle(isOn: $iCloudSyncEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("iCloud Sync")
                            Text("Verilerini tüm cihazlarda eşitle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "icloud.fill")
                            .foregroundStyle(.blue)
                    }
                }
                .tint(.primary)
            } header: {
                Text("Veri & Gizlilik")
            }
            
            // MARK: - Destek
            Section {
                // Uygulamayı Değerlendir
                Link(destination: URL(string: "https://apps.apple.com/app/hybit/id000000000")!) {
                    Label {
                        HStack {
                            Text("Uygulamayı Değerlendir")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    } icon: {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                    }
                }
                
                // Geliştiriciyle İletişim
                Link(destination: URL(string: "mailto:contact@gurtech.co")!) {
                    Label {
                        HStack {
                            Text("Geliştiriciyle İletişim")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    } icon: {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(.green)
                    }
                }
                
                // Gizlilik Politikası
                Link(destination: URL(string: "https://gurtech.co/privacy")!) {
                    Label {
                        HStack {
                            Text("Gizlilik Politikası")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    } icon: {
                        Image(systemName: "hand.raised.fill")
                            .foregroundStyle(.purple)
                    }
                }
            } header: {
                Text("Destek")
            }
            
            // MARK: - Geliştirici (Test)
            Section {
                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    Label {
                        Text("Profili Sıfırla (Onboarding Testi)")
                    } icon: {
                        Image(systemName: "trash.fill")
                            .foregroundStyle(.red)
                    }
                }
            } header: {
                Text("Geliştirici Seçenekleri")
            }
            
            // MARK: - Uygulama Bilgileri
            Section {
                HStack {
                    Text("Versiyon")
                    Spacer()
                    Text("\(appVersion) (\(buildNumber))")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            } header: {
                Text("Uygulama Bilgileri")
            } footer: {
                VStack(spacing: 4) {
                    Text("Hybit")
                        .font(.system(size: 14, weight: .bold))
                    Text("gurtech.co")
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
            }
        }
        .alert("Profili Sıfırla", isPresented: $showResetAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil ve Çıkış Yap", role: .destructive) {
                Task {
                    await AuthManager.shared.deleteProfile()
                }
            }
        } message: {
            Text("Bu işlem mevcut profili Firestore'dan silecek ve çıkış yapacaktır. Onboarding ekranına geri döneceksiniz.")
        }
    }
}
