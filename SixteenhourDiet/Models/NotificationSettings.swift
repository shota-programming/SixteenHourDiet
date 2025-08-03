import Foundation

struct NotificationSettings: Codable, Equatable {
    var fastingSuccessNotification: Bool = false
    
    // 通知時間設定
    var weightRecordTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    
    // 体重記録リマインダーの曜日（週1回）
    var weightRecordDayOfWeek: Int = 1 // 月曜日（1=日曜日, 2=月曜日, ...）
} 