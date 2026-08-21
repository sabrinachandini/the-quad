import SwiftUI
import UserNotifications

@main
struct TheQuadApp: App {
    @State private var appState = AppState.shared
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some Scene {
        WindowGroup {
            AppTabView()
                .fullScreenCover(isPresented: Binding(
                    get: { !appState.hasCompletedOnboarding },
                    set: { _ in }
                )) {
                    OnboardingView()
                }
                .task {
                    await NotificationScheduler.shared.requestPermission()
                    NotificationScheduler.shared.scheduleAll()
                    WidgetDataWriter.shared.update()
                }
                .onChange(of: appState.classRemindersEnabled) {
                    NotificationScheduler.shared.scheduleAll()
                }
                .onReceive(timer) { _ in
                    WidgetDataWriter.shared.update()
                }
        }
    }
}
