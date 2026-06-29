import SwiftData
import SwiftUI

struct LogListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var locationProvider: UserLocationProvider
    @Query(sort: \FoodLog.updatedAt, order: .reverse) private var logs: [FoodLog]
    @State private var searchText = ""
    @State private var selectedFilter = "全部"
    @State private var selectedDate: Date?
    @State private var showingNewLog = false

    private let calendar = Calendar(identifier: .gregorian)

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

            let dateMatches = selectedDate.map { calendar.isDate(log.createdAt, inSameDayAs: $0) } ?? true

            return queryMatches && filterMatches && dateMatches
        }
        .sorted {
            if $0.createdAt == $1.createdAt {
                return $0.updatedAt > $1.updatedAt
            }
            return $0.createdAt > $1.createdAt
        }
    }

    private var timelineDates: [Date] {
        let startsOfDay = logs
            .filter { $0.status != .draft }
            .map { calendar.startOfDay(for: $0.createdAt) }
        return Array(Set(startsOfDay)).sorted(by: >)
    }

    private var groupedLogs: [(day: Date, logs: [FoodLog])] {
        let groups = Dictionary(grouping: filteredLogs) { log in
            calendar.startOfDay(for: log.createdAt)
        }
        return groups
            .map { (day: $0.key, logs: $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.paper.ignoresSafeArea()

            ScrollViewReader { reader in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        draftBanner
                        filterBar

                        if filteredLogs.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: 18) {
                                ForEach(groupedLogs, id: \.day) { group in
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(Self.sectionDateFormatter.string(from: group.day))
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(Color.ink)
                                            .id(dateID(for: group.day))

                                        ForEach(group.logs) { log in
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
                        }
                    }
                    .padding(16)
                    .padding(.trailing, timelineDates.isEmpty ? 0 : 46)
                    .padding(.bottom, 72)
                }
                .searchable(text: $searchText, prompt: "搜店名、菜名、口味")
                .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
                .navigationTitle("吃货达人")
                .overlay(alignment: .trailing) {
                    timelineRail(reader: reader)
                }
            }

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
                if selectedDate != nil {
                    Button {
                        selectedDate = nil
                    } label: {
                        Label("全部日期", systemImage: "xmark")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.tomato)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }

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

    private func timelineRail(reader: ScrollViewProxy) -> some View {
        VStack(spacing: 8) {
            if selectedDate != nil {
                Button {
                    selectedDate = nil
                } label: {
                    Image(systemName: "calendar.badge.minus")
                        .font(.caption.weight(.semibold))
                        .frame(width: 38, height: 34)
                }
                .background(.white)
                .foregroundStyle(Color.tomato)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
            }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 7) {
                    ForEach(Array(timelineDates.enumerated()), id: \.element) { index, date in
                        if shouldShowYearHeader(at: index) {
                            timelineYearHeader(for: date)
                        }

                        Button {
                            selectedDate = date
                            DispatchQueue.main.async {
                                withAnimation(.snappy) {
                                    reader.scrollTo(dateID(for: date), anchor: .top)
                                }
                            }
                        } label: {
                            VStack(spacing: 1) {
                                Text(Self.timelineMonthFormatter.string(from: date))
                                    .font(.system(size: 9, weight: .semibold))
                                Text(Self.timelineDayFormatter.string(from: date))
                                    .font(.system(size: 13, weight: .bold).monospacedDigit())
                            }
                            .frame(width: 38, height: 38)
                            .background(isSelected(date) ? Color.tomato : .white)
                            .foregroundStyle(isSelected(date) ? .white : Color.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 430)
        }
        .padding(.trailing, 8)
        .padding(.top, 118)
    }

    private func timelineYearHeader(for date: Date) -> some View {
        Text(Self.timelineYearFormatter.string(from: date))
            .font(.system(size: 10, weight: .bold).monospacedDigit())
            .foregroundStyle(Color.tomato)
            .frame(width: 38, height: 18)
            .background(.white.opacity(0.9))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
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

    private func isSelected(_ date: Date) -> Bool {
        selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
    }

    private func dateID(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "date-\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    private func shouldShowYearHeader(at index: Int) -> Bool {
        guard timelineDates.indices.contains(index) else { return false }
        if index == timelineDates.startIndex { return true }
        return !calendar.isDate(timelineDates[index], equalTo: timelineDates[index - 1], toGranularity: .year)
    }

    private static let timelineMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "M月"
        return formatter
    }()

    private static let timelineYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy"
        return formatter
    }()

    private static let timelineDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "d"
        return formatter
    }()

    private static let sectionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()
}
