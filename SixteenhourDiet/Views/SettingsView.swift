import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var fastingDuration: Double = 16.0
    @State private var animateSettings = false
    @State private var showingClearDataAlert = false
    @State private var showingAdRemovalAlert = false
    @State private var showingEmojiPicker = false
    @State private var showingFastingSettingsAlert = false
    @State private var selectedEmojiType = 0 // 0: 断食成功, 1: 体重記録
    @StateObject private var weightViewModel = WeightViewModel()
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var adManager = AdManager.shared
    
    // タイマーの状態を監視
    @State private var isTimerRunning = false
    
    init() {
        // 保存された断食時間を読み込み（デフォルトは16時間）
        let savedDuration = UserDefaultsManager.shared.loadFastingDuration()
        _fastingDuration = State(initialValue: savedDuration > 0 ? savedDuration : 16.0)
    }
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.cyan.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // ヘッダー
                    VStack(spacing: 10) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                            .scaleEffect(animateSettings ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateSettings)
                        
                        Text("設定")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("アプリをカスタマイズ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 広告削除オプション
                    if !adManager.isPremium {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "megaphone.slash.fill")
                                    .foregroundColor(.red)
                                Text("広告削除")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("広告を完全に削除")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("より快適な使用体験を")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("¥500")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                }
                                
                                Button(action: {
                                    showingAdRemovalAlert = true
                                }) {
                                    HStack {
                                        Image(systemName: "crown.fill")
                                            .foregroundColor(.yellow)
                                        Text("広告削除を購入")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                        )
                    } else {
                        // プレミアムユーザー表示
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                Text("プレミアムユーザー")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("広告削除済み")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                Spacer()
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                        )
                    }
                    
                    // 通知設定
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                            Text("通知設定")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(spacing: 12) {
                            ToggleRow(icon: "star.circle.fill", title: "断食成功通知", isOn: $notificationManager.settings.fastingSuccessNotification, color: .yellow)
                        }
                        .onChange(of: notificationManager.settings) { oldValue, newValue in
                            notificationManager.saveSettings()
                            notificationManager.updateAllNotifications()
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                    )
                    
                    // 絵文字設定
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "face.smiling.fill")
                                .foregroundColor(.purple)
                            Text("絵文字設定")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("断食成功")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(notificationManager.settings.fastingEmoji)
                                    .font(.title2)
                            }
                            
                            HStack {
                                Text("体重記録")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(notificationManager.settings.weightEmoji)
                                    .font(.title2)
                            }
                            
                            Button(action: {
                                showEmojiPicker()
                            }) {
                                HStack {
                                    Image(systemName: "pencil.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("絵文字を変更")
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                    )
                    
                    // 断食設定
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "timer.fill")
                                .foregroundColor(.purple)
                            Text("断食設定")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("断食時間")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(Int(fastingDuration))時間")
                                    .fontWeight(.bold)
                                    .foregroundColor(.purple)
                            }
                            Slider(value: $fastingDuration, in: 12...24, step: 1)
                                .accentColor(.purple)
                            
                            Button(action: {
                                applyFastingSettings()
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("設定を適用")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.green, Color.blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(8)
                            }
                            .disabled(isTimerRunning)
                            .opacity(isTimerRunning ? 0.5 : 1.0)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                    )
                    
                    // データ管理
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "externaldrive.fill")
                                .foregroundColor(.red)
                            Text("データ管理")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("体重記録数")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(weightViewModel.records.count)件")
                                    .fontWeight(.bold)
                                    .foregroundColor(.pink)
                            }
                            
                            HStack {
                                Text("断食記録数")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(weightViewModel.dietRecords.count)件")
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            
                            Button(action: {
                                showingClearDataAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "trash.circle.fill")
                                        .foregroundColor(.red)
                                    Text("全データを削除")
                                        .foregroundColor(.red)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                    )
                    
                    // アプリ情報
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("アプリ情報")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("バージョン")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                    )
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
        }
        .onAppear {
            animateSettings = true
            // タイマーの状態を監視
            isTimerRunning = UserDefaults.standard.bool(forKey: "isTimerRunning")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // アプリがアクティブになった時にタイマー状態を更新
            isTimerRunning = UserDefaults.standard.bool(forKey: "isTimerRunning")
        }
        .alert("データを削除", isPresented: $showingClearDataAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                weightViewModel.clearAllData()
            }
        } message: {
            Text("全ての体重記録と断食記録が削除されます。この操作は取り消せません。")
        }
        .alert("広告削除の購入", isPresented: $showingAdRemovalAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("購入", role: .none) {
                Task {
                    await adManager.purchaseAdRemoval()
                }
            }
        } message: {
            Text("¥500で広告を完全に削除します。この購入は一度だけです。")
        }
        .alert("設定が適用されました", isPresented: $showingFastingSettingsAlert) {
            Button("OK") {
                showingFastingSettingsAlert = false
            }
        } message: {
            if isTimerRunning {
                Text("タイマー稼働中は設定を変更できません。\nタイマーを停止してから再度お試しください。")
            } else {
                Text("断食時間を\(Int(fastingDuration))時間に変更しました。\n次回のタイマー開始時から適用されます。")
            }
        }
        .sheet(isPresented: $showingEmojiPicker) {
            EmojiPickerView(
                fastingEmoji: $notificationManager.settings.fastingEmoji,
                weightEmoji: $notificationManager.settings.weightEmoji
            )
        }
    }
    
    private func showEmojiPicker() {
        showingEmojiPicker = true
    }
    
    private func applyFastingSettings() {
        // タイマー稼働中は設定を適用しない
        if isTimerRunning {
            showingFastingSettingsAlert = true
            return
        }
        
        // 断食時間設定を保存
        UserDefaultsManager.shared.saveFastingDuration(fastingDuration)
        
        // 通知設定も保存
        notificationManager.saveSettings()
        notificationManager.updateAllNotifications()
        
        // ポップアップを表示
        showingFastingSettingsAlert = true
        
        print("断食設定が適用されました。次回のタイマー開始時から適用されます。")
    }
}

struct ToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

#Preview {
    SettingsView()
} 