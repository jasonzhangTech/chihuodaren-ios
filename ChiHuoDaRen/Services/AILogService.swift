import Foundation

enum AILogService {
    static func generate(for log: FoodLog) async -> (title: String, body: String) {
        try? await Task.sleep(for: .seconds(1))

        let dishText = log.recommendedDishes
            .sorted { $0.rank < $1.rank }
            .map(\.name)
            .prefix(3)
            .joined(separator: "、")
        let typeText = log.foodType.isEmpty ? "这顿饭" : log.foodType
        let placeText = log.district.isEmpty ? "这家店" : log.district
        let note = log.voiceNoteText.isEmpty ? log.userComment : log.voiceNoteText
        let pitfall = log.isPitfall ? "但这次已经标了踩雷，下次要先避开不稳的点。" : "适合下次不知道吃什么时回来兜底。"
        let title = log.isPitfall ? "\(log.shopName)避雷备忘" : "\(log.shopName)再吃备忘"
        let ratingText = log.finalRating > 0 ? "综合评分 \(String(format: "%.1f", log.finalRating))" : "还没打分"
        let body = "\(placeText)的\(log.shopName)可以记进\(typeText)清单。推荐先点\(dishText.isEmpty ? "招牌菜" : dishText)，\(ratingText)。\(note.isEmpty ? "整体印象偏稳，适合按心情复吃。" : note)\(pitfall)"

        return (String(title.prefix(18)), String(body.prefix(120)))
    }
}
