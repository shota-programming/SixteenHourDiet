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
    
    private let userDefaultsManager = UserDefaultsManager.shared
    
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
        
        // 初回起動時のみサンプルデータを追加
        if !userDefaultsManager.hasData() {
            addSampleData()
            addSampleDietData()
        }
    }
    
    func addWeightRecord() {
        guard let weight = Double(inputWeight) else { return }
        let today = Date()
        
        // 既存の本日の記録があるかチェック
        if let existingIndex = records.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            // 既存の記録を更新
            records[existingIndex].weight = weight
        } else {
            // 新しい記録を追加
            let newRecord = WeightRecord(date: today, weight: weight)
            records.append(newRecord)
        }
        
        saveRecords()
        inputWeight = ""
        
        // 新しい体重記録リマインダーをスケジュール
        NotificationManager.shared.scheduleWeightRecordReminder()
    }
    
    func loadRecords() {
        records = userDefaultsManager.loadWeightRecords()
    }
    
    func saveRecords() {
        userDefaultsManager.saveWeightRecords(records)
    }
    
    func loadDietRecords() {
        dietRecords = userDefaultsManager.loadDietRecords()
    }
    
    func saveDietRecords() {
        userDefaultsManager.saveDietRecords(dietRecords)
    }
    
    // 断食記録を追加
    func addDietRecord(date: Date, success: Bool) {
        let newRecord = DietRecord(date: date, success: success)
        dietRecords.append(newRecord)
        saveDietRecords()
        
        // 断食成功時に通知を送信
        if success {
            NotificationManager.shared.sendFastingSuccessNotification()
        }
        
        // 断食終了リマインダーをスケジュール
        NotificationManager.shared.scheduleFastingEndReminder()
        
        // 断食開始リマインダーをスケジュール
        NotificationManager.shared.scheduleFastingStartReminder()
    }
    
    // データをクリア
    func clearAllData() {
        userDefaultsManager.clearAllData()
        records = []
        dietRecords = []
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
            // 指定週の開始日（日曜日）
            if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: offsetDate) {
                // 週の開始日を日曜日に調整
                let weekStart = weekInterval.start
                let weekday = calendar.component(.weekday, from: weekStart)
                let daysToSubtract = weekday - 1 // 日曜日を1として調整
                startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: weekStart)!
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
        
        // 過去1週間のサンプルデータのみを生成
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                // 体重の変化パターン（68kg前後で変動）
                let baseWeight = 68.0
                let randomVariation = Double.random(in: -0.3...0.3)
                let weight = baseWeight + randomVariation
                
                let record = WeightRecord(date: date, weight: weight)
                records.append(record)
            }
        }
    }
    
    // サンプル断食データを追加
    private func addSampleDietData() {
        let calendar = Calendar.current
        let today = Date()
        
        // 過去1週間のサンプル断食データのみ
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                // より現実的な成功率（70%程度）
                let success = Double.random(in: 0...1) < 0.7
                let record = DietRecord(date: date, success: success)
                dietRecords.append(record)
            }
        }
    }
} 