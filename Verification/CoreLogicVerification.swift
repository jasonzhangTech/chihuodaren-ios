import Foundation

struct Dish {
    var name: String
    var rank: Int
}

struct FoodLog {
    var shopName: String
    var foodType: String
    var environmentRating: Double
    var serviceRating: Double
    var dishRating: Double
    var recommendedDishes: [Dish]
    var photoCount: Int
    var isPitfall: Bool
    var district: String

    var finalRating: Double {
        let parts = [environmentRating, serviceRating, dishRating].filter { $0 > 0 }
        guard !parts.isEmpty else { return 0 }
        return parts.reduce(0, +) / Double(parts.count)
    }

    var isReadyForAcceptance: Bool {
        !shopName.isEmpty &&
        !foodType.isEmpty &&
        finalRating > 0 &&
        !recommendedDishes.isEmpty &&
        photoCount > 0
    }
}

func recommend(from logs: [FoodLog], filter: String) -> FoodLog? {
    logs
        .filter { log in
            let filterMatches: Bool
            switch filter {
            case "全部":
                filterMatches = true
            case "踩雷":
                filterMatches = log.isPitfall
            default:
                filterMatches = log.foodType == filter
            }
            return filterMatches
        }
        .sorted { lhs, rhs in
            let left = lhs.finalRating - (lhs.isPitfall ? 2.0 : 0)
            let right = rhs.finalRating - (rhs.isPitfall ? 2.0 : 0)
            return left > right
        }
        .first
}

var log = FoodLog(
    shopName: "阿婆牛肉粉",
    foodType: "",
    environmentRating: 4.5,
    serviceRating: 4.0,
    dishRating: 5.0,
    recommendedDishes: [
        Dish(name: "招牌牛肉粉", rank: 0),
        Dish(name: "卤蛋", rank: 1),
        Dish(name: "酸萝卜", rank: 2)
    ],
    photoCount: 1,
    isPitfall: false,
    district: "老城小巷"
)

log.foodType = "粉面"

let recommendation = recommend(from: [log], filter: "粉面")

precondition(log.isReadyForAcceptance, "PO acceptance path should be complete")
precondition(log.foodType == "粉面", "Food type should be selected explicitly")
precondition(abs(log.finalRating - 4.5) < 0.001, "Final rating should average environment, service and dishes")
precondition(recommendation?.shopName == "阿婆牛肉粉", "Recommendation should return the completed log")

print("PASS: core PRD path verified")
let dishNames = log.recommendedDishes.map(\.name).joined(separator: "、")
print("shop=\(log.shopName), type=\(log.foodType), rating=\(String(format: "%.1f", log.finalRating)), dishes=\(dishNames), photos=\(log.photoCount)")
