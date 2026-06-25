import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct PhotoMosaicView: View {
    let photos: [FoodPhoto]
    let height: CGFloat

    var body: some View {
        GeometryReader { proxy in
            Group {
                if photos.isEmpty {
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
                } else if photos.count == 1 {
                    photoImage(photos[0])
                } else {
                    let displayPhotos = Array(photos.prefix(9))
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
                        ForEach(Array(displayPhotos.enumerated()), id: \.element.id) { index, photo in
                            ZStack(alignment: .bottomTrailing) {
                                photoImage(photo)
                                    .frame(width: itemSize, height: itemSize)
                                    .clipped()
                                if index == 8 && photos.count > 9 {
                                    Text("+\(photos.count - 9)")
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
    private func photoImage(_ photo: FoodPhoto) -> some View {
        #if canImport(UIKit)
        if let uiImage = UIImage(data: photo.imageData) {
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
        if let nsImage = NSImage(data: photo.imageData) {
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
