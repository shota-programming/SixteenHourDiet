//
//  HomeView.swift
//  SixteenhourDiet
//
//  Created by 近山翔太 on 2025/07/27.
//

import SwiftUI

struct HomeView: View {
    @State private var isRunning = false
    @State private var startTime = Date()
    @State private var remainingTime: TimeInterval = 0
    @AppStorage("startHour") var startHour = 10
    @AppStorage("endHour") var endHour = 22

    let duration: TimeInterval = 16 * 60 * 60

    var body: some View {
        VStack(spacing: 20) {
            Text("16時間ダイエット")
                .font(.title)

            Text("開始時間: \(String(format: "%02d:00", startHour))")
            Text("終了時間: \(String(format: "%02d:00", endHour))")

            if isRunning {
                Text("残り時間: \(formatTime(remainingTime))")
                    .font(.headline)
            }

            HStack {
                Button("🔵 開始") {
                    startTime = Date()
                    remainingTime = duration
                    isRunning = true
                }
                .disabled(isRunning)

                Button("⏹️ 停止") {
                    stopDiet()
                }
                .disabled(!isRunning)
            }

            Spacer()
        }
        .padding()
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if isRunning {
                let elapsed = Date().timeIntervalSince(startTime)
                remainingTime = max(duration - elapsed, 0)
                if remainingTime <= 0 {
                    stopDiet()
                }
            }
        }
    }

    func stopDiet() {
        isRunning = false
        let success = remainingTime <= 0
        let record = DietRecord(date: Date(), success: success, start: startHour, end: endHour)
        UserDefaultsManager.shared.addRecord(record)
    }

    func formatTime(_ interval: TimeInterval) -> String {
        let hrs = Int(interval) / 3600
        let mins = (Int(interval) % 3600) / 60
        return String(format: "%02d時間 %02d分", hrs, mins)
    }
}
