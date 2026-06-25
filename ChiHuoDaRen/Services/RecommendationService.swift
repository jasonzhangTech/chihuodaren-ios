import Foundation

struct FoodRecommendation {
    let log: FoodLog
    let reason: String
}

enum RecommendationService {
    static func recommend(from logs: [FoodLog], type: String, scene: String, excludesPitfalls: Bool) -> FoodRecommendation? {
        let candidates = logs.filter { log in
            let typeMatches = type == "不限" || log.foodType == type || log.tags.contains(type)
            let sceneMatches = scene == "不限" || log.tags.contains(scene)
            let pitfallMatches = !excludesPitfalls || !log.isPitfall
            return typeMatches && sceneMatches && pitfallMatches && log.status != .draft
        }

        let sorted = candidates.sorted { lhs, rhs in
            let leftScore = score(lhs)
            let rightScore = score(rhs)
            if leftScore == rightScore {
                return lhs.updatedAt > rhs.updatedAt
            }
            return leftScore > rightScore
        }

        guard let winner = sorted.first else { return nil }

        var reasons: [String] = []
        if winner.revisitIntent == .yes {
            reasons.append("你标过再去")
        }
        if winner.rating > 0 {
            reasons.append("评分 \(String(format: "%.1f", winner.rating))")
        }
        if !scene.isEmpty, scene != "不限", winner.tags.contains(scene) {
            reasons.append("适合\(scene)")
        }
        if reasons.isEmpty {
            reasons.append("和当前条件最接近")
        }

        return FoodRecommendation(log: winner, reason: reasons.joined(separator: "，"))
    }

    private static func score(_ log: FoodLog) -> Double {
        var value = log.rating
        if log.revisitIntent == .yes { value += 1.2 }
        if log.revisitIntent == .no { value -= 1.4 }
        if log.isPitfall { value -= 2.0 }
        value += min(Double(log.tags.count) * 0.1, 0.5)
        return value
    }
}

