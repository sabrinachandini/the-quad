import SwiftUI

struct MeView: View {
    @State private var appState = AppState.shared
    @State private var showClassroomAlert = false
    @State private var showAspenAlert = false

    var body: some View {
        List {
            // MARK: - Profile
            Section {
                HStack(spacing: DesignTokens.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(DesignTokens.Colors.accent)
                            .frame(width: 56, height: 56)
                        Text(String(appState.displayName.prefix(1)).uppercased())
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(appState.displayName)
                            .font(DesignTokens.Typography.quadHeadline)
                            .foregroundStyle(DesignTokens.Colors.primary)
                        Text("Class of \(appState.graduationYear) · LHS")
                            .font(DesignTokens.Typography.quadCaption)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.xs)
            } header: {
                sectionHeader("Profile")
            }

            // MARK: - My Schedule
            Section {
                ForEach(appState.courses) { course in
                    HStack(spacing: DesignTokens.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                .fill(CourseColors.color(atIndex: course.colorIndex))
                                .frame(width: 32, height: 32)
                            Text(course.block.rawValue.uppercased())
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(course.name)
                                .font(DesignTokens.Typography.quadBody)
                                .foregroundStyle(DesignTokens.Colors.primary)
                            if let teacher = course.teacher {
                                Text(teacher)
                                    .font(DesignTokens.Typography.quadCaption)
                                    .foregroundStyle(DesignTokens.Colors.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                Button {
                    appState.hasCompletedOnboarding = false
                } label: {
                    HStack {
                        Image(systemName: "pencil")
                            .foregroundStyle(DesignTokens.Colors.accent)
                        Text("Edit Schedule")
                            .font(DesignTokens.Typography.quadBody)
                            .foregroundStyle(DesignTokens.Colors.accent)
                    }
                }
            } header: {
                sectionHeader("My Schedule")
            }

            // MARK: - Integrations
            Section {
                HStack {
                    Label("Google Classroom", systemImage: "graduationcap.fill")
                        .font(DesignTokens.Typography.quadBody)
                        .foregroundStyle(DesignTokens.Colors.primary)
                    Spacer()
                    Button("Connect") {
                        showClassroomAlert = true
                    }
                    .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.accent)
                }

                HStack {
                    Label("Aspen Grades", systemImage: "chart.bar.fill")
                        .font(DesignTokens.Typography.quadBody)
                        .foregroundStyle(DesignTokens.Colors.primary)
                    Spacer()
                    Button("Connect") {
                        showAspenAlert = true
                    }
                    .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.accent)
                }
            } header: {
                sectionHeader("Integrations")
            }

            // MARK: - Notifications
            Section {
                Toggle(isOn: $appState.classRemindersEnabled) {
                    Label("Class reminders", systemImage: "bell.fill")
                        .font(DesignTokens.Typography.quadBody)
                        .foregroundStyle(DesignTokens.Colors.primary)
                }
                .tint(DesignTokens.Colors.accent)
            } header: {
                sectionHeader("Notifications")
            }

            // MARK: - About
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: DesignTokens.Spacing.xs) {
                        Text("The Quad · Everything LHS.")
                            .font(DesignTokens.Typography.quadCaption)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                        Text("Version 0.1.0")
                            .font(DesignTokens.Typography.quadCaption)
                            .foregroundStyle(DesignTokens.Colors.secondary.opacity(0.6))
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Colors.background.ignoresSafeArea())
        .navigationTitle("Me")
        .navigationBarTitleDisplayMode(.large)
        .alert("Coming Soon", isPresented: $showClassroomAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Google Classroom integration is coming in a future update.")
        }
        .alert("Coming Soon", isPresented: $showAspenAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Aspen Grades integration is coming in a future update.")
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(DesignTokens.Typography.quadCaption.weight(.semibold))
            .foregroundStyle(DesignTokens.Colors.secondary)
            .textCase(nil)
    }
}

#Preview {
    NavigationStack {
        MeView()
    }
    .preferredColorScheme(.dark)
}
