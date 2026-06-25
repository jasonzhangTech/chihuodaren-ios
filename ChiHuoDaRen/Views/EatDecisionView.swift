import SwiftData
import SwiftUI

struct EatDecisionView: View {
    @EnvironmentObject private var locationProvider: UserLocationProvider
    @Query(sort: \FoodLog.updatedAt, order: .reverse) private var logs: [FoodLog]
    @State private var selectedFilter = "全部"
    @State private var recommendation: FoodRecommendation?

    private var filters: [String] {
        let foodTypes = logs
            .map(\.foodType)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let sourcedFilters = Array(Set(foodTypes)).sorted()
        return ["全部", "踩雷"] + sourcedFilters
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("今天吃啥")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.ink)
                    Text("只从你的本地日志里推荐，不够就直接告诉你。")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 16) {
                    filterBar

                    Button {
                        recommendation = RecommendationService.recommend(
                            from: logs,
                            filter: selectedFilter
                        )
                    } label: {
                        Label("给我推荐", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.tomato)
                }
                .padding(14)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if let currentRecommendation = recommendation {
                    NavigationLink {
                        LogDetailView(log: currentRecommendation.log)
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
	                            FoodLogCard(log: currentRecommendation.log, distanceText: locationProvider.distanceText(to: currentRecommendation.log))
                            Label(currentRecommendation.reason, systemImage: "lightbulb")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.leaf)
                                .padding(.horizontal, 4)
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        recommendation = randomAlternative()
                    } label: {
                        Label("换一个", systemImage: "shuffle")
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.tomato)
                        Text("还没有匹配记录")
                            .font(.headline)
                        Text("多记几家后，这里会按评分、踩雷标记和标签帮你挑。")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 64)
                }
            }
            .padding(16)
        }
	        .background(Color.paper)
	        .navigationTitle("吃啥")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            locationProvider.refresh()
            resetMissingFilter()
        }
        .onChange(of: filters) { _, _ in
            resetMissingFilter()
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { filter in
                    Button {
                        selectedFilter = filter
                        recommendation = nil
                    } label: {
                        Text(filter)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedFilter == filter ? Color.tomato : Color.secondary.opacity(0.12))
                            .foregroundStyle(selectedFilter == filter ? .white : Color.ink)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func randomAlternative() -> FoodRecommendation? {
        let matches = logs.filter { log in
            let filterMatches: Bool
            switch selectedFilter {
            case "全部":
                filterMatches = true
            case "踩雷":
                filterMatches = log.isPitfall
            default:
                filterMatches = log.foodType == selectedFilter
            }
            return filterMatches && log.status != .draft
        }

        guard let next = matches.shuffled().first else { return nil }
        return FoodRecommendation(log: next, reason: "换了一个符合条件的本地记录")
    }

    private func resetMissingFilter() {
        if !filters.contains(selectedFilter) {
            selectedFilter = "全部"
            recommendation = nil
        }
    }
}
