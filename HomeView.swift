import SwiftUI

struct HomeView: View {
    @State private var isRunning = false
    @State private var startTime = Date()
    @State private var remainingTime: TimeInterval = 0
    @AppStorage("startHour") var startHour = 10
    @AppStorage("endHour") var endHour = 2 // 翌日の2時
    let duration: TimeInterval = 16 * 60 * 60 // 16時間

    @State private var selectedDate = Date()
    @State private var records: [DietRecord] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    Text("16時間ダイエット")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    VStack(spacing: 10) {
                        Text("開始時間: \(String(format: "%02d:00", startHour))")
                        Text("終了時間: \(String(format: "%02d:00", endHour))")
                    }

                    if isRunning {
                        Text(formatTime(remainingTime))
                            .font(.system(size: 36, weight: .semibold, design: .monospaced))
                            .foregroundColor(.blue)
                    }

                    HStack(spacing: 40) {
                        Button(action: startDiet) {
                            Label("開始", systemImage: "play.circle.fill")
                                .font(.title2)
                        }.disabled(isRunning)

                        Button(action: stopDiet) {
                            Label("停止", systemImage: "stop.circle.fill")
                                .font(.title2)
                        }.disabled(!isRunning)
                    }

                    Divider()

                    // 📅 カレンダー表示
                    VStack(alignment: .leading, spacing: 10) {
                        Text("履歴")
                            .font(.headline)

                        DatePicker("日付選択", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)

                        if let matched = records.first(where: {
                            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
                        }) {
                            Text(matched.success ? "✅ 成功！" : "❌ 失敗")
                                .font(.subheadline)
                                .foregroundColor(matched.success ? .green : .red)
                        } else {
                            Text("記録なし")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("ホーム")
            .onAppear {
                records = UserDefaultsManager.shared.loadRecords()
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                guard isRunning else { return }
                let elapsed = Date().timeIntervalSince(startTime)
                remainingTime = max(duration - elapsed, 0)
                if remainingTime <= 0 {
                    stopDiet()
                }
            }
        }
    }

    func startDiet() {
        startTime = Date()
        remainingTime = duration
        isRunning = true
    }

    func stopDiet() {
        isRunning = false
        let success = remainingTime <= 0
        let record = DietRecord(date: Date(), success: success, start: startHour, end: endHour)
        UserDefaultsManager.shared.addRecord(record)
        records = UserDefaultsManager.shared.loadRecords()
    }

    func formatTime(_ interval: TimeInterval) -> String {
        let hrs = Int(interval) / 3600
        let mins = (Int(interval) % 3600) / 60
        let secs = Int(interval) % 60
        return String(format: "%02d時間 %02d分 %02d秒", hrs, mins, secs)
    }
}
