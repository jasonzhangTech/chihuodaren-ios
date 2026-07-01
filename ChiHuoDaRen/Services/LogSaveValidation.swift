import Foundation

struct LogSaveValidationResult {
    let isAllowed: Bool
    let message: String?
}

enum LogSaveValidation {
    static func canSave(shopName: String, address: String, photoCount: Int) -> LogSaveValidationResult {
        if shopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return LogSaveValidationResult(isAllowed: false, message: "店名必填。")
        }
        if address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return LogSaveValidationResult(isAllowed: false, message: "请先在地图上选择店铺地址。")
        }
        if photoCount <= 0 {
            return LogSaveValidationResult(isAllowed: false, message: "请至少添加一张美食照片。")
        }
        return LogSaveValidationResult(isAllowed: true, message: nil)
    }
}
