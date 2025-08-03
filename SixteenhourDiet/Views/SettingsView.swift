import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var fastingDuration: Double = 16.0
    @State private var selectedTheme = 0
    @State private var animateSettings = false
    
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
                            ToggleRow(icon: "bell.circle.fill", title: "プッシュ通知", isOn: $notificationsEnabled, color: .orange)
                            ToggleRow(icon: "timer.circle.fill", title: "タイマー完了通知", isOn: $notificationsEnabled, color: .green)
                            ToggleRow(icon: "scalemass.circle.fill", title: "体重記録リマインダー", isOn: $notificationsEnabled, color: .pink)
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
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                    )
                    
                    // 表示設定
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "paintbrush.fill")
                                .foregroundColor(.blue)
                            Text("表示設定")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        Picker("テーマ", selection: $selectedTheme) {
                            Text("システム").tag(0)
                            Text("ライト").tag(1)
                            Text("ダーク").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
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
                            Image(systemName: "folder.fill")
                                .foregroundColor(.green)
                            Text("データ管理")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(spacing: 12) {
                            Button(action: {
                                // データエクスポート機能
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.blue)
                                    Text("データをエクスポート")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Button(action: {
                                // データリセット機能
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                    Text("データをリセット")
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
                            Button(action: {
                                // プライバシーポリシー
                            }) {
                                HStack {
                                    Image(systemName: "hand.raised")
                                        .foregroundColor(.purple)
                                    Text("プライバシーポリシー")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Button(action: {
                                // 利用規約
                            }) {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .foregroundColor(.orange)
                                    Text("利用規約")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                            
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
        }
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