import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct LogDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var locationProvider: UserLocationProvider
    @Bindable var log: FoodLog
    @State private var showingEditor = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                GeometryReader { proxy in
                    PhotoMosaicView(
                        photos: log.photos,
                        height: PhotoMosaicView.requiredHeight(
                            forPhotoCount: log.photos.count,
                            width: proxy.size.width
                        ),
                        fillsWidth: true
                    )
                }
                .frame(
                    height: PhotoMosaicView.requiredHeight(
                        forPhotoCount: log.photos.count,
                        width: detailContentWidth
                    )
                )

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.shopName)
                                .font(.largeTitle.weight(.black))
                                .foregroundStyle(Color.ink)
                            Text("类型：\(log.foodType) · \(locationProvider.distanceText(to: log))")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.ink.opacity(0.58))
                        }
                        Spacer()
                        RatingBadge(value: log.finalRating)
                    }

                    FlowLayout(items: log.recommendedDishes.sorted { $0.rank < $1.rank }.map(\.name))

                    HStack {
                        if log.isPitfall {
                            StatusPill(text: "踩雷", systemImage: "hand.thumbsdown", color: .leaf)
                        } else {
                            StatusPill(text: "推荐", systemImage: "hand.thumbsup", color: .tomato)
                        }
                    }
                }
                .padding(14)
                .ticketSurface()

                if hasNavigationTarget {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("位置")
                            .font(.headline.weight(.black))
                            .foregroundStyle(Color.ink)
                        Text(log.displayAddress)
                            .foregroundStyle(Color.ink.opacity(0.62))
                        Button {
                            openNavigation()
                        } label: {
                            Label("导航去这里", systemImage: "map")
                                .font(.headline.weight(.bold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.tomato)
                    }
                    .padding(14)
                    .ticketSurface()
                }
            }
            .padding(16)
            .padding(.bottom, 110)
        }
        .background(Color.paper)
        .tint(.tomato)
        .navigationTitle("详情")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            locationProvider.refresh()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("删除", role: .destructive) {
                    modelContext.delete(log)
                    try? modelContext.save()
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("编辑") {
                    showingEditor = true
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            NavigationStack {
                LogEditorView(log: log)
            }
        }
    }

    private var detailContentWidth: CGFloat {
        #if canImport(UIKit)
        max(1, UIScreen.main.bounds.width - 32)
        #else
        361
        #endif
    }

    private var hasNavigationTarget: Bool {
        log.latitude != nil || !log.address.isEmpty || !log.district.isEmpty
    }

    private func openNavigation() {
        var components = URLComponents(string: "http://maps.apple.com/")!
        if let latitude = log.latitude, let longitude = log.longitude {
            components.queryItems = [
                URLQueryItem(name: "daddr", value: "\(latitude),\(longitude)"),
                URLQueryItem(name: "q", value: log.shopName)
            ]
        } else {
            let destination = [log.shopName, log.displayAddress]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            components.queryItems = [
                URLQueryItem(name: "daddr", value: destination),
                URLQueryItem(name: "q", value: log.shopName)
            ]
        }

        guard let url = components.url else { return }
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #endif
    }
}

struct FlowLayout: View {
    let items: [String]

    var body: some View {
        HStack {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.scallionSoft)
                    .foregroundStyle(Color.leaf)
                    .clipShape(Capsule())
            }
        }
    }
}
