//
//  AuthManager.swift
//  hybit
//
//  Created by Mert Gurlek on 12.02.2026.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit

// MARK: - Auth State

enum AuthState: Equatable {
    case loading
    case signedOut
    case verifying(String) // verificationID
    case profileNeeded
    case signedIn
    
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading): return true
        case (.signedOut, .signedOut): return true
        case (.verifying(let a), .verifying(let b)): return a == b
        case (.profileNeeded, .profileNeeded): return true
        case (.signedIn, .signedIn): return true
        default: return false
        }
    }
}

// MARK: - AuthManager

@Observable
final class AuthManager {
    static let shared = AuthManager()
    
    var authState: AuthState = .loading
    var errorMessage: String?
    var isLoading = false
    var currentProfile: UserProfile?
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var authListener: AuthStateDidChangeListenerHandle?
    private var isPerformingAction = false
    
    private init() {
        listenToAuthState()
    }
    
    deinit {
        if let listener = authListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Token Yenileme
    
    /// Firestore çağrılarından önce ID token'ın geçerli olduğundan emin ol
    private func ensureValidToken() async {
        guard let user = Auth.auth().currentUser else { return }
        do {
            _ = try await user.getIDTokenResult(forcingRefresh: true)
            print("✅ [AuthManager] Token refreshed successfully")
        } catch {
            print("⚠️ [AuthManager] Token refresh failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Auth State Listener
    
    private func listenToAuthState() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            
            Task { @MainActor in
                guard !self.isPerformingAction else { return }
                
                if let user {
                    // Token'ın Firestore tarafından tanınması için yenile
                    await self.ensureValidToken()
                    guard !self.isPerformingAction else { return }
                    await self.checkUserProfile(uid: user.uid)
                } else {
                    if case .verifying = self.authState { return }
                    self.authState = .signedOut
                    self.currentProfile = nil
                }
            }
        }
    }
    
    // MARK: - SMS Gönder
    
    @MainActor
    func sendSMS(phoneNumber: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(
                phoneNumber,
                uiDelegate: nil
            )
            authState = .verifying(verificationID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Kodu Doğrula
    
    @MainActor
    func verifyCode(code: String) async {
        guard case .verifying(let verificationID) = authState else { return }
        
        isLoading = true
        errorMessage = nil
        isPerformingAction = true
        defer {
            isLoading = false
            isPerformingAction = false
        }
        
        do {
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: verificationID,
                verificationCode: code
            )
            let result = try await Auth.auth().signIn(with: credential)
            
            // Oturum açıldıktan sonra token'ı yenile
            await ensureValidToken()
            await checkUserProfile(uid: result.user.uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Profil Kontrol
    
    @MainActor
    func checkUserProfile(uid: String) async {
        guard Auth.auth().currentUser != nil else {
            print("⚠️ [AuthManager] checkUserProfile: currentUser nil")
            authState = .signedOut
            return
        }
        
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            
            if doc.exists, let data = doc.data() {
                currentProfile = UserProfile(
                    uid: data["uid"] as? String ?? uid,
                    firstName: data["firstName"] as? String ?? "",
                    lastName: data["lastName"] as? String ?? "",
                    username: data["username"] as? String ?? "",
                    phoneNumber: data["phoneNumber"] as? String ?? "",
                    age: data["age"] as? Int,
                    nationality: data["nationality"] as? String,
                    profileImageURL: data["profileImageURL"] as? String,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                )
                authState = .signedIn
            } else {
                authState = .profileNeeded
            }
        } catch {
            print("⚠️ [AuthManager] checkUserProfile error: \(error.localizedDescription)")
            authState = .profileNeeded
        }
    }
    
    // MARK: - Profil Fotoğrafı Yükle
    
    @MainActor
    func uploadProfileImage(_ image: UIImage, uid: String) async -> String? {
        guard let data = image.jpegData(compressionQuality: 0.5) else { return nil }
        
        let path = "profile_images/\(uid).jpg"
        let ref = storage.reference().child(path)
        
        do {
            _ = try await ref.putDataAsync(data)
            let url = try await ref.downloadURL()
            return url.absoluteString
        } catch {
            print("❌ [AuthManager] Image upload failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Profil Oluştur
    
    @MainActor
    func createProfile(
        firstName: String,
        lastName: String,
        username: String,
        age: Int?,
        nationality: String?,
        profileImage: UIImage?
    ) async -> Bool {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "Oturum bulunamadı. Lütfen tekrar giriş yapın."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        isPerformingAction = true
        defer {
            isLoading = false
            isPerformingAction = false
        }
        
        // Token'ı yazma öncesi yenile
        await ensureValidToken()
        
        let lowercasedUsername = username.lowercased()
        
        // Kullanıcı adı benzersizlik kontrolü
        do {
            let usernameDoc = try await db.collection("usernames").document(lowercasedUsername).getDocument()
            if usernameDoc.exists {
                errorMessage = "Bu kullanıcı adı zaten alınmış."
                return false
            }
        } catch {
            print("⚠️ [AuthManager] username check error: \(error.localizedDescription)")
            // İzin hatası olursa devam et — batch write sırasında kontrol edilir
        }
        
        // Fotoğraf Yükleme (Varsa)
        var imageURL: String?
        if let profileImage {
            imageURL = await uploadProfileImage(profileImage, uid: user.uid)
        }
        
        // Profili kaydet
        let profile = UserProfile(
            uid: user.uid,
            firstName: firstName,
            lastName: lastName,
            username: lowercasedUsername,
            phoneNumber: user.phoneNumber ?? "",
            age: age,
            nationality: nationality,
            profileImageURL: imageURL,
            createdAt: Date()
        )
        
        do {
            // Batch write: hem profili hem username rezervasyonunu aynı anda yaz
            let batch = db.batch()
            
            let userRef = db.collection("users").document(user.uid)
            batch.setData(profile.dictionary, forDocument: userRef)
            
            let usernameRef = db.collection("usernames").document(lowercasedUsername)
            batch.setData(["uid": user.uid], forDocument: usernameRef)
            
            try await batch.commit()
            
            print("✅ [AuthManager] Profile created successfully for \(user.uid)")
            currentProfile = profile
            authState = .signedIn
            return true
        } catch {
            print("❌ [AuthManager] createProfile error: \(error.localizedDescription)")
            errorMessage = "Profil kaydedilemedi: \(error.localizedDescription)"
            authState = .profileNeeded
            return false
        }
    }
    
    // MARK: - Kullanıcı Adı Kontrolü
    
    @MainActor
    func checkUsernameAvailability(_ username: String) async -> Bool {
        guard username.count >= 3 else { return false }
        guard Auth.auth().currentUser != nil else { return true }
        
        do {
            let doc = try await db.collection("usernames").document(username.lowercased()).getDocument()
            return !doc.exists
        } catch {
            print("⚠️ [AuthManager] checkUsername error: \(error.localizedDescription)")
            // İzin hatası — formu engelleme, müsait kabul et
            return true
        }
    }
    
    // MARK: - Çıkış Yap
    
    @MainActor
    func signOut() {
        do {
            try Auth.auth().signOut()
            authState = .signedOut
            currentProfile = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Profili Sil (Test İçin)
    
    @MainActor
    func deleteProfile() async {
        guard let user = Auth.auth().currentUser, let profile = currentProfile else {
            signOut()
            return
        }
        
        isPerformingAction = true
        defer { isPerformingAction = false }
        
        do {
            let batch = db.batch()
            
            // 1. Users koleksiyonundan sil
            let userRef = db.collection("users").document(user.uid)
            batch.deleteDocument(userRef)
            
            // 2. Usernames koleksiyonundan sil
            let usernameRef = db.collection("usernames").document(profile.username)
            batch.deleteDocument(usernameRef)
            
            try await batch.commit()
            print("✅ [AuthManager] Profile deleted successfully")
            
            // 3. Oturumu kapat
            signOut()
            
        } catch {
            print("❌ [AuthManager] Delete profile error: \(error.localizedDescription)")
            signOut() // Hata olsa bile çıkış yap
        }
    }
}
