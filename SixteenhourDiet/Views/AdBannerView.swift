import SwiftUI

struct AdBannerView: View {
    @ObservedObject private var adManager = AdManager.shared
    
    var body: some View {
        if adManager.shouldShowBannerAd() {
            VStack(spacing: 0) {
                // 広告プレースホルダー（実際のAdMob実装時に置き換え）
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 50)
                    .overlay(
                        HStack {
                            Image(systemName: "megaphone.fill")
                                .foregroundColor(.gray)
                            Text("広告")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Button("削除") {
                                Task {
                                    await adManager.purchaseAdRemoval()
                                }
                            }
                            .font(.caption2)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 12)
                    )
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }
}

struct AdInterstitialView: View {
    @ObservedObject private var adManager = AdManager.shared
    @State private var showingAd = false
    
    var body: some View {
        EmptyView()
            .onAppear {
                if adManager.shouldShowInterstitialAd() {
                    // 実際のAdMob実装時に広告表示ロジックを追加
                    showingAd = true
                }
            }
    }
}

// 体重記録完了時の広告表示用
struct WeightRecordInterstitialAd: View {
    @ObservedObject private var adManager = AdManager.shared
    @State private var showingAd = false
    
    var body: some View {
        EmptyView()
            .onAppear {
                if adManager.shouldShowInterstitialAd() {
                    // 体重記録完了時の広告表示
                    showingAd = true
                    print("体重記録完了時の広告を表示")
                    adManager.recordInterstitialAdShown()
                }
            }
    }
}

#Preview {
    VStack {
        Text("メインコンテンツ")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue.opacity(0.1))
        
        AdBannerView()
    }
} 