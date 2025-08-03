import Foundation

struct WeightRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    var weight: Double
    
    init(date: Date, weight: Double) {
        self.id = UUID()
        self.date = date
        self.weight = weight
    }
} 