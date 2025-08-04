//
//  SixteenhourDietApp.swift
//  SixteenhourDiet
//
//  Created by 近山翔太 on 2025/07/28.
//

import SwiftUI
import StoreKit

@main
struct SixteenhourDietApp: App {
    @StateObject private var adManager = AdManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // StoreKit 2の初期化
                    Task {
                        try? await AppStore.sync()
                    }
                }
        }
    }
}
