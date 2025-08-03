//
//  SettingsView.swift
//  SixteenhourDiet
//
//  Created by 近山翔太 on 2025/07/27.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("startHour") var startHour = 10
    @AppStorage("endHour") var endHour = 22

    var body: some View {
        NavigationView {
            Form {
                Stepper("開始時間: \(startHour):00", value: $startHour, in: 0...23)
                Stepper("終了時間: \(endHour):00", value: $endHour, in: 0...23)

                Button("履歴をリセット") {
                    UserDefaultsManager.shared.clearRecords()
                }
                .foregroundColor(.red)
            }
            .navigationTitle("設定")
        }
    }
}
