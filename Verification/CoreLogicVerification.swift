import Foundation

enum RevisitIntent: String {
    case yes
    case maybe
    case no
}

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
    var voiceNoteText: String
    var aiTitle: String
    var aiBody: String
    var tags: [String]
    var revisitIntent: RevisitIntent
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

struct ShopSuggestion {
    let dishes: [String]
    let foodType: String
    let district: String
    let tags: [String]
}

func inferFoodType(from text: String) -> String {
    if text.contains("粉") || text.contains("面") { return "粉面" }
    if text.contains("烧烤") || text.contains("串") { return "烧烤" }
    if text.contains("火锅") { return "火锅" }
    if text.contains("咖啡") { return "咖啡" }
    if text.contains("甜") || text.contains("蛋糕") { return "甜品" }
    return "小吃"
}

func suggest(shopName: String, foodType: String) -> ShopSuggestion {
    let normalized = "\(shopName) \(foodType)"
    if normalized.contains("粉") || normalized.contains("面") {
        return ShopSuggestion(
            dishes: ["招牌牛肉粉", "卤蛋", "酸萝卜"],
            foodType: "粉面",
            district: "老城小巷",
            tags: ["独食", "夜宵", "锅气足"]
        )
    }

    return ShopSuggestion(
        dishes: ["店员推荐", "招牌菜", "当日小食"],
        foodType: "小吃",
        district: "附近街区",
        tags: ["探店", "可再试"]
    )
}

func generateAI(for log: FoodLog) -> (title: String, body: String) {
    let dishText = log.recommendedDishes
        .sorted { $0.rank < $1.rank }
        .map(\.name)
        .prefix(3)
        .joined(separator: "、")
    let title = "\(log.shopName)再吃备忘"
    let body = "\(log.district)的\(log.shopName)可以记进\(log.foodType)清单。推荐先点\(dishText)，综合评分 \(String(format: "%.1f", log.finalRating))。\(log.voiceNoteText)适合下次不知道吃什么时回来兜底。"

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
            let left = lhs.finalRating + (lhs.revisitIntent == .yes ? 1.2 : 0) - (lhs.isPitfall ? 2.0 : 0)
            let right = rhs.finalRating + (rhs.revisitIntent == .yes ? 1.2 : 0) - (rhs.isPitfall ? 2.0 : 0)
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
    recommendedDishes: [],
    photoCount: 1,
    voiceNoteText: "汤底清爽，辣油后劲明显。",
    aiTitle: "",
    aiBody: "",
    tags: [],
    revisitIntent: .yes,
    isPitfall: false,
    district: ""
)

log.foodType = inferFoodType(from: log.shopName)
log.rating = log.finalRating

let suggestion = suggest(shopName: log.shopName, foodType: log.foodType)
log.recommendedDishes = suggestion.dishes.enumerated().map { Dish(name: $0.element, rank: $0.offset) }
log.district = suggestion.district
log.tags = suggestion.tags

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
