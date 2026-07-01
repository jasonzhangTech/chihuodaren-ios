import Foundation

@main
struct FormValidationVerification {
    static func main() {
        let completeWithoutPhoto = LogSaveValidation.canSave(
            shopName: "表单自测小馆",
            address: "地图选点",
            photoCount: 0
        )

        precondition(!completeWithoutPhoto.isAllowed, "Saving should require at least one food photo")
        precondition(completeWithoutPhoto.message == "请至少添加一张美食照片。", "Missing photo should show a clear Chinese message")

        let completeWithPhoto = LogSaveValidation.canSave(
            shopName: "表单自测小馆",
            address: "地图选点",
            photoCount: 1
        )

        precondition(completeWithPhoto.isAllowed, "Saving should be allowed when name, address and photo are present")

        print("PASS: form save validation requires a photo")
    }
}
