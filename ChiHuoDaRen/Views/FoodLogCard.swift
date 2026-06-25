import SwiftUI

struct FoodLogCard: View {
    let log: FoodLog

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhotoMosaicView(photos: Array(log.photos.prefix(4)), height: 190)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(log.shopName.isEmpty ? "未命名小店" : log.shopName)
                            .font(.title3.bold())
                            .foregroundStyle(Color.ink)
                            .lineLimit(1)
                        Text("\(log.foodType.isEmpty ? "未分类" : log.foodType) · \(log.visibleLocation)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    DualRatingBadge(dianpingRating: log.dianpingRating, amapRating: log.amapRating, fallbackRating: log.rating)
                }

                if !log.recommendedDishes.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(log.recommendedDishes.sorted { $0.rank < $1.rank }.prefix(3)) { dish in
                            Text(dish.name)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color.leaf.opacity(0.12))
                                .foregroundStyle(Color.leaf)
                                .clipShape(Capsule())
                        }
                    }
                }

                Text(log.aiBody.isEmpty ? "AI 日志待生成，原始记录已保存在本地。" : log.aiBody)
                    .font(.subheadline)
                    .foregroundStyle(Color.ink.opacity(0.78))
                    .lineLimit(3)

                HStack(spacing: 8) {
                    StatusPill(text: log.revisitIntent.label, systemImage: "arrow.uturn.forward")
                    if log.isPitfall {
                        StatusPill(text: "踩雷", systemImage: "exclamationmark.triangle")
                    }
                    if log.privacyLevel != .exact {
                        StatusPill(text: "位置保护", systemImage: "lock")
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

struct DualRatingBadge: View {
    let dianpingRating: Double?
    let amapRating: Double?
    let fallbackRating: Double

    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            RatingLine(title: "点评", value: dianpingRating)
            RatingLine(title: "高德", value: amapRating)
            if dianpingRating == nil && amapRating == nil && fallbackRating > 0 {
                RatingLine(title: "手动", value: fallbackRating)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(Color.ink)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct RatingLine: View {
    let title: String
    let value: Double?

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.76))
            Text(value.map { String(format: "%.1f", $0) } ?? "--")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.white)
        }
    }
}

struct StatusPill: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption)
            .foregroundStyle(.secondary)
            .labelStyle(.titleAndIcon)
    }
}
