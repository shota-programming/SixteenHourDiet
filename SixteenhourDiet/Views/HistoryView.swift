import SwiftUI

struct HistoryView: View {
    @State private var selectedDate = Date()
    @State private var animateCalendar = false
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
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
                    CalendarView(selectedDate: $selectedDate)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                        )
                    
                    // 選択日付の詳細表示
                    DayDetailView(selectedDate: selectedDate)
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
            animateCalendar = true
        }
    }
}

struct CalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentMonth = Date()
    
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
            .padding(.horizontal)
            
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
                ForEach(daysInMonth(), id: \.self) { date in
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
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        
        var days: [Date?] = []
        
        // 前月の日付を追加
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // 今月の日付を追加
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func hasFastingRecord(for date: Date) -> Bool {
        // サンプルデータ：ランダムに成功記録を生成
        let calendar = Calendar.current
        let daysSinceToday = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
        return daysSinceToday >= 0 && daysSinceToday < 30 && Bool.random()
    }
    
    private func hasWeightRecord(for date: Date) -> Bool {
        // サンプルデータ：ランダムに体重記録を生成
        let calendar = Calendar.current
        let daysSinceToday = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
        return daysSinceToday >= 0 && daysSinceToday < 30 && Bool.random()
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let hasFastingRecord: Bool
    let hasWeightRecord: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                // 記録マーカー
                HStack(spacing: 2) {
                    if hasFastingRecord {
                        Circle()
                            .fill(.orange)
                            .frame(width: 4, height: 4)
                    }
                    if hasWeightRecord {
                        Circle()
                            .fill(.pink)
                            .frame(width: 4, height: 4)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(.purple)
                Text(dateString(from: selectedDate))
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                // 断食記録
                HStack {
                    Image(systemName: "timer.circle.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("16時間断食")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("成功")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    Spacer()
                    Text("16時間")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
                
                // 体重記録
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
                    Text("65.2 kg")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
                .padding()
                .background(Color.pink.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 (E)"
        return formatter.string(from: date)
    }
}

#Preview {
    HistoryView()
} 