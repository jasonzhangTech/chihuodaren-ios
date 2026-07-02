import SwiftData
import SwiftUI

struct EatDecisionView: View {
    @EnvironmentObject private var locationProvider: UserLocationProvider
    @Query(sort: \FoodLog.updatedAt, order: .reverse) private var logs: [FoodLog]
    @State private var selectedFilter = "全部"
    @State private var recommendation: FoodRecommendation?
    @State private var didEnter = false

    private var filters: [String] {
        let foodTypes = logs
            .filter { !$0.isPitfall && $0.status != .draft }
            .map(\.foodType)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let sourcedFilters = Array(Set(foodTypes)).sorted()
        return ["全部"] + sourcedFilters
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("今天吃啥")
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(Color.ink)

                VStack(alignment: .leading, spacing: 16) {
                    filterBar

                    Button {
                        withAnimation(FoodMotion.card) {
                            recommendation = RecommendationService.recommend(
                                from: logs,
                                filter: selectedFilter
                            )
                        }
                    } label: {
                        Label("给我推荐", systemImage: "sparkles")
                            .font(.headline.weight(.black))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.tomato)
                    .sensoryFeedback(.impact(weight: .medium), trigger: recommendation?.log.id)
                }
                .padding(14)
                .ticketSurface()

                if let currentRecommendation = recommendation {
                    NavigationLink {
                        LogDetailView(log: currentRecommendation.log)
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            FoodLogCard(log: currentRecommendation.log, distanceText: locationProvider.distanceText(to: currentRecommendation.log))
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(Color.tomato)
                                Text(currentRecommendation.reason)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.ink.opacity(0.74))
                            }
                            .padding(12)
                            .background(Color.scallionSoft.opacity(0.72))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                    .buttonStyle(CardPressButtonStyle())
                    .id(currentRecommendation.log.id)
                    .transition(FoodMotion.cardInsertion)

                    Button {
                        withAnimation(FoodMotion.card) {
                            recommendation = randomAlternative()
                        }
                    } label: {
                        Label("换一个", systemImage: "shuffle")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.tomato)
                    }
                    .buttonStyle(PressScaleButtonStyle())
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.tomato)
                        Text("还没有匹配记录")
                            .font(.headline.weight(.black))
                            .foregroundStyle(Color.ink)
                        Text("多记几家推荐店后，这里会按评分和类型帮你挑。")
                            .font(.body)
                            .foregroundStyle(Color.ink.opacity(0.55))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 64)
                }
            }
            .padding(16)
            .opacity(didEnter ? 1 : 0)
            .offset(y: didEnter ? 0 : 10)
        }
        .background(Color.paper)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            locationProvider.refresh()
            resetMissingFilter()
            withAnimation(FoodMotion.gentle) {
                didEnter = true
            }
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
                        withAnimation(FoodMotion.quick) {
                            selectedFilter = filter
                            recommendation = nil
                        }
                    } label: {
                        Text(filter)
                            .font(.subheadline.weight(.bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedFilter == filter ? Color.tomato : Color.chiliSoft.opacity(0.45))
                            .foregroundStyle(selectedFilter == filter ? .white : Color.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(PressScaleButtonStyle())
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
            default:
                filterMatches = log.foodType == selectedFilter
            }
            return filterMatches && log.status != .draft && !log.isPitfall
        }

        guard let next = matches.shuffled().first else { return nil }
        return FoodRecommendation(log: next, reason: RecommendationService.alternativeReason(for: next))
    }

    private func resetMissingFilter() {
        if !filters.contains(selectedFilter) {
            selectedFilter = "全部"
            recommendation = nil
        }
    }
}
