import SwiftUI
import Charts

struct WeightChartView: View {
    let records: [WeightRecord]
    let dietRecords: [DietRecord]
    let displayMode: DisplayMode
    let weekDateRange: (startDate: Date, endDate: Date)?
    let monthDateRange: (startDate: Date, endDate: Date)?
    
    // 設定された絵文字を取得
    private var fastingEmoji: String {
        return NotificationManager.shared.settings.fastingEmoji
    }
    
    private var weightEmoji: String {
        return NotificationManager.shared.settings.weightEmoji
    }
    
    private func formatDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    // 7日間を均等に分割した日付を生成
    private func generateWeekDates(startDate: Date, endDate: Date) -> [Date] {
        let calendar = Calendar.current
        
        var dates: [Date] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                dates.append(date)
            }
        }
        return dates
    }
    
    // 月表示用に5日おきの目盛りを生成
    private func generateMonthDates(startDate: Date, endDate: Date) -> [Date] {
        let calendar = Calendar.current
        
        // 月の日数を正確に計算
        let startComponents = calendar.dateComponents([.year, .month], from: startDate)
        let monthStart = calendar.date(from: startComponents) ?? startDate
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? endDate
        let daysInMonth = calendar.dateComponents([.day], from: monthStart, to: monthEnd).day ?? 30
        
        var dates: [Date] = []
        for i in stride(from: 1, through: daysInMonth, by: 5) {
            if let date = calendar.date(byAdding: .day, value: i - 1, to: monthStart) {
                dates.append(date)
            }
        }
        // 月末日も必ず含める
        if let lastDate = calendar.date(byAdding: .day, value: daysInMonth - 1, to: monthStart) {
            if !dates.contains(lastDate) {
                dates.append(lastDate)
            }
        }
        return dates.sorted()
    }
    
    // 月表示用に5日ごとのプロットデータを生成
    private func generateMonthPlotData() -> [WeightRecord] {
        guard monthDateRange != nil else { return records }
        
        let calendar = Calendar.current
        let startDate = monthDateRange!.startDate
        let endDate = monthDateRange!.endDate
        
        var plotData: [WeightRecord] = []
        
        // 5日ごとの日付を生成
        var currentDate = startDate
        while currentDate <= endDate {
            // その日付に最も近い記録を探す
            let closestRecord = records
                .filter { calendar.isDate($0.date, inSameDayAs: currentDate) }
                .first
            
            if let record = closestRecord {
                plotData.append(record)
            } else {
                // 記録がない場合は、前後の記録から補間値を計算
                let previousRecord = records
                    .filter { $0.date < currentDate }
                    .max { $0.date < $1.date }
                
                let nextRecord = records
                    .filter { $0.date > currentDate }
                    .min { $0.date < $1.date }
                
                if let prev = previousRecord, let next = nextRecord {
                    // 前後の記録から補間
                    let daysBetween = calendar.dateComponents([.day], from: prev.date, to: next.date).day ?? 1
                    let daysFromPrev = calendar.dateComponents([.day], from: prev.date, to: currentDate).day ?? 0
                    
                    if daysBetween > 0 {
                        let weight = prev.weight + (next.weight - prev.weight) * Double(daysFromPrev) / Double(daysBetween)
                        let interpolatedRecord = WeightRecord(date: currentDate, weight: weight)
                        plotData.append(interpolatedRecord)
                    }
                } else if let prev = previousRecord {
                    // 前の記録のみある場合
                    plotData.append(prev)
                } else if let next = nextRecord {
                    // 次の記録のみある場合
                    plotData.append(next)
                }
            }
            
            // 5日後に移動
            currentDate = calendar.date(byAdding: .day, value: 5, to: currentDate) ?? currentDate
        }
        
        return plotData.sorted { $0.date < $1.date }
    }
    
    // グラフ用の計算プロパティ
    private var chartData: (minWeight: Double, maxWeight: Double, startDate: Date, endDate: Date) {
        let minWeight = (records.map { $0.weight }.min() ?? 0) - 1.5
        let maxWeight = (records.map { $0.weight }.max() ?? 0) + 1.5
        
        // 記録データの範囲を使用（プロット位置を正確にするため）
        let minDate = records.map { $0.date }.min() ?? Date()
        let maxDate = records.map { $0.date }.max() ?? Date()
        
        // 日付範囲に余白を追加してプロット位置を改善
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -1, to: minDate) ?? minDate
        let endDate = calendar.date(byAdding: .day, value: 1, to: maxDate) ?? maxDate
        
        return (minWeight: minWeight, maxWeight: maxWeight, startDate: startDate, endDate: endDate)
    }
    
    private func getXAxisScale() -> ClosedRange<Date> {
        if displayMode == .week && weekDateRange != nil {
            return weekDateRange!.startDate...weekDateRange!.endDate
        } else if displayMode == .month && monthDateRange != nil {
            // 月表示時はすべての記録の範囲を使用
            let minDate = records.map { $0.date }.min() ?? monthDateRange!.startDate
            let maxDate = records.map { $0.date }.max() ?? monthDateRange!.endDate
            return minDate...maxDate
        } else {
            let minDate = records.map { $0.date }.min() ?? Date()
            let maxDate = records.map { $0.date }.max() ?? Date()
            return minDate...maxDate
        }
    }
    
    private func getXAxisValues() -> [Date] {
        if displayMode == .week && weekDateRange != nil {
            return generateWeekDates(startDate: weekDateRange!.startDate, endDate: weekDateRange!.endDate)
        } else if displayMode == .month && monthDateRange != nil {
            // 月表示時は5日ごとの目盛りを生成
            return generateMonthDates(startDate: monthDateRange!.startDate, endDate: monthDateRange!.endDate)
        } else {
            let minDate = records.map { $0.date }.min() ?? Date()
            let maxDate = records.map { $0.date }.max() ?? Date()
            return generateMonthDates(startDate: minDate, endDate: maxDate)
        }
    }
    
    var body: some View {
        if records.isEmpty {
            // データがない場合
            VStack(spacing: 15) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                
                Text("データがありません")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Text("体重を記録するとグラフが表示されます")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
        } else {
            // データがある場合
            Chart {
                // 月表示時もすべてのrecordsをプロットするように変更
                ForEach(records) { record in
                    LineMark(
                        x: .value("日付", record.date),
                        y: .value("体重", record.weight)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    
                    PointMark(
                        x: .value("日付", record.date),
                        y: .value("体重", record.weight)
                    )
                    .symbol(Circle())
                    .foregroundStyle(.purple)
                    .symbolSize(60)
                }
            }
            .chartYScale(domain: chartData.minWeight...chartData.maxWeight)
            .chartXScale(domain: getXAxisScale())
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let weight = value.as(Double.self) {
                            Text(String(format: "%.1f", weight))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: getXAxisValues()) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(formatDateString(from: date))
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 180)
            .padding(.horizontal, 20) // 左右の余白を追加
            .padding(.vertical, 10)   // 上下の余白を追加
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        }
    }
} 