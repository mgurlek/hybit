//
//  LoginView.swift
//  hybit
//
//  Created by Mert Gurlek on 12.02.2026.
//

import SwiftUI
import Combine

struct LoginView: View {
    var authManager: AuthManager
    
    @State private var phoneNumber = ""
    @FocusState private var isPhoneFocused: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 40) {
                    Spacer().frame(height: 60)
                    
                    // MARK: - Header
                    VStack(spacing: 16) {
                        Image(systemName: "circle.grid.cross.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.tint) // Use app tint
                            .symbolEffect(.bounce, value: isPhoneFocused)
                            .shadow(color: .primary.opacity(0.1), radius: 20)
                        
                        Text("Hybit")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        Text("Hedeflerine ulaşmak için giriş yap")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    // MARK: - Input Container
                    VStack(alignment: .leading, spacing: 16) {
                        Text("TELEFON NUMARASI")
                            .font(.caption2).fontWeight(.black)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                        
                        HStack(spacing: 12) {
                            Text("🇹🇷 +90")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .frame(width: 90)
                                .padding(.vertical, 16)
                                .background(Color(uiColor: .tertiarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            
                            TextField("5XX 333 22 11", text: $phoneNumber)
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .tint(.blue) // Standard iOS Blue or App Tint
                                .keyboardType(.numberPad)
                                .textContentType(.telephoneNumber)
                                .focused($isPhoneFocused)
                                .onChange(of: phoneNumber) { _, newValue in
                                    // Apply Strict Formatter
                                    let formatted = PhoneFormatter.format(newValue)
                                    if formatted != newValue {
                                        phoneNumber = formatted
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(Color(uiColor: .tertiarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    .liquidGlass() // Adaptive Apple Card
                    .padding(.horizontal, 16)
                    
                    // MARK: - Error Message
                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .monochromeBackground() // System Grouped Background
            .safeAreaInset(edge: .bottom) {
                Button {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    Task {
                        let formatted = PhoneFormatter.unformat(phoneNumber)
                        await authManager.sendSMS(phoneNumber: formatted)
                    }
                } label: {
                    HStack(spacing: 12) {
                        if authManager.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(authManager.isLoading ? "GÖNDERİLİYOR..." : "DEVAM ET")
                            .font(.headline).fontWeight(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16) // Slightly smaller for standard iOS button feel
                    .background(isValidPhone ? Color.blue : Color.secondary.opacity(0.3)) // System Blue
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // Standard corner radius
                    .shadow(color: isValidPhone ? Color.blue.opacity(0.3) : .clear, radius: 10, x: 0, y: 5)
                }
                .disabled(!isValidPhone || authManager.isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 10)
                .background(.regularMaterial) // Adaptive Glass for sticky button
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear {
                isPhoneFocused = true
            }
        }
    }
    
    // MARK: - Validation
    private var isValidPhone: Bool {
        let digits = phoneNumber.filter { $0.isNumber }
        return digits.count == 10
    }
}
