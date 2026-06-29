import Foundation
import SwiftData

enum MockDataSeeder {
    private static let shopPrefix = "时间轴验证"

    static func seedTimelineDataIfRequested(in context: ModelContext) {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--clear-timeline-mock-data") {
            clearTimelineData(in: context)
            return
        }
        guard ProcessInfo.processInfo.arguments.contains("--seed-timeline-mock-data") else { return }
        seedTimelineData(in: context)
        #endif
    }

    private static func clearTimelineData(in context: ModelContext) {
        let descriptor = FetchDescriptor<FoodLog>(
            predicate: #Predicate { log in
                log.shopName.localizedStandardContains(shopPrefix)
            }
        )

        guard let logs = try? context.fetch(descriptor) else { return }
        for log in logs {
            context.delete(log)
        }
        try? context.save()
    }

    private static func seedTimelineData(in context: ModelContext) {
        let descriptor = FetchDescriptor<FoodLog>(
            predicate: #Predicate { log in
                log.shopName.localizedStandardContains(shopPrefix)
            }
        )
        let existingNames = Set((try? context.fetch(descriptor).map(\.shopName)) ?? [])

        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        let samples: [(date: Date, name: String, type: String, dishes: [String], pitfall: Bool, ratings: (Double, Double, Double), address: String)] = [
            (date(daysAgo: 0, hour: 12, minute: 10, calendar: calendar, now: now), "时间轴验证 今日牛肉面", "粉面", ["红烧牛肉", "溏心蛋", "酸豆角"], false, (4.5, 4.0, 4.5), "上海市黄浦区南京东路"),
            (date(daysAgo: 1, hour: 21, minute: 35, calendar: calendar, now: now), "时间轴验证 昨夜烧烤", "烧烤", ["烤鸡翅", "烤茄子", "烤年糕"], false, (4.0, 4.0, 4.5), "上海市静安区愚园路"),
            (date(daysAgo: 3, hour: 15, minute: 20, calendar: calendar, now: now), "时间轴验证 午后咖啡", "咖啡", ["拿铁", "巴斯克", "冷萃"], false, (4.5, 4.5, 4.0), "上海市徐汇区武康路"),
            (date(daysAgo: 6, hour: 19, minute: 5, calendar: calendar, now: now), "时间轴验证 周末火锅", "火锅", ["毛肚", "鸭血", "虾滑"], false, (4.5, 4.0, 5.0), "上海市长宁区定西路"),
            (date(daysAgo: 12, hour: 18, minute: 45, calendar: calendar, now: now), "时间轴验证 小吃踩雷", "小吃", ["炸串", "臭豆腐"], true, (2.5, 2.0, 2.0), "上海市普陀区长寿路"),
            (date(daysAgo: 21, hour: 13, minute: 0, calendar: calendar, now: now), "时间轴验证 正餐小馆", "正餐", ["葱油鸡", "清炒时蔬", "例汤"], false, (4.0, 4.5, 4.0), "上海市浦东新区世纪大道"),
            (date(daysAgo: 35, hour: 20, minute: 25, calendar: calendar, now: now), "时间轴验证 烤肉聚餐", "烤肉", ["厚切五花", "牛肋条", "石锅拌饭"], false, (4.0, 4.0, 4.5), "上海市虹口区四川北路"),
            (date(daysAgo: 59, hour: 16, minute: 30, calendar: calendar, now: now), "时间轴验证 甜品店", "甜品", ["提拉米苏", "泡芙", "柠檬塔"], false, (4.5, 4.0, 4.0), "上海市杨浦区大学路"),
            (date(year: 2025, month: 12, day: 31, hour: 23, minute: 20, calendar: calendar, fallback: now), "时间轴验证 跨年夜火锅", "火锅", ["九宫格锅底", "毛肚", "酥肉"], false, (4.5, 4.5, 5.0), "上海市黄浦区外滩"),
            (date(year: 2025, month: 11, day: 15, hour: 14, minute: 10, calendar: calendar, fallback: now), "时间轴验证 深秋咖啡", "咖啡", ["澳白", "肉桂卷", "手冲"], false, (4.0, 4.5, 4.0), "上海市徐汇区安福路"),
            (date(year: 2024, month: 12, day: 30, hour: 18, minute: 40, calendar: calendar, fallback: now), "时间轴验证 去年烧烤", "烧烤", ["羊肉串", "烤馕", "烤包子"], false, (4.0, 3.5, 4.5), "上海市闵行区虹泉路"),
            (date(year: 2023, month: 2, day: 5, hour: 11, minute: 50, calendar: calendar, fallback: now), "时间轴验证 旧年小吃", "小吃", ["生煎", "小馄饨", "葱油饼"], false, (3.5, 4.0, 4.0), "上海市静安区南京西路")
        ]

        for sample in samples {
            guard !existingNames.contains(sample.name) else { continue }

            let log = FoodLog(shopName: sample.name, foodType: sample.type)
            log.createdAt = sample.date
            log.updatedAt = sample.date
            log.status = .saved
            log.environmentRating = sample.ratings.0
            log.serviceRating = sample.ratings.1
            log.dishRating = sample.ratings.2
            log.address = sample.address
            log.district = "上海市"
            log.latitude = 31.2304
            log.longitude = 121.4737
            log.isPitfall = sample.pitfall

            for (index, dish) in sample.dishes.enumerated() {
                log.recommendedDishes.append(Dish(name: dish, rank: index))
            }

            context.insert(log)
        }

        try? context.save()
    }

    private static func date(daysAgo: Int, hour: Int, minute: Int, calendar: Calendar, now: Date) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? now
    }

    private static func date(year: Int, month: Int, day: Int, hour: Int, minute: Int, calendar: Calendar, fallback: Date) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? fallback
    }
}
