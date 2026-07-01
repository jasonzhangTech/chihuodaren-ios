import PhotosUI
import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct LogEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var locationProvider: UserLocationProvider

    let existingLog: FoodLog?
    @State private var log: FoodLog?
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var pendingPhotoData: [Data] = []
    @State private var isPhotoPickerPresented = false
    @State private var isCameraPresented = false
    @State private var isPhotoSourceDialogPresented = false
    @State private var visitDate = Date()
    @State private var shopName = ""
    @State private var foodType = "其他"
    @State private var environmentRating = 0.0
    @State private var serviceRating = 0.0
    @State private var dishRating = 0.0
    @State private var dishText = ""
    @State private var address = ""
    @State private var district = ""
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var isPitfall = false
    @State private var errorMessage: String?
    @State private var showingLocationPicker = false

    private let foodTypes = ["火锅", "烧烤", "烤肉", "正餐", "小吃", "咖啡", "甜品", "粉面", "其他"]

    init(log: FoodLog?) {
        self.existingLog = log
    }

    var body: some View {
        Form {
            Section {
                photoEntry
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section("时间") {
                DatePicker("探店日期", selection: $visitDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
            }

            Section("店铺") {
                TextField("店名", text: $shopName)
                    .chineseTextInput()

                TypeSelectionGrid(types: foodTypes, selection: $foodType)

                VStack(alignment: .leading, spacing: 12) {
                    StarRatingRow(title: "环境", value: $environmentRating)
                    StarRatingRow(title: "服务", value: $serviceRating)
                    StarRatingRow(title: "菜品", value: $dishRating)
                    HStack {
                        Text("最终评分")
                        Spacer()
                        Text(finalRating > 0 ? String(format: "%.1f", finalRating) : "--")
                            .font(.body.weight(.semibold).monospacedDigit())
                            .foregroundStyle(Color.ink)
                    }
                }

                TextField("推荐菜，可选，用顿号分隔", text: $dishText)
                    .chineseTextInput()
            }

            Section("地址") {
                Button {
                    locationProvider.refresh()
                    showingLocationPicker = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "map")
                            .foregroundStyle(Color.tomato)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(address.isEmpty ? "在地图上选择店铺地址" : address)
                                .foregroundStyle(address.isEmpty ? .secondary : Color.ink)
                                .lineLimit(2)
                            if !district.isEmpty {
                                Text(district)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            Section("评价") {
                ThumbJudgementControl(isPitfall: $isPitfall)
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
        .scrollContentBackground(.hidden)
        .background(Color.paper)
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
                    saveLog()
                }
                .fontWeight(.semibold)
            }
        }
        .onAppear(perform: prepareLog)
        .sheet(isPresented: $isPhotoSourceDialogPresented) {
            PhotoSourceSheet(
                isCameraAvailable: isCameraAvailable,
                onCamera: chooseCamera,
                onLibrary: choosePhotoLibrary
            )
            .presentationDetents([.height(isCameraAvailable ? 236 : 178)])
            .presentationDragIndicator(.visible)
        }
        .photosPicker(isPresented: $isPhotoPickerPresented, selection: $selectedItems, maxSelectionCount: 9, matching: .images)
        .sheet(isPresented: $isCameraPresented) {
            CameraCaptureView { imageData in
                appendPhoto(data: imageData)
            }
        }
        .sheet(isPresented: $showingLocationPicker) {
            NavigationStack {
                MapLocationPickerView(
                    initialAddress: address,
                    initialLatitude: latitude,
                    initialLongitude: longitude
                ) { location in
                    address = location.address
                    district = location.district
                    latitude = location.latitude
                    longitude = location.longitude
                    autosave()
                }
            }
        }
        .onChange(of: selectedItems) { _, items in
            loadPhotos(items)
        }
        .onChange(of: visitDate) { _, _ in autosave() }
        .onChange(of: shopName) { _, _ in autosave() }
        .onChange(of: foodType) { _, _ in autosave() }
        .onChange(of: environmentRating) { _, _ in autosave() }
        .onChange(of: serviceRating) { _, _ in autosave() }
        .onChange(of: dishRating) { _, _ in autosave() }
        .onChange(of: dishText) { _, _ in autosave() }
        .onChange(of: address) { _, _ in autosave() }
        .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
        .tint(.tomato)
    }

    private var photoEntry: some View {
        let photos = (log?.photos.map(\.imageData) ?? []) + pendingPhotoData

        return ZStack(alignment: .topTrailing) {
            PhotoMosaicView(imageData: photos, height: 230)
                .contentShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    presentPrimaryPhotoInput()
                }

            if !photos.isEmpty {
                Button {
                    presentPrimaryPhotoInput()
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.tomato)
                        .clipShape(Circle())
                        .shadow(color: Color.soy.opacity(0.18), radius: 10, y: 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("追加照片")
                .padding(12)
            }
        }
    }

    private func prepareLog() {
        guard log == nil else { return }
        if let existingLog {
            log = existingLog
            visitDate = existingLog.createdAt
            shopName = existingLog.shopName
            foodType = foodTypes.contains(existingLog.foodType) ? existingLog.foodType : "其他"
            environmentRating = existingLog.environmentRating
            serviceRating = existingLog.serviceRating
            dishRating = existingLog.dishRating
            dishText = existingLog.recommendedDishes.sorted { $0.rank < $1.rank }.map(\.name).joined(separator: "、")
            address = existingLog.address
            district = existingLog.district
            latitude = existingLog.latitude
            longitude = existingLog.longitude
            isPitfall = existingLog.isPitfall
        } else {
            log = nil
        }
    }

    private func autosave() {
        guard canPersistDraft else { return }
        let log = ensureLog()
        applyForm(to: log)
        try? modelContext.save()
    }

    private func saveLog() {
        let validation = LogSaveValidation.canSave(
            shopName: shopName,
            address: address,
            photoCount: currentPhotoCount
        )
        guard validation.isAllowed else {
            errorMessage = validation.message
            return
        }
        let log = ensureLog()
        applyForm(to: log)
        log.status = .saved
        log.updatedAt = Date()
        try? modelContext.save()
        dismiss()
    }

    private func applyForm(to log: FoodLog) {
        log.shopName = shopName.trimmingCharacters(in: .whitespacesAndNewlines)
        log.createdAt = visitDate
        log.foodType = foodType
        log.environmentRating = environmentRating
        log.serviceRating = serviceRating
        log.dishRating = dishRating
        log.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        log.district = district
        log.latitude = latitude
        log.longitude = longitude
        log.isPitfall = isPitfall
        log.updatedAt = Date()
        flushPendingPhotos(to: log)

        let names = dishText
            .split(whereSeparator: { "、,，".contains($0) })
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !names.isEmpty {
            log.recommendedDishes.removeAll()
            for (index, name) in names.prefix(6).enumerated() {
                log.recommendedDishes.append(Dish(name: name, rank: index))
            }
        }
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) {
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        appendPhoto(data: data)
                    }
                }
            }
            await MainActor.run {
                selectedItems = []
            }
        }
    }

    private func appendPhoto(data: Data) {
        if canPersistDraft {
            let log = ensureLog()
            let photo = FoodPhoto(imageData: data, isCover: log.photos.isEmpty)
            log.photos.append(photo)
            log.updatedAt = Date()
            try? modelContext.save()
        } else {
            pendingPhotoData.append(data)
        }
    }

    private func presentPrimaryPhotoInput() {
        isPhotoSourceDialogPresented = true
    }

    private func chooseCamera() {
        isPhotoSourceDialogPresented = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            presentCamera()
        }
    }

    private func choosePhotoLibrary() {
        isPhotoSourceDialogPresented = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            isPhotoPickerPresented = true
        }
    }

    private func presentCamera() {
        #if canImport(UIKit)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            isCameraPresented = true
        } else {
            isPhotoPickerPresented = true
        }
        #else
        isPhotoPickerPresented = true
        #endif
    }

    private var isCameraAvailable: Bool {
        #if canImport(UIKit)
        UIImagePickerController.isSourceTypeAvailable(.camera)
        #else
        false
        #endif
    }

    private var canPersistDraft: Bool {
        !shopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && currentPhotoCount > 0
    }

    private var currentPhotoCount: Int {
        (log?.photos.count ?? 0) + pendingPhotoData.count
    }

    private func flushPendingPhotos(to log: FoodLog) {
        guard !pendingPhotoData.isEmpty else { return }
        for data in pendingPhotoData {
            log.photos.append(FoodPhoto(imageData: data, isCover: log.photos.isEmpty))
        }
        pendingPhotoData.removeAll()
    }

    private func ensureLog() -> FoodLog {
        if let log {
            return log
        }
        let newLog = FoodLog(foodType: foodType)
        modelContext.insert(newLog)
        log = newLog
        return newLog
    }

    private func closeEditor() {
        if existingLog == nil && !canPersistDraft {
            if let log {
                modelContext.delete(log)
            }
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

    private var finalRating: Double {
        let parts = [environmentRating, serviceRating, dishRating].filter { $0 > 0 }
        guard !parts.isEmpty else { return 0 }
        return parts.reduce(0, +) / Double(parts.count)
    }
}

private struct TypeSelectionGrid: View {
    let types: [String]
    @Binding var selection: String

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("类型")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.ink)
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(types, id: \.self) { type in
                    Button {
                        selection = type
                    } label: {
                        Text(type)
                            .font(.subheadline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(selection == type ? Color.tomato : Color.chiliSoft.opacity(0.45))
                            .foregroundStyle(selection == type ? .white : Color.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct StarRatingRow: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .frame(width: 44, alignment: .leading)
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { index in
                    HalfStarButton(index: index, value: $value)
                }
            }
            Spacer()
            Text(value > 0 ? String(format: "%.1f", value) : "--")
                .font(.body.monospacedDigit().weight(.bold))
                .frame(width: 42, alignment: .trailing)
                .foregroundStyle(Color.soy)
        }
    }
}

private struct ThumbJudgementControl: View {
    @Binding var isPitfall: Bool

    var body: some View {
        HStack(spacing: 10) {
            judgementButton(title: "推荐", systemImage: "hand.thumbsup.fill", selected: !isPitfall, selectedColor: .tomato) {
                isPitfall = false
            }
            judgementButton(title: "踩雷", systemImage: "hand.thumbsdown.fill", selected: isPitfall, selectedColor: .leaf) {
                isPitfall = true
            }
        }
        .padding(.vertical, 4)
    }

    private func judgementButton(title: String, systemImage: String, selected: Bool, selectedColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? selectedColor : Color.chiliSoft.opacity(0.45))
                .foregroundStyle(selected ? .white : Color.ink)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct HalfStarButton: View {
    let index: Int
    @Binding var value: Double

    var body: some View {
        Image(systemName: symbolName)
            .font(.title3)
            .foregroundStyle(value >= Double(index) || value >= Double(index) - 0.5 ? Color.tomato : Color.secondary.opacity(0.28))
            .frame(width: 32, height: 32)
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture()
                    .onEnded { gesture in
                        value = gesture.location.x < 16 ? Double(index) - 0.5 : Double(index)
                    }
            )
        .accessibilityLabel("\(index) 星")
    }

    private var symbolName: String {
        if value >= Double(index) {
            return "star.fill"
        }
        if value >= Double(index) - 0.5 {
            return "star.leadinghalf.filled"
        }
        return "star"
    }
}

private struct PhotoSourceSheet: View {
    let isCameraAvailable: Bool
    let onCamera: () -> Void
    let onLibrary: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.riceLine.opacity(0.55))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 14)

            Text("添加照片")
                .font(.headline.weight(.black))
                .foregroundStyle(Color.ink)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                if isCameraAvailable {
                    Button(action: onCamera) {
                        Label("拍照", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(PhotoSourceButtonStyle())

                    Divider()
                        .padding(.leading, 52)
                }

                Button(action: onLibrary) {
                    Label("从相册选取", systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(PhotoSourceButtonStyle())
            }
            .background(Color.ticket)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 20)

            Spacer(minLength: 0)
        }
        .background(Color.paper)
    }
}

private struct PhotoSourceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 18)
            .frame(height: 56)
            .background(configuration.isPressed ? Color.chiliSoft.opacity(0.6) : Color.clear)
    }
}
