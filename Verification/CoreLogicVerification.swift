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
    var rating: Double
    var recommendedDishes: [Dish]
    var photoCount: Int
    var aiTitle: String
    var aiBody: String
    var tags: [String]
    var isPitfall: Bool
    var district: String

    var finalRating: Double {
        let parts = [environmentRating, serviceRating, dishRating].filter { $0 > 0 }
        guard !parts.isEmpty else { return rating }
        return parts.reduce(0, +) / Double(parts.count)
    }

    var isReadyForAcceptance: Bool {
        !shopName.isEmpty &&
        !foodType.isEmpty &&
        finalRating > 0 &&
        !recommendedDishes.isEmpty &&
        photoCount > 0 &&
        !aiBody.isEmpty
    }
}

func inferFoodType(from text: String) -> String {
    if text.contains("粉") || text.contains("面") { return "粉面" }
    if text.contains("烧烤") || text.contains("串") { return "烧烤" }
    if text.contains("火锅") { return "火锅" }
    if text.contains("咖啡") { return "咖啡" }
    if text.contains("甜") || text.contains("蛋糕") { return "甜品" }
    return "小吃"
}

func generateAI(for log: FoodLog) -> (title: String, body: String) {
    let dishText = log.recommendedDishes
        .sorted { $0.rank < $1.rank }
        .map(\.name)
        .prefix(3)
        .joined(separator: "、")
    let title = log.isPitfall ? "\(log.shopName)避雷记录" : "\(log.shopName)美食记录"
    let tail = log.isPitfall ? "这次标为踩雷，下次先避开。" : "适合下次不知道吃什么时回来兜底。"
    let body = "\(log.district)的\(log.shopName)可以记进\(log.foodType)清单。推荐先点\(dishText)，综合评分 \(String(format: "%.1f", log.finalRating))。\(tail)"

    return (String(title.prefix(18)), String(body.prefix(120)))
}

func recommend(from logs: [FoodLog], type: String, scene: String, excludesPitfalls: Bool) -> FoodLog? {
    logs
        .filter { log in
            let typeMatches = type == "不限" || log.foodType == type || log.tags.contains(type)
            let sceneMatches = scene == "不限" || log.tags.contains(scene)
            let pitfallMatches = !excludesPitfalls || !log.isPitfall
            return typeMatches && sceneMatches && pitfallMatches
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
    rating: 0,
    recommendedDishes: [
        Dish(name: "招牌牛肉粉", rank: 0),
        Dish(name: "卤蛋", rank: 1),
        Dish(name: "酸萝卜", rank: 2)
    ],
    photoCount: 1,
    aiTitle: "",
    aiBody: "",
    tags: ["独食", "夜宵"],
    isPitfall: false,
    district: "老城小巷"
)

log.foodType = inferFoodType(from: log.shopName)
log.rating = log.finalRating

let ai = generateAI(for: log)
log.aiTitle = ai.title
log.aiBody = ai.body

let recommendation = recommend(from: [log], type: "粉面", scene: "独食", excludesPitfalls: true)

precondition(log.isReadyForAcceptance, "PO acceptance path should be complete")
precondition(log.foodType == "粉面", "Food type should be inferred from shop name")
precondition(abs(log.finalRating - 4.5) < 0.001, "Final rating should average environment, service and dishes")
precondition(recommendation?.shopName == "阿婆牛肉粉", "Recommendation should return the completed log")
precondition(!log.aiBody.isEmpty && log.aiBody.count <= 120, "AI body should be generated and editable-length")

print("PASS: core PRD path verified")
let dishNames = log.recommendedDishes.map(\.name).joined(separator: "、")
print("shop=\(log.shopName), type=\(log.foodType), rating=\(String(format: "%.1f", log.finalRating)), dishes=\(dishNames), photos=\(log.photoCount)")
print("aiTitle=\(log.aiTitle)")
print("aiBody=\(log.aiBody)")
