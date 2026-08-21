import SwiftUI

@main
struct TheQuadApp: App {
    @State private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            AppTabView()
                .fullScreenCover(isPresented: Binding(
                    get: { !appState.hasCompletedOnboarding },
                    set: { _ in }
                )) {
                    OnboardingView()
                }
        }
    }
}
