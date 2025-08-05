import SwiftUI

struct DayDetailEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var weightViewModel: WeightViewModel
    let selectedDate: Date
    
    @State private var fastingStartTime: Date = Date()
    @State private var fastingEndTime: Date = Date()
    @State private var weight: String = ""
    @State private var showingSaveAlert = false
    
    private var existingDietRecord: DietRecord? {
        weightViewModel.dietRecords.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    private var existingWeightRecord: WeightRecord? {
        weightViewModel.records.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    // 断食成功の自動判定（16時間以上）
    private var isFastingSuccessful: Bool {
        let duration = fastingEndTime.timeIntervalSince(fastingStartTime) / 3600
        return duration >= 16.0
    }
    
    // 開始時間の選択範囲（前日〜当日）
    private var fastingStartTimeRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let previousDay = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        let endOfSelectedDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: selectedDate) ?? selectedDate
        return previousDay...endOfSelectedDay
    }
    
    // 終了時間の選択範囲（当日のみ）
    private var fastingEndTimeRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let startOfSelectedDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        let endOfSelectedDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: selectedDate) ?? selectedDate
        return startOfSelectedDay...endOfSelectedDay
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // ヘッダー
                        VStack(spacing: 10) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 50))
                                .foregroundColor(.purple)
                            
                            Text(dateString)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("記録を編集")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // 断食記録セクション
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "timer.fill")
                                    .foregroundColor(.green)
                                Text("断食記録")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(spacing: 15) {
                                // 断食開始時間
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("断食開始時間")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    DatePicker("開始時間", selection: $fastingStartTime, in: fastingStartTimeRange, displayedComponents: [.date, .hourAndMinute])
                                        .labelsHidden()
                                        .environment(\.locale, Locale(identifier: "ja_JP"))
                                }
                                
                                // 断食終了時間
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("断食終了時間")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    DatePicker("終了時間", selection: $fastingEndTime, in: fastingEndTimeRange, displayedComponents: [.date, .hourAndMinute])
                                        .labelsHidden()
                                        .environment(\.locale, Locale(identifier: "ja_JP"))
                                }
                                
                                // 断食時間と成功判定の表示
                                if let duration = calculateFastingDuration() {
                                    VStack(spacing: 8) {
                                        HStack {
                                            Text("断食時間")
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Text(String(format: "%.1f時間", duration))
                                                .fontWeight(.bold)
                                                .foregroundColor(isFastingSuccessful ? .green : .orange)
                                        }
                                        
                                        HStack {
                                            Text("判定")
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Text(isFastingSuccessful ? "成功" : "失敗")
                                                .fontWeight(.bold)
                                                .foregroundColor(isFastingSuccessful ? .green : .red)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isFastingSuccessful ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                        )
                        
                        // 体重記録セクション
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "scalemass.fill")
                                    .foregroundColor(.pink)
                                Text("体重記録")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(spacing: 15) {
                                HStack {
                                    Text("体重")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    TextField("kg", text: $weight)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 80)
                                    Text("kg")
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
                        
                        // 保存ボタン
                        Button(action: {
                            saveRecords()
                            showingSaveAlert = true
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("保存")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.green, Color.blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(15)
                        }
                        .disabled(weight.isEmpty && fastingStartTime == fastingEndTime)
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("記録編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadExistingData()
        }
        .alert("保存完了", isPresented: $showingSaveAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("記録が保存されました。")
        }
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: selectedDate)
    }
    
    private func loadExistingData() {
        // 既存の断食記録を読み込み
        if let dietRecord = existingDietRecord {
            fastingStartTime = dietRecord.startTime ?? selectedDate
            fastingEndTime = dietRecord.endTime ?? selectedDate
        } else {
            // 新規作成時はデフォルト値を設定
            let calendar = Calendar.current
            fastingStartTime = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            fastingEndTime = selectedDate
        }
        
        // 既存の体重記録を読み込み
        if let weightRecord = existingWeightRecord {
            weight = String(format: "%.1f", weightRecord.weight)
        }
    }
    
    private func calculateFastingDuration() -> Double? {
        return fastingEndTime.timeIntervalSince(fastingStartTime) / 3600
    }
    
    private func saveRecords() {
        // 断食記録を保存（自動判定）
        let newDietRecord = DietRecord(
            date: selectedDate,
            success: isFastingSuccessful,
            startTime: fastingStartTime,
            endTime: fastingEndTime
        )
        
        // 既存の記録を削除して新しい記録を追加
        weightViewModel.dietRecords.removeAll { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
        weightViewModel.dietRecords.append(newDietRecord)
        weightViewModel.saveDietRecords()
        
        // 体重記録を保存
        if !weight.isEmpty, let weightValue = Double(weight) {
            let newWeightRecord = WeightRecord(date: selectedDate, weight: weightValue)
            
            // 既存の記録を削除して新しい記録を追加
            weightViewModel.records.removeAll { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            weightViewModel.records.append(newWeightRecord)
            weightViewModel.saveRecords()
        } else {
            // 体重が空の場合は記録を削除
            weightViewModel.records.removeAll { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            weightViewModel.saveRecords()
        }
        
        // 保存完了時の広告表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showInterstitialAd()
        }
    }
    
    // インタースティシャル広告表示関数
    private func showInterstitialAd() {
        let adManager = AdManager.shared
        if adManager.shouldShowInterstitialAd() {
            // 実際のAdMob実装時に広告表示ロジックを追加
            print("履歴編集完了時のインタースティシャル広告を表示")
            adManager.recordInterstitialAdShown()
        }
    }
} 