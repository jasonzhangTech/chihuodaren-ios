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
                    guard let selectedCoordinate else { return }
                    onSelect(PickedLocation(
                        address: selectedAddress.isEmpty ? "地图选点" : selectedAddress,
                        district: selectedDistrict,
                        latitude: selectedCoordinate.latitude,
                        longitude: selectedCoordinate.longitude
                    ))
                    dismiss()
                }
                .disabled(selectedCoordinate == nil)
                .fontWeight(.semibold)
            }
        }
        .onAppear(perform: prepareInitialLocation)
        .onChange(of: locationProvider.currentLocation) { _, location in
            guard initialLatitude == nil, selectedCoordinate == nil, let location else { return }
            cameraPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
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
                                select(mapItem: item)
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
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(16)
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private var selectedLocationCard: some View {
        if let selectedCoordinate {
            VStack(alignment: .leading, spacing: 6) {
                Text(selectedAddress.isEmpty ? "已选择位置" : selectedAddress)
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
        }
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
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
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
        selectedAddress = mapItem.name ?? compactAddress(for: placemark)
        selectedDistrict = placemark.locality ?? placemark.subLocality ?? placemark.administrativeArea ?? ""
        cameraPosition = .region(MKCoordinateRegion(
            center: placemark.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        ))
    }

    private func select(coordinate: CLLocationCoordinate2D, fallbackName: String) {
        selectedCoordinate = coordinate
        selectedAddress = fallbackName
        selectedDistrict = ""
        cameraPosition = .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        ))

        Task {
            let geocoder = CLGeocoder()
            if let placemark = try? await geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)).first {
                await MainActor.run {
                    selectedAddress = compactAddress(for: placemark)
                    selectedDistrict = placemark.locality ?? placemark.subLocality ?? placemark.administrativeArea ?? ""
                }
            }
        }
    }

    private func compactAddress(for placemark: MKPlacemark) -> String {
        [
            placemark.locality,
            placemark.subLocality,
            placemark.thoroughfare,
            placemark.subThoroughfare
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: " ")
    }

    private func compactAddress(for placemark: CLPlacemark) -> String {
        [
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
}
