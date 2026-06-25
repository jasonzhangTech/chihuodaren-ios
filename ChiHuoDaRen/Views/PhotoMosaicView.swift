import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct PhotoMosaicView: View {
    let imageData: [Data]
    let height: CGFloat
    var maxPhotos: Int = 9
    var showsOverflowCount: Bool = true

    init(photos: [FoodPhoto], height: CGFloat, maxPhotos: Int = 9, showsOverflowCount: Bool = true) {
        self.imageData = photos.map(\.imageData)
        self.height = height
        self.maxPhotos = maxPhotos
        self.showsOverflowCount = showsOverflowCount
    }

    init(imageData: [Data], height: CGFloat, maxPhotos: Int = 9, showsOverflowCount: Bool = true) {
        self.imageData = imageData
        self.height = height
        self.maxPhotos = maxPhotos
        self.showsOverflowCount = showsOverflowCount
    }

    var body: some View {
        GeometryReader { proxy in
            Group {
                if imageData.isEmpty {
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
                } else if imageData.count == 1 {
                    photoImage(imageData[0])
                } else {
                    let displayPhotos = Array(imageData.prefix(maxPhotos))
                    let columns = gridColumns(for: displayPhotos.count)
                    let rows = Int(ceil(Double(displayPhotos.count) / Double(columns)))
                    let spacing: CGFloat = 4
                    let itemWidth = (proxy.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
                    let itemHeight = (proxy.size.height - spacing * CGFloat(rows - 1)) / CGFloat(rows)
                    let itemSize = max(1, min(itemWidth, itemHeight))

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
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func gridColumns(for count: Int) -> Int {
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
