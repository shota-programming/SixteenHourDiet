import SwiftUI

struct TimerView: View {
    @State private var isTimerRunning = false
    @State private var remainingTime: TimeInterval = 16 * 60 * 60 // 16時間を秒で表現
    @State private var startTime: Date?
    @State private var pulseAnimation = false
    @State private var fastingStartTime: Date = Date()
    @State private var fastingEndTime: Date = Calendar.current.date(byAdding: .hour, value: 16, to: Date()) ?? Date()
    @State private var timer: Timer?
    
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
                        
                        Text("16時間断食タイマー")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("健康な生活をサポート")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 円グラフ表示
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
                                    Text("16:00:00")
                                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                                        .foregroundColor(.primary)
                                    
                                    Text("準備完了")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        // 時間情報
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
                            
                            HStack {
                                Image(systemName: "target")
                                    .foregroundColor(.green)
                                Text("終了予定")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(endTimeString)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundColor(.orange)
                                Text("断食時間")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(calculateFastingDuration())
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                        )
                    }
                    
                    // 操作ボタン
                    VStack(spacing: 15) {
                        // 開始/停止ボタン
                        Button(action: {
                            withAnimation(.spring()) {
                                if isTimerRunning {
                                    stopTimer()
                                } else {
                                    startTimer()
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
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
        }
        .onAppear {
            pulseAnimation = true
            updateFastingEndTime()
        }
        .onChange(of: fastingStartTime) { _ in
            updateFastingEndTime()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
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
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
    
    // 終了時刻の文字列
    private var endTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: fastingEndTime)
    }
    
    private func updateFastingEndTime() {
        fastingEndTime = Calendar.current.date(byAdding: .hour, value: 16, to: fastingStartTime) ?? fastingStartTime
    }
    
    private func calculateFastingDuration() -> String {
        let duration = fastingEndTime.timeIntervalSince(fastingStartTime) / 3600
        return String(format: "%.1f時間", duration)
    }
    
    private func startTimer() {
        isTimerRunning = true
        startTime = Date()
        remainingTime = fastingEndTime.timeIntervalSince(fastingStartTime)
        
        // タイマーを開始
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                stopTimer()
                // 断食完了時の処理
                NotificationManager.shared.sendFastingSuccessNotification()
            }
        }
    }
    
    private func stopTimer() {
        isTimerRunning = false
        startTime = nil
        
        // タイマーを停止
        timer?.invalidate()
        timer = nil
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

#Preview {
    TimerView()
} 