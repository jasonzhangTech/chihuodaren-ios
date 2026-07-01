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
                    .fill(Color.chiliSoft.opacity(0.58))
                VStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                        .font(.title)
                    Text("添加美食照片")
                        .font(.subheadline.weight(.black))
                }
                .foregroundStyle(Color.tomato)
            }
        case .defaultCover:
            ZStack {
                Color.ticket

                VStack(spacing: 10) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(Color.tomato)
                    Text("照片待补")
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color.ink)
                }

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.riceLine.opacity(0.48), style: StrokeStyle(lineWidth: 1, dash: [7, 7]))
                    .padding(10)
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
