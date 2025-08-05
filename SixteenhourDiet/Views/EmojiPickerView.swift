import SwiftUI

struct EmojiPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var fastingEmoji: String
    @Binding var weightEmoji: String
    
    private let fastingEmojis = ["🍽️", "🥗", "🥑", "🥦", "🥬", "🥒", "🍎", "🍊", "🍌", "🍓", "🍇", "🍉", "🍈", "🍍", "🥝", "🥭", "🥥", "🥜", "🌰", "🍎"]
    private let weightEmojis = ["⚖️", "🏋️", "💪", "🏃", "🚴", "🏊", "🧘", "🎯", "📊", "📈", "📉", "🎨", "🌈", "⭐", "🌟", "💎", "💍", "👑", "🏆", "🎖️"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // ヘッダー
                    VStack(spacing: 10) {
                        Image(systemName: "face.smiling.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.purple)
                        
                        Text("絵文字設定")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("カレンダーに表示される絵文字を選択")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 断食成功絵文字選択
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "timer.circle.fill")
                                .foregroundColor(.orange)
                            Text("断食成功")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                            ForEach(fastingEmojis, id: \.self) { emoji in
                                Button(action: {
                                    fastingEmoji = emoji
                                }) {
                                    Text(emoji)
                                        .font(.title)
                                        .padding(8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(fastingEmoji == emoji ? Color.orange.opacity(0.3) : Color.clear)
                                        )
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                    )
                    
                    // 体重記録絵文字選択
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "scalemass.fill")
                                .foregroundColor(.pink)
                            Text("体重記録")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                            ForEach(weightEmojis, id: \.self) { emoji in
                                Button(action: {
                                    weightEmoji = emoji
                                }) {
                                    Text(emoji)
                                        .font(.title)
                                        .padding(8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(weightEmoji == emoji ? Color.pink.opacity(0.3) : Color.clear)
                                        )
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                    )
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("絵文字選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    EmojiPickerView(
        fastingEmoji: .constant("🍽️"),
        weightEmoji: .constant("⚖️")
    )
} 