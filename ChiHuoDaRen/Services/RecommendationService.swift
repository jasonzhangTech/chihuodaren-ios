import Foundation

struct FoodRecommendation {
    let log: FoodLog
    let reason: String
}

enum RecommendationService {
    static func recommend(from logs: [FoodLog], filter: String) -> FoodRecommendation? {
        let candidates = logs.filter { log in
            let filterMatches: Bool
            switch filter {
            case "全部":
                filterMatches = true
            default:
                filterMatches = log.foodType == filter
            }
            return filterMatches && log.status != .draft && !log.isPitfall
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
        if winner.finalRating > 0 {
            reasons.append("评分 \(String(format: "%.1f", winner.finalRating))")
        }
        if filter != "全部" {
            if winner.foodType == filter {
                reasons.append("类型是\(filter)")
            }
        }
        if reasons.isEmpty {
            reasons.append("和当前条件最接近")
        }

        return FoodRecommendation(log: winner, reason: reasons.joined(separator: "，"))
    }

    private static func score(_ log: FoodLog) -> Double {
        log.finalRating
    }
}
