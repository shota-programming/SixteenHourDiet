import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var settings = NotificationSettings()
    
    private init() {
        loadSettings()
        requestNotificationPermission()
        scheduleWeightRecordReminder() // アプリ起動時にリマインダーをスケジュール
    }
    
    // MARK: - Notification Permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("通知許可が取得されました")
                } else {
                    print("通知許可が拒否されました")
                }
            }
        }
    }
    
    // MARK: - Settings Management
    func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "notificationSettings"),
           let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            self.settings = settings
        }
    }
    
    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "notificationSettings")
        }
    }
    
    // MARK: - Notification Scheduling
    func scheduleFastingStartReminder() {
        // 最新の断食記録を取得
        let lastFastingRecord = getLastFastingRecord()
        
        guard let endTime = lastFastingRecord?.endTime else { return }
        
        // 断食終了から24時間後を計算
        let nextFastingStartTime = Calendar.current.date(byAdding: .hour, value: 24, to: endTime) ?? Date()
        
        // 24時間後が過去の場合は現在時刻から1時間後に設定
        let reminderDate = nextFastingStartTime > Date() ? nextFastingStartTime : Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        
        let content = UNMutableNotificationContent()
        content.title = "断食開始の時間です"
        content.body = "次の16時間断食を開始しましょう！"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: reminderDate.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(identifier: "fastingStart", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleFastingEndReminder() {
        // 最新の断食記録を取得
        let lastFastingRecord = getLastFastingRecord()
        
        guard let startTime = lastFastingRecord?.startTime else { return }
        
        // 断食開始から16時間後を計算
        let fastingEndTime = Calendar.current.date(byAdding: .hour, value: 16, to: startTime) ?? Date()
        
        // 16時間後が過去の場合は現在時刻から1時間後に設定
        let reminderDate = fastingEndTime > Date() ? fastingEndTime : Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        
        let content = UNMutableNotificationContent()
        content.title = "断食終了の時間です"
        content.body = "16時間断食が完了しました！お疲れ様でした！"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: reminderDate.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(identifier: "fastingEnd", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleWeightRecordReminder() {
        // 最終記録日を取得
        let lastRecordDate = getLastWeightRecordDate()
        let oneWeekLater = Calendar.current.date(byAdding: .day, value: 7, to: lastRecordDate) ?? Date()
        
        // 1週間後が過去の場合は現在時刻から1時間後に設定
        let reminderDate = oneWeekLater > Date() ? oneWeekLater : Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        
        let content = UNMutableNotificationContent()
        content.title = "体重記録の時間です"
        content.body = "1週間ぶりの体重記録をしましょう！"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: reminderDate.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(identifier: "weightRecord", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // 最終体重記録日を取得
    private func getLastWeightRecordDate() -> Date {
        let userDefaults = UserDefaults.standard
        if let data = userDefaults.data(forKey: "weightRecords"),
           let records = try? JSONDecoder().decode([WeightRecord].self, from: data),
           let lastRecord = records.max(by: { $0.date < $1.date }) {
            return lastRecord.date
        }
        // 記録がない場合は現在時刻から1週間前
        return Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    }
    
    // 最新の断食記録を取得
    private func getLastFastingRecord() -> DietRecord? {
        let userDefaults = UserDefaults.standard
        if let data = userDefaults.data(forKey: "dietRecords"),
           let records = try? JSONDecoder().decode([DietRecord].self, from: data),
           let lastRecord = records.max(by: { $0.date < $1.date }) {
            return lastRecord
        }
        return nil
    }
    
    func sendFastingSuccessNotification() {
        guard settings.fastingSuccessNotification else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "断食成功！🎉"
        content.body = "16時間断食を達成しました！素晴らしいです！"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "fastingSuccess", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Notification Management
    func updateAllNotifications() {
        // 既存の通知を削除
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // 新しい通知をスケジュール
        scheduleFastingStartReminder()
        scheduleFastingEndReminder()
        scheduleWeightRecordReminder()
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Utility Methods
    func getNotificationStatus() -> Bool {
        var status = false
        let semaphore = DispatchSemaphore(value: 0)
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            status = settings.authorizationStatus == .authorized
            semaphore.signal()
        }
        
        semaphore.wait()
        return status
    }
} 