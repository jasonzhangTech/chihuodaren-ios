import Foundation

struct ShopSuggestion {
    let rating: Double
    let ratingSource: RatingSource
    let dishes: [String]
    let foodType: String
    let district: String
    let address: String
    let latitude: Double?
    let longitude: Double?
    let tags: [String]
}

enum AutoFillService {
    static func suggest(for shopName: String, foodType: String) async -> ShopSuggestion {
        try? await Task.sleep(for: .milliseconds(550))

        let normalized = "\(shopName) \(foodType)"
        if normalized.contains("粉") || normalized.contains("面") {
            return ShopSuggestion(
                rating: 4.7,
                ratingSource: .mixed,
                dishes: ["招牌牛肉粉", "卤蛋", "酸萝卜"],
                foodType: "粉面",
                district: "老城小巷",
                address: "老城小巷 18 号",
                latitude: 31.2304,
                longitude: 121.4737,
                tags: ["独食", "夜宵", "锅气足"]
            )
        }

        if normalized.contains("烧烤") || normalized.contains("串") {
            return ShopSuggestion(
                rating: 4.6,
                ratingSource: .mixed,
                dishes: ["烤牛油", "掌中宝", "烤茄子"],
                foodType: "烧烤",
                district: "河边夜市",
                address: "河边夜市 B 区 09 号",
                latitude: 31.2396,
                longitude: 121.4998,
                tags: ["朋友聚餐", "夜宵", "重口"]
            )
        }

        if normalized.contains("甜") || normalized.contains("咖啡") {
            return ShopSuggestion(
                rating: 4.5,
                ratingSource: .amap,
                dishes: ["拿铁", "巴斯克蛋糕", "季节特调"],
                foodType: normalized.contains("甜") ? "甜品" : "咖啡",
                district: "梧桐街区",
                address: "梧桐街区 32 号",
                latitude: 31.2133,
                longitude: 121.4454,
                tags: ["下午茶", "约会", "轻食"]
            )
        }

        return ShopSuggestion(
            rating: 4.4,
            ratingSource: .mixed,
            dishes: ["店员推荐", "招牌菜", "当日小食"],
            foodType: "小吃",
            district: "附近街区",
            address: "附近街区",
            latitude: nil,
            longitude: nil,
            tags: ["探店", "可再试"]
        )
    }
}
