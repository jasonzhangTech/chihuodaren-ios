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

        return FoodRecommendation(log: winner, reason: recommendationReason(for: winner, filter: filter))
    }

    static func alternativeReason(for log: FoodLog) -> String {
        let name = displayName(for: log)
        let type = displayType(for: log)
        return "换个选择也不错，今天可以试试\(name)这家\(type)\(ratingSuffix(for: log))。"
    }

    private static func score(_ log: FoodLog) -> Double {
        log.finalRating
    }

    private static func recommendationReason(for log: FoodLog, filter: String) -> String {
        let name = displayName(for: log)
        let type = displayType(for: log)
        if filter == "全部" {
            return "今天可以去\(name)，想吃\(type)的时候很合适\(ratingSuffix(for: log))。"
        }
        return "想吃\(filter)的话，可以优先考虑\(name)\(ratingSuffix(for: log))。"
    }

    private static func displayName(for log: FoodLog) -> String {
        let name = log.shopName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "这家店" : name
    }

    private static func displayType(for log: FoodLog) -> String {
        let type = log.foodType.trimmingCharacters(in: .whitespacesAndNewlines)
        return type.isEmpty ? "这类口味" : type
    }

    private static func ratingSuffix(for log: FoodLog) -> String {
        log.finalRating > 0 ? "，综合评分 \(String(format: "%.1f", log.finalRating))" : ""
    }
}
