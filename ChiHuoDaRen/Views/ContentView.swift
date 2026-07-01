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
    }
}

extension Color {
    static let tomato = Color(red: 0.84, green: 0.25, blue: 0.16)
    static let ink = Color(red: 0.13, green: 0.10, blue: 0.08)
    static let paper = Color(red: 0.94, green: 0.97, blue: 0.94)
    static let leaf = Color(red: 0.18, green: 0.44, blue: 0.31)
    static let ticket = Color(red: 1.0, green: 0.99, blue: 0.95)
    static let soy = Color(red: 0.48, green: 0.32, blue: 0.22)
    static let chiliSoft = Color(red: 1.0, green: 0.88, blue: 0.82)
    static let scallionSoft = Color(red: 0.83, green: 0.92, blue: 0.85)
    static let riceLine = Color(red: 0.76, green: 0.82, blue: 0.72)
}

extension View {
    func ticketSurface(radius: CGFloat = 8) -> some View {
        background(Color.ticket)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: Color.soy.opacity(0.10), radius: 16, x: 0, y: 8)
    }
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
