import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct FoodLogCard: View {
    let log: FoodLog
    let distanceText: String
    @State private var didAppear = false

    var body: some View {
        HStack(spacing: 0) {
            ReceiptEdge()
                .frame(width: 10)

            VStack(alignment: .leading, spacing: 0) {
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

                VStack(alignment: .leading, spacing: 11) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(log.shopName.isEmpty ? "未命名小店" : log.shopName)
                                .font(.system(size: 24, weight: .black, design: .default))
                                .foregroundStyle(Color.ink)
                                .lineLimit(1)
                            Text(Self.dateFormatter.string(from: log.createdAt))
                                .font(.caption.monospacedDigit().weight(.medium))
                                .foregroundStyle(Color.soy.opacity(0.72))
                                .lineLimit(1)
                            Text("\(log.foodType.isEmpty ? "未分类" : log.foodType) · \(distanceText)")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.ink.opacity(0.55))
                                .lineLimit(1)
                        }
                        Spacer()
                        RatingBadge(value: log.finalRating)
                    }

                    if !log.recommendedDishes.isEmpty {
                        HStack(spacing: 7) {
                            ForEach(log.recommendedDishes.sorted { $0.rank < $1.rank }.prefix(3)) { dish in
                                Text(dish.name)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 6)
                                    .background(Color.scallionSoft)
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
                .padding(.vertical, 14)
            }
        }
        .background(Color.ticket)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.riceLine.opacity(0.24), lineWidth: 1)
        }
        .shadow(color: Color.soy.opacity(0.12), radius: 18, x: 0, y: 8)
        .opacity(didAppear ? 1 : 0)
        .offset(y: didAppear ? 0 : 8)
        .onAppear {
            withAnimation(FoodMotion.card) {
                didAppear = true
            }
        }
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
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .labelStyle(.titleAndIcon)
    }
}

private struct ReceiptEdge: View {
    var body: some View {
        Rectangle()
            .fill(Color.tomato)
            .overlay {
                VStack(spacing: 12) {
                    ForEach(0..<28, id: \.self) { _ in
                        Circle()
                            .fill(Color.paper)
                            .frame(width: 5, height: 5)
                    }
                }
                .padding(.vertical, 8)
            }
            .clipped()
    }
}
