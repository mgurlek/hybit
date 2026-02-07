//
//  hybitApp.swift
//  hybit
//
//  Created by Mert Gurlek on 7.02.2026.
//

import SwiftUI
import SwiftData

@main
struct hybitApp: App {
    let container: ModelContainer

    init() {
        // HATA ÇÖZÜMÜ: do-catch bloğunu kaldırdık.
        // DataManager zaten başlatılırken hatayı kendi içinde hallediyor.
        // Biz sadece hazır olan container'ı alıyoruz.
        self.container = DataManager.shared.modelContainer
        
        // Bildirim İzni İste
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Uygulamaya "Ortak Kasayı" veriyoruz
        .modelContainer(container)
    }
}
