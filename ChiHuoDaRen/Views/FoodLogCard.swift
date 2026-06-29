import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct FoodLogCard: View {
    let log: FoodLog
    let distanceText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GeometryReader { proxy in
                let coverHeight = PhotoMosaicView.requiredHeight(
                    forPhotoCount: log.photos.count,
                    width: proxy.size.width,
                    maxPhotos: 6
                )

                PhotoMosaicView(
                    photos: log.photos,
                    height: coverHeight,
                    maxPhotos: 6,
                    showsOverflowCount: false,
                    fillsWidth: true,
                    emptyState: .defaultCover
                )
            }
            .frame(height: PhotoMosaicView.requiredHeight(forPhotoCount: log.photos.count, width: estimatedCardWidth, maxPhotos: 6))

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(log.shopName.isEmpty ? "未命名小店" : log.shopName)
                            .font(.title3.bold())
                            .foregroundStyle(Color.ink)
                            .lineLimit(1)
                        Text(Self.dateFormatter.string(from: log.createdAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text("\(log.foodType.isEmpty ? "未分类" : log.foodType) · \(distanceText)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    RatingBadge(value: log.finalRating)
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

                HStack(spacing: 8) {
                    if log.isPitfall {
                        StatusPill(text: "踩雷", systemImage: "hand.thumbsdown", color: .leaf)
                    } else {
                        StatusPill(text: "推荐", systemImage: "hand.thumbsup", color: .tomato)
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

    private var estimatedCardWidth: CGFloat {
        #if canImport(UIKit)
        UIScreen.main.bounds.width - 32
        #else
        360
        #endif
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter
    }()
}

struct RatingBadge: View {
    let value: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption)
                .foregroundStyle(.white)
            Text(value > 0 ? String(format: "%.1f", value) : "--")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(Color.tomato)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct StatusPill: View {
    let text: String
    let systemImage: String
    var color: Color = .secondary

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption)
            .foregroundStyle(color)
            .labelStyle(.titleAndIcon)
    }
}
