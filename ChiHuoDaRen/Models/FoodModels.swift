import Foundation
import SwiftData

enum LogStatus: String, Codable, CaseIterable {
    case draft
    case saved
}

@Model
final class Dish {
    var id: UUID
    var name: String
    var rank: Int

    init(name: String, rank: Int = 0) {
        self.id = UUID()
        self.name = name
        self.rank = rank
    }
}

@Model
final class FoodPhoto {
    var id: UUID
    @Attribute(.externalStorage) var imageData: Data
    var isCover: Bool
    var createdAt: Date

    init(imageData: Data, isCover: Bool = false) {
        self.id = UUID()
        self.imageData = imageData
        self.isCover = isCover
        self.createdAt = Date()
    }
}

@Model
final class FoodLog {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var statusRaw: String
    var shopName: String
    var foodType: String
    var environmentRating: Double = 0
    var serviceRating: Double = 0
    var dishRating: Double = 0
    @Relationship(deleteRule: .cascade) var recommendedDishes: [Dish]
    @Relationship(deleteRule: .cascade) var photos: [FoodPhoto]
    var isPitfall: Bool
    var district: String
    var address: String
    var latitude: Double?
    var longitude: Double?

    init(
        shopName: String = "",
        foodType: String = "",
        recommendedDishes: [Dish] = [],
        photos: [FoodPhoto] = []
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.statusRaw = LogStatus.draft.rawValue
        self.shopName = shopName
        self.foodType = foodType
        self.environmentRating = 0
        self.serviceRating = 0
        self.dishRating = 0
        self.recommendedDishes = recommendedDishes
        self.photos = photos
        self.isPitfall = false
        self.district = ""
        self.address = ""
        self.latitude = nil
        self.longitude = nil
    }

    var status: LogStatus {
        get { LogStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    var finalRating: Double {
        let parts = [environmentRating, serviceRating, dishRating].filter { $0 > 0 }
        guard !parts.isEmpty else { return 0 }
        return parts.reduce(0, +) / Double(parts.count)
    }

    var displayAddress: String {
        address.isEmpty ? (district.isEmpty ? "未填写地址" : district) : address
    }
}
