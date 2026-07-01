import Foundation

enum MapInitialLocationPolicy {
    static func shouldAutoSelectCurrentLocation(
        hasInitialCoordinate: Bool,
        hasSelectedCoordinate: Bool,
        hasCurrentLocation: Bool
    ) -> Bool {
        !hasInitialCoordinate && !hasSelectedCoordinate && hasCurrentLocation
    }

    static func canFinishSelection(address: String) -> Bool {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != "当前位置" && trimmed != "地图选点"
    }
}
