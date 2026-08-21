import SwiftUI

struct AppTabView: View {
    @State private var selectedTab: Tab = .today
    @State private var showAsk: Bool = false
    // Hold a reference so @Observable tracking fires on AppState changes
    @State private var appState = AppState.shared

    enum Tab {
        case today, work, grades, school, me
    }

    private var workBadgeCount: Int {
        let cal = Calendar.current
        let today = Date()
        return appState.assignments.filter { a in
            !a.isCompleted && a.dueDate.map { cal.isDate($0, inSameDayAs: today) } ?? false
        }.count
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                TodayView()
                    .tabItem { Label("Today", systemImage: "sun.max.fill") }
                    .tag(Tab.today)
                WorkView()
                    .tabItem { Label("Work", systemImage: "checkmark.circle.fill") }
                    .tag(Tab.work)
                    .badge(workBadgeCount)
                GradesView()
                    .tabItem { Label("Grades", systemImage: "chart.bar.fill") }
                    .tag(Tab.grades)
                SchoolView()
                    .tabItem { Label("School", systemImage: "building.columns.fill") }
                    .tag(Tab.school)
                MeView()
                    .tabItem { Label("Me", systemImage: "person.fill") }
                    .tag(Tab.me)
            }
            // Floating Ask button
            Button(action: { showAsk = true }) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(DesignTokens.Colors.accent)
                    .clipShape(Circle())
                    .shadow(radius: 8)
            }
            .padding(.bottom, 70)
            .sheet(isPresented: $showAsk) {
                AskView()
            }
        }
    }
}
