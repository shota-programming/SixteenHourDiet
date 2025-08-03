import Foundation
import SwiftUI

enum DisplayMode: String, CaseIterable, Identifiable {
    case week, month
    var id: String { self.rawValue }
}

class WeightViewModel: ObservableObject {
    @Published var records: [WeightRecord] = []
    @Published var dietRecords: [DietRecord] = []
    @Published var displayMode: DisplayMode = .week
    @Published var inputDate: Date = Date()
    @Published var inputWeight: String = ""
    
    var filteredRecords: [WeightRecord] {
        return filteredRecords(period: 0, offset: 0) // デフォルトは現在の週
    }
    
    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        return df
    }()
    
    init() {
        loadRecords()
        loadDietRecords()
        addSampleData() // サンプルデータを追加
    }
    
    func addWeightRecord() {
        guard let weight = Double(inputWeight) else { return }
        let newRecord = WeightRecord(date: inputDate, weight: weight)
        records.append(newRecord)
        saveRecords()
        inputWeight = ""
    }
    
    func loadRecords() {
        // UserDefaults等から取得する処理を後で実装
    }
    
    func saveRecords() {
        // UserDefaults等に保存する処理を後で実装
    }
    
    func loadDietRecords() {
        // DietRecordの取得処理を後で実装
        addSampleDietData() // サンプルデータを追加
    }
    
    // 期間別フィルタリング機能（週/月 + オフセット）
    func filteredRecords(period: Int, offset: Int) -> [WeightRecord] {
        let calendar = Calendar.current
        let today = Date()
        
        // オフセットを計算（現在=0, 前=1, 前々=2）
        let offsetDate: Date
        switch offset {
        case 0: // 現在
            offsetDate = today
        case 1: // 前
            offsetDate = period == 0 ? 
                calendar.date(byAdding: .weekOfYear, value: -1, to: today)! :
                calendar.date(byAdding: .month, value: -1, to: today)!
        case 2: // 前々
            offsetDate = period == 0 ? 
                calendar.date(byAdding: .weekOfYear, value: -2, to: today)! :
                calendar.date(byAdding: .month, value: -2, to: today)!
        default:
            offsetDate = today
        }
        
        let startDate: Date
        let endDate: Date
        
        switch period {
        case 0: // 週
            // 指定週の開始日（月曜日）
            if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: offsetDate) {
                startDate = weekInterval.start
                endDate = calendar.date(byAdding: .day, value: 6, to: startDate)!
            } else {
                startDate = offsetDate
                endDate = calendar.date(byAdding: .day, value: 6, to: startDate)!
            }
        case 1: // 月
            // 指定月の開始日と終了日
            if let monthInterval = calendar.dateInterval(of: .month, for: offsetDate) {
                startDate = monthInterval.start
                endDate = calendar.date(byAdding: .day, value: -1, to: monthInterval.end)!
            } else {
                startDate = offsetDate
                endDate = calendar.date(byAdding: .month, value: 1, to: startDate)!
            }
        default:
            startDate = calendar.date(byAdding: .day, value: -6, to: today)!
            endDate = today
        }
        
        // デバッグ用ログ
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        print("Filtered Records - Period: \(period), Offset: \(offset)")
        print("Start Date: \(formatter.string(from: startDate))")
        print("End Date: \(formatter.string(from: endDate))")
        print("Records count: \(records.count)")
        
        let filtered = records
            .filter { $0.date >= startDate && $0.date <= endDate }
            .sorted { $0.date < $1.date }
        
        print("Filtered count: \(filtered.count)")
        
        return filtered
    }
    
    // サンプルデータを追加
    private func addSampleData() {
        let calendar = Calendar.current
        let today = Date()
        
        // 現在の月のデータを生成
        if let monthInterval = calendar.dateInterval(of: .month, for: today) {
            let startOfMonth = monthInterval.start
            let endOfMonth = calendar.date(byAdding: .day, value: -1, to: monthInterval.end)!
            
            var currentDate = startOfMonth
            while currentDate <= endOfMonth {
                // 体重の変化パターン（68kg前後で変動）
                let baseWeight = 68.0
                let dayOffset = calendar.dateComponents([.day], from: startOfMonth, to: currentDate).day ?? 0
                let weightChange = Double(dayOffset) * 0.01 // 徐々に変化
                let randomVariation = Double.random(in: -0.3...0.3)
                let weight = baseWeight + weightChange + randomVariation
                
                let record = WeightRecord(date: currentDate, weight: weight)
                records.append(record)
                
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
        }
        
        // 前月のデータも少し追加
        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: today),
           let monthInterval = calendar.dateInterval(of: .month, for: previousMonth) {
            let startOfMonth = monthInterval.start
            let endOfMonth = calendar.date(byAdding: .day, value: -1, to: monthInterval.end)!
            
            var currentDate = startOfMonth
            while currentDate <= endOfMonth {
                // 前月の体重データ
                let baseWeight = 68.5
                let dayOffset = calendar.dateComponents([.day], from: startOfMonth, to: currentDate).day ?? 0
                let weightChange = Double(dayOffset) * 0.01
                let randomVariation = Double.random(in: -0.3...0.3)
                let weight = baseWeight + weightChange + randomVariation
                
                let record = WeightRecord(date: currentDate, weight: weight)
                records.append(record)
                
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
        }
    }
    
    // サンプル断食データを追加
    private func addSampleDietData() {
        let calendar = Calendar.current
        let today = Date()
        
        // 過去6ヶ月間のサンプル断食データ
        for i in 0..<180 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                // より現実的な成功率（70%程度）
                let success = Double.random(in: 0...1) < 0.7
                let record = DietRecord(date: date, success: success)
                dietRecords.append(record)
            }
        }
    }
} 