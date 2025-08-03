import SwiftUI

struct TimerView: View {
    @State private var isTimerRunning = false
    @State private var remainingTime: TimeInterval = 16 * 60 * 60 // 16時間を秒で表現
    @State private var startTime: Date?
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.pink.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
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
                
                // 残り時間表示
                VStack {
                    Text(timeString(from: remainingTime))
                        .font(.system(size: 60, weight: .thin, design: .monospaced))
                        .foregroundColor(isTimerRunning ? .orange : .primary)
                        .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 0)
                    
                    Text("残り時間")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
                )
                
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
                
                // リセットボタン
                Button("リセット") {
                    withAnimation(.spring()) {
                        resetTimer()
                    }
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            pulseAnimation = true
        }
    }
    
    private func startTimer() {
        isTimerRunning = true
        startTime = Date()
    }
    
    private func stopTimer() {
        isTimerRunning = false
        startTime = nil
    }
    
    private func resetTimer() {
        isTimerRunning = false
        startTime = nil
        remainingTime = 16 * 60 * 60
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