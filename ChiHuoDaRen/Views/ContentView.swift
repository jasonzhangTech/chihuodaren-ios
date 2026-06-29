import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var locationProvider = UserLocationProvider()

    var body: some View {
        TabView {
            NavigationStack {
                LogListView()
            }
            .tabItem {
                Label("日志", systemImage: "fork.knife")
            }

            NavigationStack {
                EatDecisionView()
            }
            .tabItem {
                Label("吃啥", systemImage: "sparkles")
            }
        }
        .tint(.tomato)
        .environmentObject(locationProvider)
        .task {
            MockDataSeeder.seedTimelineDataIfRequested(in: modelContext)
        }
    }
}

extension Color {
    static let tomato = Color(red: 0.86, green: 0.25, blue: 0.16)
    static let ink = Color(red: 0.13, green: 0.12, blue: 0.1)
    static let paper = Color(red: 0.98, green: 0.96, blue: 0.92)
    static let leaf = Color(red: 0.18, green: 0.45, blue: 0.32)
}

struct ChineseTextInput: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .textInputAutocapitalization(.never)
            .keyboardType(.default)
            .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
        #else
        content
            .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
        #endif
    }
}

extension View {
    func chineseTextInput() -> some View {
        modifier(ChineseTextInput())
    }
}
