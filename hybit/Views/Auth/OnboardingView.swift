//
//  OnboardingView.swift
//  hybit
//
//  Created by Mert Gurlek on 12.02.2026.
//

import SwiftUI
import PhotosUI

enum OnboardingStep: Int, CaseIterable {
    case name = 0
    case username
    case details // Age & Nationality
    case photo
}

struct OnboardingView: View {
    var authManager: AuthManager
    
    @State private var currentStep: OnboardingStep = .name
    
    // Step 1: Name
    @State private var firstName = ""
    @State private var lastName = ""
    @FocusState private var isNameFocused: Bool
    
    // Step 2: Username
    @State private var username = ""
    @State private var isUsernameAvailable: Bool?
    @State private var isCheckingUsername = false
    @State private var usernameCheckTask: Task<Void, Never>?
    @FocusState private var isUsernameFocused: Bool
    
    // Step 3: Details
    @State private var age = ""
    @State private var nationality = "TR"
    @FocusState private var isAgeFocused: Bool
    let nationalities = ["TR", "US", "GB", "DE", "FR", "IT", "ES", "NL", "RU", "JP", "KR", "CN"]
    
    // Step 4: Photo
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    @State private var showErrorAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Header & Progress
                VStack(spacing: 20) {
                    HStack {
                        Button("Çıkış (Test)") {
                            authManager.signOut()
                        }
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(8)
                        .background(.regularMaterial)
                        .clipShape(Capsule())
                        
                        Spacer()
                        
                        Text("ADIM \(currentStep.rawValue + 1)/4")
                            .font(.caption).fontWeight(.black)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    // Adaptive Progress Bar
                    HStack(spacing: 6) {
                        ForEach(OnboardingStep.allCases, id: \.self) { step in
                            Capsule()
                                .fill(step.rawValue <= currentStep.rawValue ? Color.primary : Color.secondary.opacity(0.2))
                                .frame(height: 4)
                                .animation(.spring, value: currentStep)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 20)
                
                // MARK: - Step Content
                TabView(selection: $currentStep) {
                    nameView.tag(OnboardingStep.name)
                    usernameView.tag(OnboardingStep.username)
                    detailsView.tag(OnboardingStep.details)
                    photoView.tag(OnboardingStep.photo)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: currentStep)
                
                Spacer()
            }
            .monochromeBackground() // Adaptive System Grouped Background
            .safeAreaInset(edge: .bottom) {
                HStack {
                    if currentStep != .name {
                        Button {
                            withAnimation {
                                if let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) {
                                    currentStep = prev
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.primary)
                                .frame(width: 50, height: 50)
                                .background(Color(uiColor: .tertiarySystemFill))
                                .clipShape(Circle())
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        if currentStep == .photo {
                            completeOnboarding()
                        } else {
                            withAnimation {
                                if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
                                    currentStep = next
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if authManager.isLoading && currentStep == .photo {
                                ProgressView().tint(.white)
                            }
                            Text(currentStep == .photo ? "TAMAMLA" : "İLERİ")
                                .fontWeight(.bold)
                            
                            if !authManager.isLoading {
                                Image(systemName: "arrow.right")
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(canProceed ? Color.blue : Color.secondary.opacity(0.3)) // System Blue
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .shadow(color: canProceed ? Color.blue.opacity(0.3) : .clear, radius: 15, x: 0, y: 5)
                    }
                    .disabled(!canProceed || authManager.isLoading)
                }
                .padding(24)
                .background(.regularMaterial) // Adaptive Glass for buttons
            }
            .alert("Hata", isPresented: $showErrorAlert) {
                Button("Tamam", role: .cancel) { authManager.errorMessage = nil }
            } message: {
                Text(authManager.errorMessage ?? "Bilinmeyen bir hata oluştu.")
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
    
    // MARK: - Step Views
    
    var nameView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Adın ne?")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                VStack(spacing: 20) {
                    TextField("Adın", text: $firstName)
                        .font(.system(size: 20, weight: .medium))
                        .padding()
                        .background(Color(uiColor: .tertiarySystemFill))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .focused($isNameFocused)
                        .textContentType(.givenName)
                        .submitLabel(.next)
                    
                    TextField("Soyadın", text: $lastName)
                        .font(.system(size: 20, weight: .medium))
                        .padding()
                        .background(Color(uiColor: .tertiarySystemFill))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .textContentType(.familyName)
                        .submitLabel(.done)
                }
            }
            .liquidGlass()
            .padding(.horizontal)
            .padding(.top, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear { isNameFocused = true }
    }
    
    var usernameView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Kullanıcı Adı")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("@")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        
                        TextField("kullanici_adi", text: $username)
                            .font(.system(size: 20, weight: .medium))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .foregroundStyle(.primary)
                            .focused($isUsernameFocused)
                            .onChange(of: username) { _, newValue in checkUsername(newValue) }
                    }
                    .padding()
                    .background(Color(uiColor: .tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    if !username.isEmpty {
                        if isCheckingUsername {
                            HStack {
                                ProgressView().scaleEffect(0.8)
                                Text("Kontrol ediliyor...").font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(.leading, 8)
                        } else if let available = isUsernameAvailable {
                            Text(available ? "Bu isim müsait ✓" : "Bu isim alınmış")
                                .font(.caption)
                                .foregroundStyle(available ? .green : .red)
                                .padding(.leading, 8)
                                .transition(.opacity)
                        }
                    }
                }
            }
            .liquidGlass()
            .padding(.horizontal)
            .padding(.top, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear { isUsernameFocused = true }
    }
    
    var detailsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Detaylar")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YAŞIN").font(.caption).bold().foregroundStyle(.secondary)
                        TextField("25", text: $age)
                            .font(.system(size: 20, weight: .medium))
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color(uiColor: .tertiarySystemFill))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .focused($isAgeFocused)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ÜLKE").font(.caption).bold().foregroundStyle(.secondary)
                        Menu {
                            ForEach(nationalities, id: \.self) { country in
                                Button(country) { nationality = country }
                            }
                        } label: {
                            HStack {
                                Text(nationality)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(uiColor: .tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }
            .liquidGlass()
            .padding(.horizontal)
            .padding(.top, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear { isAgeFocused = true }
    }
    
    var photoView: some View {
        ScrollView {
            VStack(spacing: 32) {
                Text("Profil Fotoğrafı")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 24) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        ZStack {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 160, height: 160)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
                                    .shadow(radius: 20)
                            } else {
                                Circle()
                                    .fill(Color(uiColor: .tertiarySystemFill))
                                    .frame(width: 160, height: 160)
                                    .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.secondary)
                            }
                            
                            // Edit Badge
                            if selectedImage != nil {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.blue)
                                    .background(Circle().fill(Color(uiColor: .systemBackground)))
                                    .offset(x: 50, y: 50)
                            }
                        }
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                withAnimation {
                                    selectedImage = image
                                }
                            }
                        }
                    }
                    
                    if selectedImage == nil {
                        Button("Şimdilik Atla") {
                            completeOnboarding()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                    }
                }
            }
            .liquidGlass()
            .padding(.horizontal)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Logic
    
    var canProceed: Bool {
        switch currentStep {
        case .name:
            return !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !lastName.trimmingCharacters(in: .whitespaces).isEmpty
        case .username:
            return username.count >= 3 && isUsernameAvailable == true
        case .details:
            return !age.isEmpty && Int(age) != nil
        case .photo:
            return true
        }
    }
    
    private func checkUsername(_ value: String) {
        usernameCheckTask?.cancel()
        isUsernameAvailable = nil
        isCheckingUsername = false
        
        guard value.count >= 3 else { return }
        isCheckingUsername = true
        
        usernameCheckTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            let available = await authManager.checkUsernameAvailability(value)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation {
                    isUsernameAvailable = available
                    isCheckingUsername = false
                }
            }
        }
    }
    
    private func completeOnboarding() {
        Task {
            let success = await authManager.createProfile(
                firstName: firstName,
                lastName: lastName,
                username: username,
                age: Int(age),
                nationality: nationality,
                profileImage: selectedImage
            )
            
            if !success && authManager.errorMessage != nil {
                showErrorAlert = true
            }
        }
    }
}

