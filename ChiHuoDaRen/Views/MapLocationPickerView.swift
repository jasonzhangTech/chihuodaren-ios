import MapKit
import SwiftUI

struct PickedLocation {
    let address: String
    let district: String
    let latitude: Double
    let longitude: Double
}

struct MapLocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var locationProvider: UserLocationProvider

    let initialAddress: String
    let initialLatitude: Double?
    let initialLongitude: Double?
    let onSelect: (PickedLocation) -> Void

    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedAddress = ""
    @State private var selectedDistrict = ""
    @State private var isResolvingSelectedAddress = false
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )

    var body: some View {
        VStack(spacing: 0) {
            searchBar

            MapReader { proxy in
                Map(position: $cameraPosition) {
                    if let selectedCoordinate {
                        Marker(selectedAddress.isEmpty ? "已选位置" : selectedAddress, coordinate: selectedCoordinate)
                            .tint(Color.tomato)
                    }
                }
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .onTapGesture { point in
                    guard let coordinate = proxy.convert(point, from: .local) else { return }
                    select(coordinate: coordinate, fallbackName: "地图选点")
                }
            }
            .overlay(alignment: .bottom) {
                selectedLocationCard
            }
        }
        .navigationTitle("选择地址")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") {
                    guard let selectedCoordinate, canFinishSelection else { return }
                    onSelect(PickedLocation(
                        address: selectedAddress,
                        district: selectedDistrict,
                        latitude: selectedCoordinate.latitude,
                        longitude: selectedCoordinate.longitude
                    ))
                    dismiss()
                }
                .disabled(!canFinishSelection)
                .fontWeight(.semibold)
            }
        }
        .onAppear(perform: prepareInitialLocation)
        .onChange(of: locationProvider.currentLocation) { _, location in
            autoSelectCurrentLocationIfNeeded(location)
        }
    }

    private var searchBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索店名或地址", text: $searchText)
                    .chineseTextInput()
                    .submitLabel(.search)
                    .onSubmit { searchPlaces() }
                Button("搜索", action: searchPlaces)
                    .font(.body.weight(.semibold))
                    .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if !searchResults.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(searchResults, id: \.self) { item in
                            Button {
                                withAnimation(FoodMotion.gentle) {
                                    select(mapItem: item)
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.name ?? "未命名地点")
                                        .font(.subheadline.weight(.semibold))
                                        .lineLimit(1)
                                    Text(compactAddress(for: item.placemark))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                .frame(width: 180, alignment: .leading)
                                .padding(10)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(CardPressButtonStyle())
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(16)
        .background(Color(.systemGroupedBackground))
        .animation(FoodMotion.gentle, value: searchResults.count)
    }

    @ViewBuilder
    private var selectedLocationCard: some View {
        if let selectedCoordinate {
            VStack(alignment: .leading, spacing: 6) {
                Text(selectedLocationTitle)
                    .font(.headline)
                    .foregroundStyle(Color.ink)
                    .lineLimit(2)
                Text(String(format: "%.5f, %.5f", selectedCoordinate.latitude, selectedCoordinate.longitude))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(FoodMotion.gentle, value: selectedLocationTitle)
        }
    }

    private var canFinishSelection: Bool {
        selectedCoordinate != nil &&
        !isResolvingSelectedAddress &&
        MapInitialLocationPolicy.canFinishSelection(address: selectedAddress)
    }

    private var selectedLocationTitle: String {
        if isResolvingSelectedAddress {
            return "正在获取具体地址..."
        }
        return MapInitialLocationPolicy.canFinishSelection(address: selectedAddress) ? selectedAddress : "未获取到具体地址，请搜索或点选附近店铺"
    }

    private func prepareInitialLocation() {
        locationProvider.refresh()
        searchText = initialAddress
        if let initialLatitude, let initialLongitude {
            let coordinate = CLLocationCoordinate2D(latitude: initialLatitude, longitude: initialLongitude)
            selectedCoordinate = coordinate
            selectedAddress = initialAddress
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        } else if let coordinate = locationProvider.currentLocation?.coordinate {
            select(coordinate: coordinate, fallbackName: "当前位置")
        }
    }

    private func autoSelectCurrentLocationIfNeeded(_ location: CLLocation?) {
        guard MapInitialLocationPolicy.shouldAutoSelectCurrentLocation(
            hasInitialCoordinate: initialLatitude != nil,
            hasSelectedCoordinate: selectedCoordinate != nil,
            hasCurrentLocation: location != nil
        ), let location else {
            return
        }
        select(coordinate: location.coordinate, fallbackName: "当前位置")
    }

    private func searchPlaces() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.pointOfInterest, .address]
        if let location = locationProvider.currentLocation {
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
        }

        Task {
            do {
                let response = try await MKLocalSearch(request: request).start()
                await MainActor.run {
                    searchResults = Array(response.mapItems.prefix(8))
                    if let first = searchResults.first {
                        select(mapItem: first)
                    }
                }
            } catch {
                await MainActor.run {
                    searchResults = []
                }
            }
        }
    }

    private func select(mapItem: MKMapItem) {
        let placemark = mapItem.placemark
        selectedCoordinate = placemark.coordinate
        selectedAddress = concreteAddress(for: mapItem)
        selectedDistrict = placemark.locality ?? placemark.subLocality ?? placemark.administrativeArea ?? ""
        isResolvingSelectedAddress = false
        cameraPosition = .region(MKCoordinateRegion(
            center: placemark.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        ))
    }

    private func select(coordinate: CLLocationCoordinate2D, fallbackName: String) {
        selectedCoordinate = coordinate
        selectedAddress = fallbackName
        selectedDistrict = ""
        isResolvingSelectedAddress = true
        cameraPosition = .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        ))

        Task {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            if let resolved = await resolveConcreteAddress(for: location) {
                await MainActor.run {
                    selectedAddress = resolved.address
                    selectedDistrict = resolved.district
                    isResolvingSelectedAddress = false
                }
            } else {
                await MainActor.run {
                    isResolvingSelectedAddress = false
                }
            }
        }
    }

    private func resolveConcreteAddress(for location: CLLocation) async -> (address: String, district: String)? {
        if #available(iOS 26.0, *) {
            let request = MKReverseGeocodingRequest(location: location)
            request?.preferredLocale = Locale(identifier: "zh_Hans_CN")
            if let mapItems = try? await request?.mapItems {
                for item in mapItems {
                    let address = concreteAddress(for: item)
                    if MapInitialLocationPolicy.canFinishSelection(address: address) {
                        let placemark = item.placemark
                        return (address, placemark.locality ?? placemark.subLocality ?? placemark.administrativeArea ?? "")
                    }
                }
            }
        }

        let geocoder = CLGeocoder()
        if let placemark = try? await geocoder.reverseGeocodeLocation(location).first {
            let address = concreteAddress(for: placemark)
            if MapInitialLocationPolicy.canFinishSelection(address: address) {
                return (address, placemark.locality ?? placemark.subLocality ?? placemark.administrativeArea ?? "")
            }
        }

        let request = MKLocalPointsOfInterestRequest(center: location.coordinate, radius: 120)
        if let response = try? await MKLocalSearch(request: request).start() {
            let nearest = response.mapItems.min { lhs, rhs in
                let leftDistance = lhs.placemark.location?.distance(from: location) ?? .greatestFiniteMagnitude
                let rightDistance = rhs.placemark.location?.distance(from: location) ?? .greatestFiniteMagnitude
                return leftDistance < rightDistance
            }
            if let nearest {
                let address = concreteAddress(for: nearest)
                if MapInitialLocationPolicy.canFinishSelection(address: address) {
                    let placemark = nearest.placemark
                    return (address, placemark.locality ?? placemark.subLocality ?? placemark.administrativeArea ?? "")
                }
            }
        }

        return nil
    }

    private func compactAddress(for placemark: MKPlacemark) -> String {
        [
            placemark.administrativeArea,
            placemark.locality,
            placemark.subLocality,
            placemark.thoroughfare,
            placemark.subThoroughfare,
            placemark.name
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: " ")
    }

    private func compactAddress(for placemark: CLPlacemark) -> String {
        [
            placemark.administrativeArea,
            placemark.locality,
            placemark.subLocality,
            placemark.thoroughfare,
            placemark.subThoroughfare,
            placemark.name
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: " ")
    }

    private func concreteAddress(for item: MKMapItem) -> String {
        let placemarkAddress = compactAddress(for: item.placemark)
        guard let name = item.name, !name.isEmpty else {
            return placemarkAddress
        }
        if placemarkAddress.contains(name) {
            return placemarkAddress
        }
        return ([placemarkAddress, name].filter { !$0.isEmpty }).joined(separator: " ")
    }

    private func concreteAddress(for placemark: CLPlacemark) -> String {
        compactAddress(for: placemark)
    }
}
