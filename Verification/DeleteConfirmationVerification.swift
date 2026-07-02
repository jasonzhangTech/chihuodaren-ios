import Foundation

@main
struct DeleteConfirmationVerification {
    static func main() {
        precondition(DeleteConfirmationPolicy.title == "删除这条日志？", "delete confirmation title should be explicit")
        precondition(DeleteConfirmationPolicy.message.contains("删除后无法恢复"), "delete confirmation must warn about irreversibility")
        precondition(DeleteConfirmationPolicy.confirmButtonTitle == "删除", "confirm button should keep the destructive action name")
        print("PASS: delete action requires explicit confirmation copy")
    }
}
