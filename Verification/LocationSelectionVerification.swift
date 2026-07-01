import Foundation

@main
struct LocationSelectionVerification {
    static func main() {
        precondition(
            MapInitialLocationPolicy.shouldAutoSelectCurrentLocation(
                hasInitialCoordinate: false,
                hasSelectedCoordinate: false,
                hasCurrentLocation: true
            ),
            "Address picker should default to current location when there is no prior address"
        )

        precondition(
            !MapInitialLocationPolicy.shouldAutoSelectCurrentLocation(
                hasInitialCoordinate: true,
                hasSelectedCoordinate: false,
                hasCurrentLocation: true
            ),
            "Existing saved location should not be replaced by current location"
        )

        precondition(
            !MapInitialLocationPolicy.shouldAutoSelectCurrentLocation(
                hasInitialCoordinate: false,
                hasSelectedCoordinate: true,
                hasCurrentLocation: true
            ),
            "User-selected location should not be replaced by current location updates"
        )

        precondition(
            !MapInitialLocationPolicy.canFinishSelection(address: "当前位置"),
            "Current location placeholder should not be submitted as the picked address"
        )

        precondition(
            !MapInitialLocationPolicy.canFinishSelection(address: "地图选点"),
            "Map tap placeholder should not be submitted as the picked address"
        )

        precondition(
            MapInitialLocationPolicy.canFinishSelection(address: "南京市江宁区秣陵街道竹山路东渡国际 6 栋"),
            "Concrete resolved address should be submittable"
        )

        print("PASS: address picker auto-selects current location when appropriate")
    }
}
