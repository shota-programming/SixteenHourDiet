import Foundation

struct DietRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    var success: Bool
    var startTime: Date?
    var endTime: Date?
    
    init(date: Date, success: Bool, startTime: Date? = nil, endTime: Date? = nil) {
        self.id = UUID()
        self.date = date
        self.success = success
        self.startTime = startTime
        self.endTime = endTime
    }
    
    // 断食開始日（前日）を取得
    var fastingStartDate: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
    }
    
    // 断食時間を計算（時間単位）
    var fastingDuration: Double? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start) / 3600 // 時間単位
    }
} 