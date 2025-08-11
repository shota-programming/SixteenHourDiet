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
    
    // 断食記録をクリア（実行中はクリア不可）
    func clearDietRecord(for date: Date) -> Bool {
        let calendar = Calendar.current
        let today = Date()
        
        // 実行中の断食があるかチェック（今日のみ）
        if calendar.isDate(date, inSameDayAs: today) {
            if let existingRecord = dietRecords.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
                // 実行中の断食はクリア不可
                if existingRecord.startTime != nil && existingRecord.endTime == nil {
                    return false
                }
            }
        }
        
        // 指定された日付の断食記録を削除
        if let index = dietRecords.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            dietRecords.remove(at: index)
            saveDietRecords()
            return true
        }
        
        return false
    }
    
    // 本日の断食記録を取得
    func getTodayDietRecord() -> DietRecord? {
        let today = Date()
        return dietRecords.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }
    
    // 本日の断食記録が実行中かチェック
    func isTodayFastingInProgress() -> Bool {
        if let todayRecord = getTodayDietRecord() {
            return todayRecord.startTime != nil && todayRecord.endTime == nil
        }
        return false
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
            // 指定週の開始日と終了日を正確に計算
            if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: offsetDate) {
                startDate = weekInterval.start
                // 週の終了日は7日後の前日（6日後）にする
                endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? startDate
            } else {
                // フォールバック: 手動で週の範囲を計算
                let weekday = calendar.component(.weekday, from: offsetDate)
                let daysFromWeekStart = weekday - calendar.firstWeekday
                startDate = calendar.date(byAdding: .day, value: -daysFromWeekStart, to: offsetDate) ?? offsetDate
                endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? offsetDate
            }
        case 1: // 月
            // 指定月の開始日と終了日
            if let monthInterval = calendar.dateInterval(of: .month, for: offsetDate) {
                startDate = monthInterval.start
                endDate = monthInterval.end
            } else {
                // フォールバック: 手動で月の範囲を計算
                let components = calendar.dateComponents([.year, .month], from: offsetDate)
                startDate = calendar.date(from: components) ?? offsetDate
                endDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? offsetDate
            }
        default:
            startDate = calendar.date(byAdding: .day, value: -6, to: today) ?? today
            endDate = today
        }
        
        // デバッグ用ログ
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        print("Filtered Records - Period: \(period), Offset: \(offset)")
        print("Start Date: \(formatter.string(from: startDate))")
        print("End Date: \(formatter.string(from: endDate))")
        print("Records count: \(records.count)")
        
        // 各記録の日付をデバッグ出力
        print("All records dates:")
        for (index, record) in records.enumerated() {
            print("  [\(index)]: \(formatter.string(from: record.date))")
        }
        
        let filtered = records
            .filter { $0.date >= startDate && $0.date <= endDate }
            .sorted { $0.date < $1.date }
        
        print("Filtered count: \(filtered.count)")
        print("Filtered records:")
        for record in filtered {
            print("  - \(formatter.string(from: record.date))")
        }
        
        return filtered
    }
    
    // 指定された期間とオフセットの週の日付範囲を取得
    func getWeekDateRange(period: Int, offset: Int) -> (startDate: Date, endDate: Date) {
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
            // 指定週の開始日と終了日を正確に計算
            if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: offsetDate) {
                startDate = weekInterval.start
                // 週の終了日は7日後の前日（6日後）にする
                endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? startDate
            } else {
                // フォールバック: 手動で週の範囲を計算
                let weekday = calendar.component(.weekday, from: offsetDate)
                let daysFromWeekStart = weekday - calendar.firstWeekday
                startDate = calendar.date(byAdding: .day, value: -daysFromWeekStart, to: offsetDate) ?? offsetDate
                endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? offsetDate
            }
        case 1: // 月
            // 指定月の開始日と終了日
            if let monthInterval = calendar.dateInterval(of: .month, for: offsetDate) {
                startDate = monthInterval.start
                endDate = monthInterval.end
            } else {
                // フォールバック: 手動で月の範囲を計算
                let components = calendar.dateComponents([.year, .month], from: offsetDate)
                startDate = calendar.date(from: components) ?? offsetDate
                endDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? offsetDate
            }
        default:
            startDate = calendar.date(byAdding: .day, value: -6, to: today) ?? today
            endDate = today
        }
        
        return (startDate: startDate, endDate: endDate)
    }
    
    // 指定された期間とオフセットの月の日付範囲を取得
    func getMonthDateRange(period: Int, offset: Int) -> (startDate: Date, endDate: Date) {
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
            // 指定週の開始日と終了日を正確に計算
            if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: offsetDate) {
                startDate = weekInterval.start
                // 週の終了日は7日後の前日（6日後）にする
                endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? startDate
            } else {
                // フォールバック: 手動で週の範囲を計算
                let weekday = calendar.component(.weekday, from: offsetDate)
                let daysFromWeekStart = weekday - calendar.firstWeekday
                startDate = calendar.date(byAdding: .day, value: -daysFromWeekStart, to: offsetDate) ?? offsetDate
                endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? offsetDate
            }
        case 1: // 月
            // 指定月の開始日と終了日
            if let monthInterval = calendar.dateInterval(of: .month, for: offsetDate) {
                startDate = monthInterval.start
                endDate = monthInterval.end
            } else {
                // フォールバック: 手動で月の範囲を計算
                let components = calendar.dateComponents([.year, .month], from: offsetDate)
                startDate = calendar.date(from: components) ?? offsetDate
                endDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? offsetDate
            }
        default:
            startDate = calendar.date(byAdding: .day, value: -6, to: today) ?? today
            endDate = today
        }
        
        return (startDate: startDate, endDate: endDate)
    }
} 