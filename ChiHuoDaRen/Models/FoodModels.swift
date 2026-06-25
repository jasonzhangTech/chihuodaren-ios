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

enum RatingSource: String, Codable, CaseIterable {
    case dianping
    case amap
    case manual
    case mixed

    var label: String {
        switch self {
        case .dianping: "大众点评"
        case .amap: "高德扫街榜"
        case .manual: "手动"
        case .mixed: "自动+手动"
        }
    }
}

enum RevisitIntent: String, Codable, CaseIterable {
    case yes
    case maybe
    case no

    var label: String {
        switch self {
        case .yes: "再去"
        case .maybe: "待定"
        case .no: "不再去"
        }
    }
}

enum PrivacyLevel: String, Codable, CaseIterable {
    case hiddenExact
    case districtOnly
    case exact

    var label: String {
        switch self {
        case .hiddenExact: "隐藏精确位置"
        case .districtOnly: "仅显示街区"
        case .exact: "显示完整地址"
        }
    }
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
    var dianpingRating: Double?
    var amapRating: Double?
    var ratingSourceRaw: String
    @Relationship(deleteRule: .cascade) var recommendedDishes: [Dish]
    @Relationship(deleteRule: .cascade) var photos: [FoodPhoto]
    var voiceNoteText: String
    var userComment: String
    var aiTitle: String
    var aiBody: String
    var aiStatusRaw: String
    var tags: [String]
    var revisitIntentRaw: String
    var isPitfall: Bool
    var privacyLevelRaw: String
    var district: String
    var address: String
    var latitude: Double?
    var longitude: Double?

    init(
        shopName: String = "",
        foodType: String = "",
        rating: Double = 0,
        ratingSource: RatingSource = .manual,
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
        self.dianpingRating = ratingSource == .dianping || ratingSource == .mixed ? rating : nil
        self.amapRating = ratingSource == .amap ? rating : nil
        self.ratingSourceRaw = ratingSource.rawValue
        self.recommendedDishes = recommendedDishes
        self.photos = photos
        self.voiceNoteText = ""
        self.userComment = ""
        self.aiTitle = ""
        self.aiBody = ""
        self.aiStatusRaw = AIStatus.pending.rawValue
        self.tags = []
        self.revisitIntentRaw = RevisitIntent.maybe.rawValue
        self.isPitfall = false
        self.privacyLevelRaw = PrivacyLevel.hiddenExact.rawValue
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

    var ratingSource: RatingSource {
        get { RatingSource(rawValue: ratingSourceRaw) ?? .manual }
        set { ratingSourceRaw = newValue.rawValue }
    }

    var revisitIntent: RevisitIntent {
        get { RevisitIntent(rawValue: revisitIntentRaw) ?? .maybe }
        set { revisitIntentRaw = newValue.rawValue }
    }

    var privacyLevel: PrivacyLevel {
        get { PrivacyLevel(rawValue: privacyLevelRaw) ?? .hiddenExact }
        set { privacyLevelRaw = newValue.rawValue }
    }

    var preferredRating: Double {
        dianpingRating ?? amapRating ?? rating
    }

    var coverPhoto: FoodPhoto? {
        photos.first(where: \.isCover) ?? photos.first
    }

    var visibleLocation: String {
        switch privacyLevel {
        case .hiddenExact:
            district.isEmpty ? "位置已保护" : district
        case .districtOnly:
            district.isEmpty ? "未填写街区" : district
        case .exact:
            address.isEmpty ? (district.isEmpty ? "未填写地址" : district) : address
        }
    }

    var isReadyForPOAcceptance: Bool {
        !shopName.isEmpty &&
        !foodType.isEmpty &&
        preferredRating > 0 &&
        !recommendedDishes.isEmpty &&
        !photos.isEmpty &&
        !aiBody.isEmpty
    }
}
