//
//  hybitApp.swift
//  hybit
//
//  Created by Mert Gurlek on 7.02.2026.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth

// MARK: - Firebase AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    // APNs token'ı Firebase Auth'a ilet
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
    }
    
    // Sessiz push bildirimi — Firebase Phone Auth doğrulaması için
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        completionHandler(.noData)
    }
    
    // reCAPTCHA URL callback — Firebase Phone Auth için
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        if Auth.auth().canHandle(url) {
            return true
        }
        return false
    }
}

// MARK: - App

@main
struct hybitApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    let container: ModelContainer

    init() {
        self.container = DataManager.shared.modelContainer
        
        // Bildirim İzni İste
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
