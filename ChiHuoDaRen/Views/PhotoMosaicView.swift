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
                Grid(horizontalSpacing: 3, verticalSpacing: 3) {
                    GridRow {
                        photoImage(photos[0])
                            .gridCellColumns(photos.count == 2 ? 1 : 2)
                        if photos.count == 2 {
                            photoImage(photos[1])
                        }
                    }
                    if photos.count > 2 {
                        GridRow {
                            ForEach(photos.dropFirst().prefix(3)) { photo in
                                photoImage(photo)
                            }
                        }
                    }
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
