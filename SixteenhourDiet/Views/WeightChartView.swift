import SwiftUI
import Charts

struct WeightChartView: View {
    let records: [WeightRecord]
    let dietRecords: [DietRecord]
    let displayMode: DisplayMode
    
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
            let minWeight = (records.map { $0.weight }.min() ?? 0) - 1.5  // 余白を1.5に増加
            let maxWeight = (records.map { $0.weight }.max() ?? 0) + 1.5  // 余白を1.5に増加
            
            // データの期間を計算
            let minDate = records.map { $0.date }.min() ?? Date()
            let maxDate = records.map { $0.date }.max() ?? Date()
            
            // 余白を削除してデータの範囲のみ表示
            let startDate = minDate
            let endDate = maxDate
            
            Chart {
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
                
                // 断食成功日のマークは削除
            }
            .chartYScale(domain: minWeight...maxWeight)
            .chartXScale(domain: startDate...endDate)
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
                AxisMarks { value in
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