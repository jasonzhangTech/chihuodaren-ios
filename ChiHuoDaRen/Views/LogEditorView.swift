import PhotosUI
import SwiftData
import SwiftUI

struct LogEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let existingLog: FoodLog?
    @State private var log: FoodLog?
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var shopName = ""
    @State private var foodType = "自动识别"
    @State private var rating = 0.0
    @State private var dishText = ""
    @State private var voiceNoteText = ""
    @State private var userComment = ""
    @State private var revisitIntent = RevisitIntent.maybe
    @State private var isPitfall = false
    @State private var isAutoFilling = false
    @State private var isGenerating = false
    @State private var errorMessage: String?

    private let foodTypes = ["自动识别", "粉面", "烧烤", "火锅", "咖啡", "甜品", "小吃", "正餐", "其他"]

    init(log: FoodLog?) {
        self.existingLog = log
    }

    var body: some View {
        Form {
            Section {
                if let log {
                    PhotoMosaicView(photos: log.photos, height: 210)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } else {
                    PhotoMosaicView(photos: [], height: 210)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                PhotosPicker(selection: $selectedItems, maxSelectionCount: 6, matching: .images) {
                    Label("添加照片", systemImage: "photo.badge.plus")
                }
            }

            Section("店铺") {
                TextField("店名，其他信息可自动补", text: $shopName)
                    .textInputAutocapitalization(.never)
                    .onSubmit { autofill() }

                Picker("美食类型", selection: $foodType) {
                    ForEach(foodTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }

                HStack {
                    Text("评分")
                    Slider(value: $rating, in: 0...5, step: 0.1)
                    Text(rating > 0 ? String(format: "%.1f", rating) : "--")
                        .font(.body.monospacedDigit())
                        .frame(width: 42, alignment: .trailing)
                }

                TextField("推荐菜，自动补齐后可改", text: $dishText)

                Button {
                    autofill()
                } label: {
                    Label(isAutoFilling ? "正在补全" : "自动带入评分和推荐菜", systemImage: "wand.and.stars")
                }
                .disabled(shopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAutoFilling)
            }

            Section("一句口述") {
                TextField("这家最惊喜或最踩雷的是？", text: $voiceNoteText, axis: .vertical)
                    .lineLimit(3...5)
                TextField("补充点评，可选", text: $userComment, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("判断") {
                Picker("下次还去吗", selection: $revisitIntent) {
                    ForEach(RevisitIntent.allCases, id: \.self) { intent in
                        Text(intent.label).tag(intent)
                    }
                }
                Toggle("这家踩雷", isOn: $isPitfall)
            }

            if let log, !log.aiBody.isEmpty || isGenerating {
                Section("AI 日志") {
                    if isGenerating {
                        HStack {
                            ProgressView()
                            Text("AI 日志生成中，可先离开")
                        }
                    }
                    TextField("AI 生成内容", text: Binding(
                        get: { log.aiBody },
                        set: { newValue in
                            log.aiBody = newValue
                            log.aiStatus = .edited
                            log.updatedAt = Date()
                        }
                    ), axis: .vertical)
                    .lineLimit(4...8)
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(existingLog == nil ? "新建探店" : "编辑探店")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("关闭") {
                    closeEditor()
                    dismiss()
                }
            }
            if existingLog != nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button("删除", role: .destructive) {
                        deleteCurrentLog()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    saveAndGenerate()
                }
                .fontWeight(.semibold)
            }
        }
        .onAppear(perform: prepareLog)
        .onChange(of: selectedItems) { _, items in
            loadPhotos(items)
        }
        .onChange(of: shopName) { _, _ in autosave() }
        .onChange(of: foodType) { _, _ in autosave() }
        .onChange(of: rating) { _, _ in autosave() }
        .onChange(of: dishText) { _, _ in autosave() }
        .onChange(of: voiceNoteText) { _, _ in autosave() }
        .onChange(of: userComment) { _, _ in autosave() }
    }

    private func prepareLog() {
        guard log == nil else { return }
        if let existingLog {
            log = existingLog
            shopName = existingLog.shopName
            foodType = existingLog.foodType.isEmpty ? "自动识别" : existingLog.foodType
            rating = existingLog.rating
            dishText = existingLog.recommendedDishes.sorted { $0.rank < $1.rank }.map(\.name).joined(separator: "、")
            voiceNoteText = existingLog.voiceNoteText
            userComment = existingLog.userComment
            revisitIntent = existingLog.revisitIntent
            isPitfall = existingLog.isPitfall
        } else {
            log = nil
        }
    }

    private func autosave() {
        guard hasMeaningfulInput else { return }
        let log = ensureLog()
        applyForm(to: log)
        try? modelContext.save()
    }

    private func saveAndGenerate() {
        guard !shopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "先写个店名就能保存，评分、推荐菜和地址会自动补。"
            return
        }
        let log = ensureLog()
        applyForm(to: log)
        log.status = .saved
        log.updatedAt = Date()
        try? modelContext.save()

        if validateForAI(log) {
            generateAI(for: log)
            dismiss()
        } else {
            Task {
                await autofillBeforeGenerating(log)
                await MainActor.run {
                    generateAI(for: log)
                    dismiss()
                }
            }
        }
    }

    private func applyForm(to log: FoodLog) {
        log.shopName = shopName.trimmingCharacters(in: .whitespacesAndNewlines)
        log.foodType = foodType == "自动识别" ? inferFoodType(from: shopName) : foodType
        log.rating = rating > 0 ? rating : log.rating
        log.voiceNoteText = voiceNoteText
        log.userComment = userComment
        log.revisitIntent = revisitIntent
        log.isPitfall = isPitfall
        log.updatedAt = Date()

        let names = dishText
            .split(whereSeparator: { "、,，".contains($0) })
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !names.isEmpty {
            log.recommendedDishes.removeAll()
            for (index, name) in names.prefix(6).enumerated() {
                log.recommendedDishes.append(Dish(name: name, source: "manual", rank: index))
            }
        }
    }

    private func validateForAI(_ log: FoodLog) -> Bool {
        !log.shopName.isEmpty
    }

    private func autofill() {
        guard !shopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isAutoFilling = true
        Task {
            let suggestion = await AutoFillService.suggest(for: shopName, foodType: foodType)
            await MainActor.run {
                rating = suggestion.rating
                if foodType == "自动识别" {
                    foodType = suggestion.foodType
                }
                dishText = suggestion.dishes.joined(separator: "、")
                let log = ensureLog()
                log.ratingSource = suggestion.ratingSource
                log.district = suggestion.district
                log.address = suggestion.address
                log.latitude = suggestion.latitude
                log.longitude = suggestion.longitude
                log.tags = suggestion.tags
                applyForm(to: log)
                try? modelContext.save()
                isAutoFilling = false
            }
        }
    }

    private func generateAI(for log: FoodLog) {
        isGenerating = true
        log.status = .generating
        log.aiStatus = .generating
        try? modelContext.save()

        Task {
            let result = await AILogService.generate(for: log)
            await MainActor.run {
                log.aiTitle = result.title
                log.aiBody = result.body
                log.aiStatus = .generated
                log.status = .generated
                log.updatedAt = Date()
                try? modelContext.save()
                isGenerating = false
            }
        }
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) {
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        let log = ensureLog()
                        let photo = FoodPhoto(imageData: data, isCover: log.photos.isEmpty)
                        log.photos.append(photo)
                        log.updatedAt = Date()
                        try? modelContext.save()
                    }
                }
            }
            await MainActor.run {
                selectedItems = []
            }
        }
    }

    private var hasMeaningfulInput: Bool {
        !shopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !voiceNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !userComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        rating > 0 ||
        !dishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !(log?.photos.isEmpty ?? true)
    }

    private func ensureLog() -> FoodLog {
        if let log {
            return log
        }
        let newLog = FoodLog(foodType: foodType == "自动识别" ? "" : foodType)
        modelContext.insert(newLog)
        log = newLog
        return newLog
    }

    private func closeEditor() {
        guard let log else { return }
        if existingLog == nil && !hasMeaningfulInput {
            modelContext.delete(log)
        } else {
            autosave()
        }
        try? modelContext.save()
    }

    private func deleteCurrentLog() {
        if let log {
            modelContext.delete(log)
            try? modelContext.save()
        }
        dismiss()
    }

    private func autofillBeforeGenerating(_ log: FoodLog) async {
        let suggestion = await AutoFillService.suggest(for: log.shopName, foodType: log.foodType)
        await MainActor.run {
            if log.rating <= 0 {
                log.rating = suggestion.rating
                rating = suggestion.rating
            }
            if log.foodType.isEmpty || log.foodType == "自动识别" {
                log.foodType = suggestion.foodType
                foodType = suggestion.foodType
            }
            if log.recommendedDishes.isEmpty {
                for (index, name) in suggestion.dishes.enumerated() {
                    log.recommendedDishes.append(Dish(name: name, source: "auto", rank: index))
                }
                dishText = suggestion.dishes.joined(separator: "、")
            }
            log.ratingSource = suggestion.ratingSource
            log.district = suggestion.district
            log.address = suggestion.address
            log.latitude = suggestion.latitude
            log.longitude = suggestion.longitude
            log.tags = suggestion.tags
            log.updatedAt = Date()
            try? modelContext.save()
        }
    }

    private func inferFoodType(from text: String) -> String {
        if text.contains("粉") || text.contains("面") { return "粉面" }
        if text.contains("烧烤") || text.contains("串") { return "烧烤" }
        if text.contains("火锅") { return "火锅" }
        if text.contains("咖啡") { return "咖啡" }
        if text.contains("甜") || text.contains("蛋糕") { return "甜品" }
        return "小吃"
    }
}
