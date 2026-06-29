import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct PhotoMosaicView: View {
    enum EmptyState {
        case addPhoto
        case defaultCover
    }

    let imageData: [Data]
    let height: CGFloat
    var maxPhotos: Int = 9
    var showsOverflowCount: Bool = true
    var fillsWidth: Bool = false
    var emptyState: EmptyState = .addPhoto

    init(photos: [FoodPhoto], height: CGFloat, maxPhotos: Int = 9, showsOverflowCount: Bool = true, fillsWidth: Bool = false, emptyState: EmptyState = .addPhoto) {
        self.imageData = photos.map(\.imageData)
        self.height = height
        self.maxPhotos = maxPhotos
        self.showsOverflowCount = showsOverflowCount
        self.fillsWidth = fillsWidth
        self.emptyState = emptyState
    }

    init(imageData: [Data], height: CGFloat, maxPhotos: Int = 9, showsOverflowCount: Bool = true, fillsWidth: Bool = false, emptyState: EmptyState = .addPhoto) {
        self.imageData = imageData
        self.height = height
        self.maxPhotos = maxPhotos
        self.showsOverflowCount = showsOverflowCount
        self.fillsWidth = fillsWidth
        self.emptyState = emptyState
    }

    var body: some View {
        GeometryReader { proxy in
            Group {
                if imageData.isEmpty {
                    emptyStateView
                } else if imageData.count == 1 {
                    photoImage(imageData[0])
                } else {
                    let displayPhotos = Array(imageData.prefix(maxPhotos))
                    let columns = gridColumns(for: displayPhotos.count)
                    let rows = Int(ceil(Double(displayPhotos.count) / Double(columns)))
                    let spacing: CGFloat = 4
                    let itemWidth = (proxy.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
                    let itemHeight = (proxy.size.height - spacing * CGFloat(rows - 1)) / CGFloat(rows)
                    let itemSize = max(1, fillsWidth ? itemWidth : min(itemWidth, itemHeight))

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.fixed(itemSize), spacing: spacing), count: columns),
                        alignment: .leading,
                        spacing: spacing
                    ) {
                        ForEach(Array(displayPhotos.enumerated()), id: \.offset) { index, photoData in
                            ZStack(alignment: .bottomTrailing) {
                                photoImage(photoData)
                                    .frame(width: itemSize, height: itemSize)
                                    .clipped()
                                if showsOverflowCount && index == displayPhotos.count - 1 && imageData.count > displayPhotos.count {
                                    Text("+\(imageData.count - displayPhotos.count)")
                                        .font(.headline.bold())
                                        .foregroundStyle(.white)
                                        .frame(width: itemSize, height: itemSize)
                                        .background(.black.opacity(0.38))
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
        }
        .frame(height: height)
        .compositingGroup()
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var emptyStateView: some View {
        switch emptyState {
        case .addPhoto:
            ZStack {
                Rectangle()
                    .fill(Color.tomato.opacity(0.12))
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.title)
                    Text("添加美食照片")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(Color.tomato)
            }
        case .defaultCover:
            ZStack {
                LinearGradient(
                    colors: [
                        Color.tomato.opacity(0.92),
                        Color(red: 0.96, green: 0.63, blue: 0.28),
                        Color.leaf.opacity(0.86)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(.white.opacity(0.16))
                    .frame(width: 170, height: 170)
                    .offset(x: -96, y: -58)

                Circle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 140, height: 140)
                    .offset(x: 112, y: 62)

                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
            }
        }
    }

    private func gridColumns(for count: Int) -> Int {
        Self.gridColumns(for: count)
    }

    static func requiredHeight(forPhotoCount count: Int, width: CGFloat, maxPhotos: Int = 9) -> CGFloat {
        let displayCount = min(count, maxPhotos)
        guard displayCount > 1 else { return 190 }
        let columns = gridColumns(for: displayCount)
        let rows = Int(ceil(Double(displayCount) / Double(columns)))
        let spacing: CGFloat = 4
        let itemSize = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        return itemSize * CGFloat(rows) + spacing * CGFloat(rows - 1)
    }

    private static func gridColumns(for count: Int) -> Int {
        switch count {
        case 2, 4:
            return 2
        default:
            return 3
        }
    }

    @ViewBuilder
    private func photoImage(_ data: Data) -> some View {
        #if canImport(UIKit)
        if let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
        }
        #elseif canImport(AppKit)
        if let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
        }
        #else
        Rectangle()
            .fill(Color.gray.opacity(0.2))
        #endif
    }
}
