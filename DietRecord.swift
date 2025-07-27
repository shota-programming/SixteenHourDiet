//
//  DietRecord.swift
//  SixteenhourDiet
//
//  Created by 近山翔太 on 2025/07/27.
//

import Foundation

struct DietRecord: Codable {
    let date: Date
    let success: Bool
    let start: Int
    let end: Int
}
