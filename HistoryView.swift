//
//  HistoryView.swift
//  SixteenhourDiet
//
//  Created by 近山翔太 on 2025/07/27.
//

import SwiftUI

struct HistoryView: View {
    @State private var records: [DietRecord] = []

    var body: some View {
        NavigationView {
            List(records.reversed(), id: \.date) { record in
                HStack {
                    Text(formattedDate(record.date))
                    Spacer()
                    Text(record.success ? "✅ 成功" : "❌ 未達成")
                        .foregroundColor(record.success ? .green : .red)
                }
            }
            .navigationTitle("ダイエット履歴")
            .onAppear {
                records = UserDefaultsManager.shared.getRecords()
            }
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
