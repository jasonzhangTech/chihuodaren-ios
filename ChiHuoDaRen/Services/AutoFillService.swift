import Foundation

struct ShopSuggestion {
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
        if let remoteSuggestion = await ShopNetworkService.fetchSuggestion(shopName: shopName, foodType: foodType) {
            return remoteSuggestion
        }

        return await fallbackSuggestion(for: shopName, foodType: foodType)
    }

    private static func fallbackSuggestion(for shopName: String, foodType: String) async -> ShopSuggestion {
        try? await Task.sleep(for: .milliseconds(550))

        let normalized = "\(shopName) \(foodType)"
        if normalized.contains("粉") || normalized.contains("面") {
            return ShopSuggestion(
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

private enum ShopNetworkService {
    static func fetchSuggestion(shopName: String, foodType: String) async -> ShopSuggestion? {
        async let dianping = fetchDianping(shopName: shopName)
        async let amap = fetchAmap(shopName: shopName)

        let dianpingResult = await dianping
        let amapResult = await amap

        guard dianpingResult != nil || amapResult != nil else {
            return nil
        }

        return ShopSuggestion(
            dishes: dianpingResult?.dishes.isEmpty == false ? dianpingResult?.dishes ?? [] : amapResult?.dishes ?? [],
            foodType: dianpingResult?.foodType ?? amapResult?.foodType ?? foodType,
            district: dianpingResult?.district ?? amapResult?.district ?? "",
            address: dianpingResult?.address ?? amapResult?.address ?? "",
            latitude: amapResult?.latitude ?? dianpingResult?.latitude,
            longitude: amapResult?.longitude ?? dianpingResult?.longitude,
            tags: dianpingResult?.tags.isEmpty == false ? dianpingResult?.tags ?? [] : amapResult?.tags ?? []
        )
    }

    private static func fetchDianping(shopName: String) async -> RemoteShopData? {
        guard let endpoint = Bundle.main.object(forInfoDictionaryKey: "DIANPING_API_ENDPOINT") as? String,
              !endpoint.isEmpty,
              var components = URLComponents(string: endpoint) else {
            return nil
        }

        components.queryItems = (components.queryItems ?? []) + [
            URLQueryItem(name: "keyword", value: shopName)
        ]

        var request = URLRequest(url: components.url!)
        if let token = Bundle.main.object(forInfoDictionaryKey: "DIANPING_API_TOKEN") as? String, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return await fetchRemoteShopData(request: request, preferredFoodType: nil)
    }

    private static func fetchAmap(shopName: String) async -> RemoteShopData? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "AMAP_WEB_SERVICE_KEY") as? String,
              !key.isEmpty,
              var components = URLComponents(string: "https://restapi.amap.com/v5/place/text") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "key", value: key),
            URLQueryItem(name: "keywords", value: shopName),
            URLQueryItem(name: "show_fields", value: "business")
        ]

        guard let url = components.url else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(AmapPlaceResponse.self, from: data)
            guard let poi = response.pois.first else { return nil }
            let coordinate = poi.location
                .split(separator: ",")
                .compactMap { Double($0) }
            let typeParts = poi.type.components(separatedBy: ";")
            return RemoteShopData(
                dishes: [],
                foodType: typeParts.last,
                district: poi.adname,
                address: poi.addressText,
                latitude: coordinate.count == 2 ? coordinate[1] : nil,
                longitude: coordinate.count == 2 ? coordinate[0] : nil,
                tags: Array(typeParts.suffix(2))
            )
        } catch {
            return nil
        }
    }

    private static func fetchRemoteShopData(request: URLRequest, preferredFoodType: String?) async -> RemoteShopData? {
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(DianpingShopResponse.self, from: data)
            guard let shop = response.shops.first ?? response.data?.first else { return nil }
            return RemoteShopData(
                dishes: shop.recommendedDishes ?? shop.dishes ?? [],
                foodType: shop.foodType ?? preferredFoodType,
                district: shop.district,
                address: shop.address,
                latitude: shop.latitude,
                longitude: shop.longitude,
                tags: shop.tags ?? []
            )
        } catch {
            return nil
        }
    }
}

private struct RemoteShopData {
    let dishes: [String]
    let foodType: String?
    let district: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let tags: [String]
}

private struct DianpingShopResponse: Decodable {
    let shops: [DianpingShop]
    let data: [DianpingShop]?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.shops = (try? container.decode([DianpingShop].self, forKey: .shops)) ?? []
        self.data = try? container.decode([DianpingShop].self, forKey: .data)
    }

    private enum CodingKeys: String, CodingKey {
        case shops
        case data
    }
}

private struct DianpingShop: Decodable {
    let recommendedDishes: [String]?
    let dishes: [String]?
    let foodType: String?
    let district: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let tags: [String]?

    private enum CodingKeys: String, CodingKey {
        case recommendedDishes = "recommended_dishes"
        case dishes
        case foodType = "food_type"
        case district
        case address
        case latitude
        case longitude
        case tags
    }
}

private struct AmapPlaceResponse: Decodable {
    let pois: [AmapPOI]
}

private struct AmapPOI: Decodable {
    let name: String
    let type: String
    let adname: String
    let address: AmapAddress
    let location: String
    let business: AmapBusiness?

    var addressText: String {
        switch address {
        case .string(let value): value
        case .array(let values): values.joined(separator: "")
        }
    }
}

private struct AmapBusiness: Decodable {
    let rating: String?
}

private enum AmapAddress: Decodable {
    case string(String)
    case array([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else {
            self = .array((try? container.decode([String].self)) ?? [])
        }
    }
}
