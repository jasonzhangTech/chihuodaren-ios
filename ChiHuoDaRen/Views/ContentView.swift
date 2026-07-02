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

enum FoodMotion {
    static let quick = Animation.spring(response: 0.26, dampingFraction: 0.78)
    static let gentle = Animation.spring(response: 0.42, dampingFraction: 0.86)
    static let card = Animation.spring(response: 0.50, dampingFraction: 0.82)

    static var cardInsertion: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.98)),
            removal: .opacity.combined(with: .scale(scale: 0.98))
        )
    }
}

struct PressScaleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion || !configuration.isPressed ? 1 : 0.96)
            .brightness(configuration.isPressed ? -0.03 : 0)
            .animation(FoodMotion.quick, value: configuration.isPressed)
    }
}

struct CardPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion || !configuration.isPressed ? 1 : 0.985)
            .shadow(color: configuration.isPressed ? Color.soy.opacity(0.05) : Color.clear, radius: 6, y: 2)
            .animation(FoodMotion.quick, value: configuration.isPressed)
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
