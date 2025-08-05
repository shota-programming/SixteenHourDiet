import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Keys
    private enum Keys {
        static let weightRecords = "weightRecords"
        static let dietRecords = "dietRecords"
        static let fastingDuration = "fastingDuration"
    }
    
    private init() {}
    
    // MARK: - Weight Records
    func saveWeightRecords(_ records: [WeightRecord]) {
        do {
            let data = try JSONEncoder().encode(records)
            userDefaults.set(data, forKey: Keys.weightRecords)
        } catch {
            print("Error saving weight records: \(error)")
        }
    }
    
    func loadWeightRecords() -> [WeightRecord] {
        guard let data = userDefaults.data(forKey: Keys.weightRecords) else {
            return []
        }
        
        do {
            let records = try JSONDecoder().decode([WeightRecord].self, from: data)
            return records
        } catch {
            print("Error loading weight records: \(error)")
            return []
        }
    }
    
    // MARK: - Diet Records
    func saveDietRecords(_ records: [DietRecord]) {
        do {
            let data = try JSONEncoder().encode(records)
            userDefaults.set(data, forKey: Keys.dietRecords)
        } catch {
            print("Error saving diet records: \(error)")
        }
    }
    
    func loadDietRecords() -> [DietRecord] {
        guard let data = userDefaults.data(forKey: Keys.dietRecords) else {
            return []
        }
        
        do {
            let records = try JSONDecoder().decode([DietRecord].self, from: data)
            return records
        } catch {
            print("Error loading diet records: \(error)")
            return []
        }
    }
    
    // MARK: - Fasting Duration Settings
    func saveFastingDuration(_ duration: Double) {
        userDefaults.set(duration, forKey: Keys.fastingDuration)
    }
    
    func loadFastingDuration() -> Double {
        return userDefaults.double(forKey: Keys.fastingDuration)
    }
    
    // MARK: - Utility Methods
    func clearAllData() {
        userDefaults.removeObject(forKey: Keys.weightRecords)
        userDefaults.removeObject(forKey: Keys.dietRecords)
    }
    
    func hasData() -> Bool {
        return userDefaults.data(forKey: Keys.weightRecords) != nil ||
               userDefaults.data(forKey: Keys.dietRecords) != nil
    }
} 