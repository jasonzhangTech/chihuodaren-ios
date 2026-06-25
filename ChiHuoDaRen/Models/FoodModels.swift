import Foundation
import SwiftData

enum LogStatus: String, Codable, CaseIterable {
    case draft
    case saved
    case generating
    case generated
    case failed
}

enum AIStatus: String, Codable, CaseIterable {
    case pending
    case generating
    case generated
    case failed
    case edited
}

@Model
final class Dish {
    var id: UUID
    var name: String
    var source: String
    var rank: Int
    var note: String

    init(name: String, source: String = "manual", rank: Int = 0, note: String = "") {
        self.id = UUID()
        self.name = name
        self.source = source
        self.rank = rank
        self.note = note
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
    var rating: Double
    var environmentRating: Double = 0
    var serviceRating: Double = 0
    var dishRating: Double = 0
    @Relationship(deleteRule: .cascade) var recommendedDishes: [Dish]
    @Relationship(deleteRule: .cascade) var photos: [FoodPhoto]
    var aiTitle: String
    var aiBody: String
    var aiStatusRaw: String
    var tags: [String]
    var isPitfall: Bool
    var district: String
    var address: String
    var latitude: Double?
    var longitude: Double?

    init(
        shopName: String = "",
        foodType: String = "",
        rating: Double = 0,
        recommendedDishes: [Dish] = [],
        photos: [FoodPhoto] = []
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.statusRaw = LogStatus.draft.rawValue
        self.shopName = shopName
        self.foodType = foodType
        self.rating = rating
        self.environmentRating = 0
        self.serviceRating = 0
        self.dishRating = rating
        self.recommendedDishes = recommendedDishes
        self.photos = photos
        self.aiTitle = ""
        self.aiBody = ""
        self.aiStatusRaw = AIStatus.pending.rawValue
        self.tags = []
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

    var aiStatus: AIStatus {
        get { AIStatus(rawValue: aiStatusRaw) ?? .pending }
        set { aiStatusRaw = newValue.rawValue }
    }

    var finalRating: Double {
        let parts = [environmentRating, serviceRating, dishRating].filter { $0 > 0 }
        guard !parts.isEmpty else { return rating }
        return parts.reduce(0, +) / Double(parts.count)
    }

    var coverPhoto: FoodPhoto? {
        photos.first(where: \.isCover) ?? photos.first
    }

    var displayAddress: String {
        address.isEmpty ? (district.isEmpty ? "未填写地址" : district) : address
    }

    var isReadyForPOAcceptance: Bool {
        !shopName.isEmpty &&
        !foodType.isEmpty &&
        finalRating > 0 &&
        !recommendedDishes.isEmpty &&
        !photos.isEmpty &&
        !aiBody.isEmpty
    }
}
