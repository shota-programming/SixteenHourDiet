import SwiftUI

struct HistoryView: View {
    @StateObject private var weightViewModel = WeightViewModel()
    @State private var selectedDate = Date()
    @State private var animateCalendar = false
    @State private var showingEditView = false
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // ヘッダー
                        VStack(spacing: 10) {
                            Image(systemName: "calendar.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.purple)
                                .scaleEffect(animateCalendar ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateCalendar)
                            
                            Text("履歴カレンダー")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("あなたの健康記録")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // カレンダー表示
                        CalendarView(selectedDate: $selectedDate, weightViewModel: weightViewModel)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.9))
                                    .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                            )
                        
                        // 選択日付の詳細表示
                        DayDetailView(selectedDate: selectedDate, weightViewModel: weightViewModel, onEditTap: {
                            showingEditView = true
                        })
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
                
                // 広告バナー
                AdBannerView()
            }
        }
        .onAppear {
            animateCalendar = true
            // データを再読み込み
            weightViewModel.loadRecords()
            weightViewModel.loadDietRecords()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // アプリがアクティブになった時にデータを再読み込み
            weightViewModel.loadRecords()
            weightViewModel.loadDietRecords()
        }
        .sheet(isPresented: $showingEditView) {
            DayDetailEditView(weightViewModel: weightViewModel, selectedDate: selectedDate)
        }
        .onChange(of: showingEditView) { oldValue, newValue in
            if !newValue {
                // 編集画面が閉じられた時にデータを再読み込み
                weightViewModel.loadRecords()
                weightViewModel.loadDietRecords()
            }
        }
    }
}

struct CalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentMonth = Date()
    @ObservedObject var weightViewModel: WeightViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            // 月切り替え
            HStack {
                Button(action: {
                    withAnimation {
                        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.purple)
                        .font(.title2)
                }
                
                Spacer()
                
                Text(monthYearString(from: currentMonth))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.purple)
                        .font(.title2)
                }
            }
            
            // 曜日ヘッダー
            HStack {
                ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // カレンダーグリッド
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(Array(daysInMonth().enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            hasFastingRecord: hasFastingRecord(for: date),
                            hasWeightRecord: hasWeightRecord(for: date)
                        ) {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }
    
    private func daysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let monthInterval = calendar.dateInterval(of: .month, for: currentMonth)!
        let firstDay = monthInterval.start
        
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let offsetDays = firstWeekday - 1
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)!.count
        
        var days: [Date?] = Array(repeating: nil, count: offsetDays)
        
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        
        // 7の倍数になるように調整
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func hasFastingRecord(for date: Date) -> Bool {
        return weightViewModel.dietRecords.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    private func hasWeightRecord(for date: Date) -> Bool {
        return weightViewModel.records.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let hasFastingRecord: Bool
    let hasWeightRecord: Bool
    let onTap: () -> Void
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                // 記録マーカー（絵文字）
                HStack(spacing: 2) {
                    if hasFastingRecord {
                        Text(notificationManager.settings.fastingEmoji)
                            .font(.caption2)
                    }
                    if hasWeightRecord {
                        Text(notificationManager.settings.weightEmoji)
                            .font(.caption2)
                    }
                }
            }
            .frame(width: 35, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.purple : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DayDetailView: View {
    let selectedDate: Date
    @ObservedObject var weightViewModel: WeightViewModel
    let onEditTap: () -> Void
    
    // 設定された断食時間を取得
    private var fastingDuration: Double {
        let savedDuration = UserDefaultsManager.shared.loadFastingDuration()
        return savedDuration > 0 ? savedDuration : 16.0
    }
    
    private var dietRecord: DietRecord? {
        weightViewModel.dietRecords.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    private var weightRecord: WeightRecord? {
        weightViewModel.records.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(.purple)
                Text(dateString(from: selectedDate))
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                
                // 編集ボタン
                Button(action: onEditTap) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.blue)
                        Text("編集")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                    }
                }
            }
            
            VStack(spacing: 12) {
                // 断食記録
                if let dietRecord = dietRecord {
                    HStack {
                        Image(systemName: "timer.circle.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Int(fastingDuration))時間断食")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            // 断食ステータスの判定
                            let isToday = Calendar.current.isDate(dietRecord.date, inSameDayAs: Date())
                            let hasEndTime = dietRecord.endTime != nil
                            let isRunning = isToday && !hasEndTime && dietRecord.startTime != nil
                            
                            // デバッグ情報（開発時のみ表示）
                            #if DEBUG
                            Text("DEBUG: success=\(dietRecord.success), hasEndTime=\(hasEndTime), isToday=\(isToday)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            #endif
                            
                            if isRunning {
                                Text("断食中")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else if dietRecord.success {
                                Text("成功")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else if hasEndTime {
                                Text("失敗")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            } else {
                                Text("記録なし")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                        
                        if let duration = dietRecord.fastingDuration {
                            Text(String(format: "%.1f時間", duration))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(dietRecord.success ? Color.green : Color.clear)
                                .foregroundColor(dietRecord.success ? .white : .secondary)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                    
                    // 断食開始時間と終了時間の表示（全ての記録で表示）
                    VStack(spacing: 8) {
                        // 開始時間表示
                        if let startTime = dietRecord.startTime {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("開始時間")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(formatDateTime(from: startTime))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                        
                        // 終了時間表示
                        if let endTime = dietRecord.endTime {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                    .foregroundColor(.green)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("終了時間")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(formatDateTime(from: endTime))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                } else {
                    HStack {
                        Image(systemName: "timer.circle.fill")
                            .foregroundColor(.gray)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Int(fastingDuration))時間断食")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("記録なし")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // 体重記録
                if let weightRecord = weightRecord {
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .foregroundColor(.pink)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("体重記録")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("記録済み")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        Spacer()
                        Text(String(format: "%.1f kg", weightRecord.weight))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    }
                    .padding()
                    .background(Color.pink.opacity(0.1))
                    .cornerRadius(10)
                } else {
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .foregroundColor(.gray)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("体重記録")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("記録なし")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
    }
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 (E)"
        return formatter.string(from: date)
    }
    
    private func formatDateTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    HistoryView()
} 