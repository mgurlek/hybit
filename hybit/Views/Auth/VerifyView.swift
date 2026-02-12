//
//  VerifyView.swift
//  hybit
//
//  Created by Mert Gurlek on 12.02.2026.
//

import SwiftUI

struct VerifyView: View {
    var authManager: AuthManager
    
    @State private var code = ""
    @FocusState private var isCodeFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 120)
                
                // MARK: - Başlık
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.primary)
                    
                    Text("Doğrulama Kodu")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("SMS ile gönderilen 6 haneli kodu gir")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 40)
                
                // MARK: - Kod Girişi
                VStack(alignment: .leading, spacing: 12) {
                    Text("DOĞRULAMA KODU")
                        .font(.caption2).fontWeight(.black)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                    
                    TextField("000000", text: $code)
                        .font(.system(size: 32, weight: .bold))
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .focused($isCodeFocused)
                        .padding(.vertical, 16)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .onChange(of: code) { _, newValue in
                            if newValue.count > 6 {
                                code = String(newValue.prefix(6))
                            }
                        }
                }
                .padding(.horizontal)
                
                // MARK: - Hata Mesajı
                if let error = authManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.top, 12)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                
                // MARK: - Doğrula Butonu
                Button {
                    Task {
                        await authManager.verifyCode(code: code)
                    }
                } label: {
                    HStack(spacing: 8) {
                        if authManager.isLoading {
                            ProgressView()
                                .tint(Color(uiColor: .systemBackground))
                        }
                        Text("Doğrula")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(code.count == 6 ? Color.primary : Color.primary.opacity(0.3))
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(code.count != 6 || authManager.isLoading)
                .padding(.horizontal)
                .padding(.top, 24)
                
                // MARK: - Geri Dön
                Button {
                    authManager.authState = .signedOut
                    authManager.errorMessage = nil
                } label: {
                    Text("Numarayı Değiştir")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 16)
                
                Spacer().frame(height: 100)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear { isCodeFocused = true }
    }
}
