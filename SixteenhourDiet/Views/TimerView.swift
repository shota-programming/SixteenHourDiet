import SwiftUI

struct TimerView: View {
    @StateObject private var weightViewModel = WeightViewModel()
    @State private var isTimerRunning = false
    @State private var remainingTime: TimeInterval = 16 * 60 * 60 // 16時間を秒で表現
    @State private var startTime: Date?
    @State private var pulseAnimation = false
    @State private var fastingStartTime: Date = Date()
    @State private var fastingEndTime: Date = Calendar.current.date(byAdding: .hour, value: 16, to: Date()) ?? Date()
    @State private var timer: Timer?
    @State private var showingStopAlert = false
    @State private var showingStartAlert = false
    @State private var lastStartTime: Date?
    @State private var lastEndTime: Date?
    @State private var lastActualEndTime: Date?
    
    // 保存された断食時間を取得
    private var fastingDuration: Double {
        let savedDuration = UserDefaultsManager.shared.loadFastingDuration()
        return savedDuration > 0 ? savedDuration : 16.0
    }
    
    // 準備完了時の表示時間を計算
    private var readyTimeString: String {
        let totalSeconds = TimeInterval(fastingDuration * 60 * 60)
        return timeString(from: totalSeconds)
    }
    
    // 前回の時間表示の条件を計算
    private var shouldShowLastTimes: Bool {
        return !isTimerRunning && lastStartTime != nil && lastActualEndTime != nil
    }
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.pink.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // ヘッダー
                    VStack(spacing: 10) {
                        Image(systemName: "timer.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                        
                        Text("\(Int(fastingDuration))時間断食タイマー")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("健康な生活をサポート")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 円グラフ表示
                    CircularProgressView(
                        isTimerRunning: isTimerRunning,
                        remainingTime: remainingTime,
                        readyTimeString: readyTimeString,
                        progressValue: progressValue
                    )
                    
                    // 時間情報
                    TimeInfoView(
                        isTimerRunning: isTimerRunning,
                        currentTimeString: currentTimeString,
                        endTimeString: endTimeString,
                        shouldShowLastTimes: shouldShowLastTimes,
                        lastStartTime: lastStartTime,
                        lastEndTime: lastActualEndTime,
                        fastingStartTime: fastingStartTime
                    )
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                    )
                    
                    // 操作ボタン
                    TimerControlButton(
                        isTimerRunning: isTimerRunning,
                        onStart: checkExistingRecordAndStart,
                        onStop: { showingStopAlert = true }
                    )
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
        }
        .overlay(
            VStack {
                Spacer()
                AdBannerView()
            }
        )
        .onAppear {
            pulseAnimation = true
            updateFastingEndTime()
            loadTimerState()
        }
        .onChange(of: fastingStartTime) { oldValue, newValue in
            updateFastingEndTime()
        }
        .onDisappear {
            // タイマーは停止しない（バックグラウンドで動作）
        }
        .alert("タイマーを停止", isPresented: $showingStopAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("停止", role: .destructive) {
                confirmStopTimer()
            }
        } message: {
            Text("タイマーを停止しますか？\n進行中の断食記録は停止時間まで記録されます。")
        }
        .alert("断食記録が見つかりました", isPresented: $showingStartAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除して開始", role: .destructive) {
                confirmStartWithOverwrite()
            }
        } message: {
            Text("今日の断食記録が見つかりました。\n記録を削除して新しい断食を開始しますか？")
        }
    }
    
    // 進行状況の計算
    private var progressValue: Double {
        if isTimerRunning {
            let totalTime = fastingEndTime.timeIntervalSince(fastingStartTime)
            let elapsedTime = totalTime - remainingTime
            return elapsedTime / totalTime
        } else {
            return 0.0
        }
    }
    
    // 現在時刻の文字列
    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d HH:mm"
        return formatter.string(from: Date())
    }
    
    // 終了時刻の文字列
    private var endTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: fastingEndTime)
    }
    
    private func updateFastingEndTime() {
        fastingEndTime = Calendar.current.date(byAdding: .hour, value: Int(fastingDuration), to: fastingStartTime) ?? fastingStartTime
    }
    
    private func calculateFastingDuration() -> String {
        let duration = fastingEndTime.timeIntervalSince(fastingStartTime) / 3600
        return String(format: "%.1f時間", duration)
    }
    
    private func startTimer() {
        isTimerRunning = true
        startTime = Date()
        fastingStartTime = Date()
        updateFastingEndTime() // 終了予定時間を更新
        remainingTime = fastingEndTime.timeIntervalSince(fastingStartTime)
        
        // 状態を保存
        saveTimerState()
        
        // 既存の記録を削除して新しい記録を開始
        weightViewModel.dietRecords.removeAll { Calendar.current.isDate($0.date, inSameDayAs: Date()) }
        
        // 断食記録を開始（進行中）
        let dietRecord = DietRecord(
            date: Date(),
            success: false,
            startTime: fastingStartTime,
            endTime: fastingEndTime
        )
        
        weightViewModel.dietRecords.append(dietRecord)
        weightViewModel.saveDietRecords()
        
        // タイマーを開始
        startBackgroundTimer()
    }
    
    private func confirmStopTimer() {
        // 前回の時間を保存
        lastStartTime = startTime
        lastEndTime = fastingEndTime
        lastActualEndTime = Date() // 実際の停止時刻を保存
        saveLastTimes()
        
        // タイマーを停止（記録は削除しない）
        stopTimerWithoutDeletingRecord()
    }
    
    private func stopTimerWithoutDeletingRecord() {
        isTimerRunning = false
        startTime = nil
        
        // 断食終了予定時間を削除
        fastingEndTime = Date()
        
        // 状態を保存
        saveTimerState()
        
        // タイマーを停止
        timer?.invalidate()
        timer = nil
        
        // 進行中の断食記録を完了記録として保存（中断）
        if let existingIndex = weightViewModel.dietRecords.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: Date()) && !$0.success }) {
            weightViewModel.dietRecords[existingIndex].success = false
            weightViewModel.dietRecords[existingIndex].endTime = Date()
            weightViewModel.saveDietRecords()
        }
    }
    
    private func completeFasting() {
        // タイマー状態をクリア
        isTimerRunning = false
        startTime = nil
        
        // 断食終了予定時間を削除
        fastingEndTime = Date()
        
        saveTimerState()
        
        // タイマーを停止
        timer?.invalidate()
        timer = nil
        
        // 実際の終了時刻を計算（開始時刻 + 設定された断食時間）
        let actualEndTime = Calendar.current.date(byAdding: .hour, value: Int(fastingDuration), to: fastingStartTime) ?? Date()
        
        // 断食成功記録を保存
        let successRecord = DietRecord(
            date: Date(),
            success: true,
            startTime: fastingStartTime,
            endTime: actualEndTime
        )
        
        // 既存の記録を削除して成功記録を追加
        weightViewModel.dietRecords.removeAll { Calendar.current.isDate($0.date, inSameDayAs: Date()) }
        weightViewModel.dietRecords.append(successRecord)
        weightViewModel.saveDietRecords()
        
        // 成功通知を送信
        NotificationManager.shared.sendFastingSuccessNotification()
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // MARK: - Timer State Management
    private func loadTimerState() {
        let userDefaults = UserDefaults.standard
        isTimerRunning = userDefaults.bool(forKey: "isTimerRunning")
        
        // 前回の時間を読み込み
        if let lastStartData = userDefaults.object(forKey: "lastStartTime") as? Date {
            lastStartTime = lastStartData
        }
        if let lastEndData = userDefaults.object(forKey: "lastEndTime") as? Date {
            lastEndTime = lastEndData
        }
        if let lastActualEndData = userDefaults.object(forKey: "lastActualEndTime") as? Date {
            lastActualEndTime = lastActualEndData
        }
        
        if isTimerRunning {
            if let startTimeData = userDefaults.object(forKey: "timerStartTime") as? Date {
                startTime = startTimeData
                fastingStartTime = startTimeData
                updateFastingEndTime()
                
                // 残り時間を計算
                let elapsedTime = Date().timeIntervalSince(startTimeData)
                let totalTime = fastingEndTime.timeIntervalSince(fastingStartTime)
                remainingTime = max(0, totalTime - elapsedTime)
                
                // タイマーがまだ実行中かチェック
                if remainingTime > 0 {
                    startBackgroundTimer()
                } else {
                    // タイマーが完了している場合
                    completeFasting()
                }
            }
        }
    }
    
    private func saveTimerState() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(isTimerRunning, forKey: "isTimerRunning")
        userDefaults.set(startTime, forKey: "timerStartTime")
    }
    
    private func saveLastTimes() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(lastStartTime, forKey: "lastStartTime")
        userDefaults.set(lastEndTime, forKey: "lastEndTime")
        userDefaults.set(lastActualEndTime, forKey: "lastActualEndTime")
    }
    
    private func startBackgroundTimer() {
        // 既存のタイマーを停止
        timer?.invalidate()
        
        // 新しいタイマーを開始
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                stopTimerWithoutDeletingRecord()
                completeFasting()
            }
        }
    }
    
    private func checkExistingRecordAndStart() {
        let currentDate = Date()
        let existingRecord = weightViewModel.dietRecords.first { Calendar.current.isDate($0.date, inSameDayAs: currentDate) }
        
        if existingRecord != nil {
            // 既存の記録がある場合は確認アラートを表示
            showingStartAlert = true
        } else {
            // 既存の記録がない場合は新しい断食を開始
            startTimer()
        }
    }
    
    private func confirmStartWithOverwrite() {
        let currentDate = Date()
        // 記録を削除して新しい断食を開始
        weightViewModel.dietRecords.removeAll { Calendar.current.isDate($0.date, inSameDayAs: currentDate) }
        weightViewModel.saveDietRecords()
        
        // タイマー状態もリセット
        resetTimerState()
        
        startTimer()
    }
    
    private func resetTimerState() {
        // タイマー状態をクリア
        isTimerRunning = false
        startTime = nil
        fastingStartTime = Date() // 現在時刻にリセット
        updateFastingEndTime() // 終了予定時間を更新
        remainingTime = TimeInterval(fastingDuration * 60 * 60)
        
        // UserDefaultsからタイマー状態を削除
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: "isTimerRunning")
        userDefaults.removeObject(forKey: "timerStartTime")
        
        // タイマーを停止
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Time Info View
struct TimeInfoView: View {
    let isTimerRunning: Bool
    let currentTimeString: String
    let endTimeString: String
    let shouldShowLastTimes: Bool
    let lastStartTime: Date?
    let lastEndTime: Date?
    let fastingStartTime: Date?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                Text("現在時刻")
                    .foregroundColor(.primary)
                Spacer()
                Text(currentTimeString)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            // タイマー実施中のみ断食開始時間を表示
            if isTimerRunning, let startTime = fastingStartTime {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(.orange)
                    Text("開始時刻")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(formatDateTimeWithDate(from: startTime))
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
            
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.green)
                Text("終了予定")
                    .foregroundColor(.primary)
                Spacer()
                Text(isTimerRunning ? formatDateTimeWithDate(from: Calendar.current.date(byAdding: .hour, value: 16, to: fastingStartTime ?? Date()) ?? Date()) : "-")
                    .fontWeight(.bold)
                    .foregroundColor(isTimerRunning ? .green : .secondary)
            }
            
            // 前回の時間表示（停止時のみ）
            if shouldShowLastTimes {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.orange)
                        Text("前回の断食")
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    HStack {
                        Text("開始")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Spacer()
                        Text(formatDateTimeWithDate(from: lastStartTime!))
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                    
                    HStack {
                        Text("終了")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Spacer()
                        Text(formatDateTimeWithDate(from: lastEndTime!))
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func formatDateTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDateTimeWithDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Timer Control Button
struct TimerControlButton: View {
    let isTimerRunning: Bool
    let onStart: () -> Void
    let onStop: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            Button(action: {
                withAnimation(.spring()) {
                    if isTimerRunning {
                        onStop()
                    } else {
                        onStart()
                    }
                }
            }) {
                HStack {
                    Image(systemName: isTimerRunning ? "stop.circle.fill" : "play.circle.fill")
                        .font(.title2)
                    Text(isTimerRunning ? "停止" : "開始")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(width: 150, height: 60)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: isTimerRunning ? [Color.red, Color.orange] : [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(30)
                .shadow(color: isTimerRunning ? .red.opacity(0.3) : .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
    }
}

// MARK: - Circular Progress View
struct CircularProgressView: View {
    let isTimerRunning: Bool
    let remainingTime: TimeInterval
    let readyTimeString: String
    let progressValue: Double
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // 背景円
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                    .frame(width: 250, height: 250)
                
                // 進行状況円
                Circle()
                    .trim(from: 0, to: progressValue)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: progressValue)
                
                // 中央の情報
                VStack(spacing: 8) {
                    if isTimerRunning {
                        Text(timeString(from: remainingTime))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                        
                        Text("残り時間")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(readyTimeString)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                        
                        Text("準備完了")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

#Preview {
    TimerView()
}
