import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // 16時間タイマー
            TimerView()
                .tabItem {
                    Image(systemName: "timer.circle.fill")
                        .foregroundColor(.orange)
                    Text("タイマー")
                }
                .accentColor(.orange)
            
            // 体重記録
            WeightView()
                .tabItem {
                    Image(systemName: "scalemass.fill")
                        .foregroundColor(.pink)
                    Text("体重記録")
                }
                .accentColor(.pink)
            
            // 履歴確認
            HistoryView()
                .tabItem {
                    Image(systemName: "list.bullet.circle.fill")
                        .foregroundColor(.purple)
                    Text("履歴")
                }
                .accentColor(.purple)
            
            // 設定
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.blue)
                    Text("設定")
                }
                .accentColor(.blue)
        }
        .accentColor(.orange)
    }
}

#Preview {
    MainTabView()
} 