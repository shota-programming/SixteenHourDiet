import SwiftUI

struct WeightView: View {
    @StateObject private var viewModel = WeightViewModel()
    @State private var animateChart = false
    @State private var selectedPeriod = 0 // 0: 週, 1: 月
    @State private var selectedOffset = 0 // 0: 現在, 1: 前, 2: 前々
    @State private var showingInputForm = false
    @State private var showingSuccessAlert = false
    @FocusState private var isWeightFieldFocused: Bool
    
    // 本日の体重記録
    private var todayWeightRecord: WeightRecord? {
        let today = Date()
        return viewModel.records.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                gradient: Gradient(colors: [Color.pink.opacity(0.3), Color.purple.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // ヘッダー
                    VStack(spacing: 10) {
                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.pink)
                            .scaleEffect(animateChart ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateChart)
                        
                        Text("体重記録")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("健康管理をサポート")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 表示期間選択（新UI）
                    VStack(spacing: 16) {
                        // 週/月切り替え
                        Picker("表示タイプ", selection: $selectedPeriod) {
                            Text("週").tag(0)
                            Text("月").tag(1)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        // 期間スライド
                        HStack(spacing: 24) {
                            Button(action: {
                                if selectedOffset < 2 {
                                    withAnimation(.spring()) {
                                        selectedOffset += 1
                                    }
                                }
                            }) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(selectedOffset < 2 ? .purple : .gray.opacity(0.3))
                            }
                            .disabled(selectedOffset >= 2)
                            
                            VStack(spacing: 2) {
                                Text(periodDisplayText)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.purple)
                                Text(periodRangeText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(minWidth: 120)
                            
                            Button(action: {
                                if selectedOffset > 0 {
                                    withAnimation(.spring()) {
                                        selectedOffset -= 1
                                    }
                                }
                            }) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(selectedOffset > 0 ? .purple : .gray.opacity(0.3))
                            }
                            .disabled(selectedOffset <= 0)
                        }
                        .padding(.vertical, 4)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.95))
                            .shadow(color: .gray.opacity(0.15), radius: 8, x: 0, y: 4)
                    )
                    
                    // グラフ表示
                    WeightChartView(
                        records: viewModel.filteredRecords(period: selectedPeriod, offset: selectedOffset),
                        dietRecords: viewModel.dietRecords,
                        displayMode: selectedPeriod == 0 ? .week : .month,
                        weekDateRange: selectedPeriod == 0 ? viewModel.getWeekDateRange(period: selectedPeriod, offset: selectedOffset) : nil,
                        monthDateRange: selectedPeriod == 1 ? viewModel.getMonthDateRange(period: selectedPeriod, offset: selectedOffset) : nil
                    )
                    .frame(height: 180)
                    
                    // 入力フォーム
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.pink)
                            Text("本日の体重記録")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        // 本日の記録状況
                        if let todayRecord = todayWeightRecord {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("本日の記録済み")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                Spacer()
                                Text(String(format: "%.1f kg", todayRecord.weight))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.purple)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.green.opacity(0.1))
                            )
                        } else {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.orange)
                                Text("本日の記録未入力")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                Spacer()
                                Text("記録してください")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.orange.opacity(0.1))
                            )
                        }
                        
                        VStack(spacing: 10) {
                            HStack(spacing: 10) {
                                Text("今日の体重")
                                    .foregroundColor(.primary)
                                    .font(.subheadline)
                                
                                TextField("kg", text: $viewModel.inputWeight)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 80)
                                    .focused($isWeightFieldFocused)
                                    .toolbar {
                                        ToolbarItemGroup(placement: .keyboard) {
                                            Spacer()
                                            Button("完了") {
                                                isWeightFieldFocused = false
                                            }
                                            .foregroundColor(.blue)
                                        }
                                    }
                                Text("kg")
                                    .foregroundColor(.secondary)
                            }
                            .focused($isWeightFieldFocused)
                            
                            // ボタン行
                            HStack(spacing: 8) {
                                // 記録ボタン
                                Button(action: {
                                    if !viewModel.inputWeight.isEmpty {
                                        withAnimation(.spring()) {
                                            viewModel.addWeightRecord()
                                            showingSuccessAlert = true
                                            // キーボードを閉じる
                                            isWeightFieldFocused = false
                                            // 体重記録完了時の広告表示
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                // インタースティシャル広告を表示
                                                showInterstitialAd()
                                            }
                                        }
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text(todayWeightRecord != nil ? "更新" : "記録")
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.green, Color.blue]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                }
                                .disabled(viewModel.inputWeight.isEmpty)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
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
        .onTapGesture {
            // 背景タップでキーボードを閉じる
            isWeightFieldFocused = false
        }
        .onAppear {
            animateChart = true
            // データの再読み込みを実行
            viewModel.loadRecords()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // アプリがフォアグラウンドに戻った時にデータを再読み込み
            viewModel.loadRecords()
        }
        .alert("記録完了", isPresented: $showingSuccessAlert) {
            Button("OK") {
                showingSuccessAlert = false
            }
        } message: {
            Text(todayWeightRecord != nil ? "体重記録が更新されました" : "体重記録が正常に保存されました")
        }
    }
    
    // インタースティシャル広告表示関数
    private func showInterstitialAd() {
        let adManager = AdManager.shared
        if adManager.shouldShowInterstitialAd() {
            // 実際のAdMob実装時に広告表示ロジックを追加
            print("体重記録完了時のインタースティシャル広告を表示")
            adManager.recordInterstitialAdShown()
        }
    }
    
    private var periodDisplayText: String {
        let period = selectedPeriod == 0 ? "週" : "月"
        switch selectedOffset {
        case 0: return "今\(period)"
        case 1: return "前\(period)"
        case 2: return "前々\(period)"
        default: return "今\(period)"
        }
    }
    
    private var periodRangeText: String {
        // 期間の範囲を表示（例: 7/1〜7/7, 7月など）
        let calendar = Calendar.current
        let now = Date()
        if selectedPeriod == 0 {
            // 週
            let offsetWeek = -selectedOffset
            if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: calendar.date(byAdding: .weekOfYear, value: offsetWeek, to: now) ?? now) {
                let formatter = DateFormatter()
                formatter.dateFormat = "M/d"
                let start = formatter.string(from: weekInterval.start)
                let end = formatter.string(from: calendar.date(byAdding: .day, value: 6, to: weekInterval.start) ?? weekInterval.end)
                return "\(start)〜\(end)"
            }
        } else {
            // 月
            let offsetMonth = -selectedOffset
            if let monthInterval = calendar.dateInterval(of: .month, for: calendar.date(byAdding: .month, value: offsetMonth, to: now) ?? now) {
                let formatter = DateFormatter()
                formatter.dateFormat = "M月"
                return formatter.string(from: monthInterval.start)
            }
        }
        return ""
    }
    
    private func periodTypeText(for index: Int) -> String {
        switch index {
        case 0: return "週"
        case 1: return "月"
        default: return "週"
        }
    }
}

#Preview {
    WeightView()
} 