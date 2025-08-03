import Foundation

struct DietRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    var success: Bool
    
    init(date: Date, success: Bool) {
        self.id = UUID()
        self.date = date
        self.success = success
    }
} 