import SwiftData
import SwiftUI

struct EatDecisionView: View {
    @Query(sort: \FoodLog.updatedAt, order: .reverse) private var logs: [FoodLog]
    @State private var selectedType = "不限"
    @State private var selectedScene = "不限"
    @State private var excludesPitfalls = true
    @State private var recommendation: FoodRecommendation?

    private let types = ["不限", "粉面", "烧烤", "火锅", "咖啡", "甜品", "小吃", "正餐"]
    private let scenes = ["不限", "独食", "朋友聚餐", "夜宵", "约会", "下午茶"]

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
                    Picker("类型", selection: $selectedType) {
                        ForEach(types, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("场景", selection: $selectedScene) {
                        ForEach(scenes, id: \.self) { scene in
                            Text(scene).tag(scene)
                        }
                    }
                    .pickerStyle(.menu)

                    Toggle("排除踩雷", isOn: $excludesPitfalls)

                    Button {
                        recommendation = RecommendationService.recommend(
                            from: logs,
                            type: selectedType,
                            scene: selectedScene,
                            excludesPitfalls: excludesPitfalls
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
                            FoodLogCard(log: currentRecommendation.log)
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
                        Text("多记几家后，这里会按评分、再去意愿和标签帮你挑。")
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
    }

    private func randomAlternative() -> FoodRecommendation? {
        let matches = logs.filter { log in
            let typeMatches = selectedType == "不限" || log.foodType == selectedType || log.tags.contains(selectedType)
            let sceneMatches = selectedScene == "不限" || log.tags.contains(selectedScene)
            let pitfallMatches = !excludesPitfalls || !log.isPitfall
            return typeMatches && sceneMatches && pitfallMatches && log.status != .draft
        }

        guard let next = matches.shuffled().first else { return nil }
        return FoodRecommendation(log: next, reason: "换了一个符合条件的本地记录")
    }
}
