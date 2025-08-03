//
//  UserDefaultsManager.swift
//  SixteenhourDiet
//
//  Created by 近山翔太 on 2025/07/27.
//

import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private let key = "diet_records"

    func getRecords() -> [DietRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let records = try? JSONDecoder().decode([DietRecord].self, from: data) else {
            return []
        }
        return records
    }

    func addRecord(_ record: DietRecord) {
        var records = getRecords()
        records.append(record)
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    func clearRecords() {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    func loadRecords() -> [DietRecord] {
        guard let data = UserDefaults.standard.data(forKey: "records") else { return [] }
        let decoder = JSONDecoder()
        if let records = try? decoder.decode([DietRecord].self, from: data) {
            return records
        }
        return []
    }

}
