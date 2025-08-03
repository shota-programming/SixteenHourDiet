import SwiftUI

struct WeightView: View {
    @StateObject private var viewModel = WeightViewModel()
    @State private var animateChart = false
    @State private var selectedPeriod = 0 // 0: 週, 1: 月
    @State private var selectedOffset = 0 // 0: 現在, 1: 前, 2: 前々
    @State private var showingInputForm = false
    @State private var showingSuccessAlert = false
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                gradient: Gradient(colors: [Color.pink.opacity(0.3), Color.purple.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
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
                    displayMode: selectedPeriod == 0 ? .week : .month
                )
                .frame(height: 180)
                .padding(.horizontal, 8)
                .scaleEffect(animateChart ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateChart)
                
                // 入力フォーム
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.pink)
                        Text("新しい記録")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            DatePicker("日付", selection: $viewModel.inputDate, displayedComponents: .date)
                                .labelsHidden()
                                .scaleEffect(0.85)
                            
                            TextField("体重(kg)", text: $viewModel.inputWeight)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 70)
                        }
                        
                        // ボタン行
                        HStack(spacing: 8) {
                            // 記録ボタン
                            Button(action: {
                                if !viewModel.inputWeight.isEmpty {
                                    withAnimation(.spring()) {
                                        viewModel.addWeightRecord()
                                        showingSuccessAlert = true
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("記録")
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
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
                            
                            // リセットボタン
                            Button(action: {
                                withAnimation(.spring()) {
                                    viewModel.inputWeight = ""
                                    viewModel.inputDate = Date()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                    Text("リセット")
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.orange, Color.red]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                )
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            animateChart = true
        }
        .alert("記録完了", isPresented: $showingSuccessAlert) {
            Button("OK") {
                showingSuccessAlert = false
            }
        } message: {
            Text("体重記録が正常に保存されました")
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