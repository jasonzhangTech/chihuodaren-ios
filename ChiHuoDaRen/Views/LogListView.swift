import SwiftData
import SwiftUI

struct LogListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var locationProvider: UserLocationProvider
    @Query(sort: \FoodLog.updatedAt, order: .reverse) private var logs: [FoodLog]
    @State private var searchText = ""
    @State private var selectedFilter = "全部"
    @State private var showingNewLog = false

    private var filters: [String] {
        let foodTypes = logs
            .map(\.foodType)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let sourcedFilters = Array(Set(foodTypes)).sorted()
        return ["全部", "踩雷"] + sourcedFilters
    }

    var filteredLogs: [FoodLog] {
        logs.filter { log in
            let queryMatches = searchText.isEmpty ||
                log.shopName.localizedStandardContains(searchText) ||
                log.foodType.localizedStandardContains(searchText) ||
                log.recommendedDishes.contains { $0.name.localizedStandardContains(searchText) }

            let filterMatches: Bool
            switch selectedFilter {
            case "全部":
                filterMatches = true
            case "踩雷":
                filterMatches = log.isPitfall
            default:
                filterMatches = log.foodType == selectedFilter
            }

            return queryMatches && filterMatches
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    draftBanner
                    filterBar

                    if filteredLogs.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 14) {
	                            ForEach(filteredLogs) { log in
	                                NavigationLink {
	                                    LogDetailView(log: log)
	                                } label: {
	                                    FoodLogCard(log: log, distanceText: locationProvider.distanceText(to: log))
	                                }
	                                .buttonStyle(.plain)
	                            }
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 72)
            }
            .searchable(text: $searchText, prompt: "搜店名、菜名、口味")
            .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
            .navigationTitle("吃货达人")

            Button {
                showingNewLog = true
            } label: {
                Label("新建", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(Color.tomato)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
            }
            .padding(20)
        }
        .sheet(isPresented: $showingNewLog) {
            NavigationStack {
                LogEditorView(log: nil)
            }
        }
        .onAppear {
            locationProvider.refresh()
            resetMissingFilter()
        }
        .onChange(of: filters) { _, _ in
            resetMissingFilter()
        }
    }

    @ViewBuilder
    private var draftBanner: some View {
        if let draft = logs.first(where: { $0.status == .draft }) {
            NavigationLink {
                LogEditorView(log: draft)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "tray.and.arrow.down")
                        .foregroundStyle(Color.tomato)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("有一条草稿待完成")
                            .font(.headline)
                            .foregroundStyle(Color.ink)
                        Text(draft.shopName.isEmpty ? "继续补上店名和照片" : draft.shopName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedFilter == filter ? Color.tomato : .white)
                            .foregroundStyle(selectedFilter == filter ? .white : Color.ink)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 44))
                .foregroundStyle(Color.tomato)
            Text("把第一家小店记下来")
                .font(.title3.bold())
            Text("照片、店名、评分和推荐菜先保存，之后回看更省心。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
        .padding(.horizontal, 24)
    }

    private func resetMissingFilter() {
        if !filters.contains(selectedFilter) {
            selectedFilter = "全部"
        }
    }
}
