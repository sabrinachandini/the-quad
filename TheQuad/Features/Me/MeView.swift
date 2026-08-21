import SwiftUI

struct MeView: View {
    @State private var appState = AppState.shared
    @State private var showClassroomSheet = false
    @State private var showAspenSheet = false
    @State private var icsExportURL: URL? = nil
    @State private var showShareSheet = false

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
                // Google Classroom row
                Button {
                    showClassroomSheet = true
                } label: {
                    HStack {
                        Label("Google Classroom", systemImage: "graduationcap.fill")
                            .font(DesignTokens.Typography.quadBody)
                            .foregroundStyle(DesignTokens.Colors.primary)
                        Spacer()
                        Text("Connect")
                            .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                            .foregroundStyle(DesignTokens.Colors.accent)
                    }
                }
                .buttonStyle(.plain)

                // Aspen Grades row
                HStack {
                    Label("Aspen Grades", systemImage: "chart.bar.fill")
                        .font(DesignTokens.Typography.quadBody)
                        .foregroundStyle(DesignTokens.Colors.primary)
                    Spacer()
                    Button {
                        showAspenSheet = true
                    } label: {
                        Text("Coming soon")
                            .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                            .foregroundStyle(DesignTokens.Colors.secondary)
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, 3)
                            .background(DesignTokens.Colors.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
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
                .onChange(of: appState.classRemindersEnabled) {
                    NotificationScheduler.shared.scheduleAll()
                }
            } header: {
                sectionHeader("Notifications")
            }

            // MARK: - Calendar Export
            Section {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Subscribe to your rotating schedule in any calendar app.")
                        .font(DesignTokens.Typography.quadCaption)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let url = icsExportURL {
                        ShareLink(
                            item: url,
                            preview: SharePreview("LHS Schedule", image: Image(systemName: "calendar"))
                        ) {
                            HStack {
                                Image(systemName: "calendar.badge.checkmark")
                                    .foregroundStyle(DesignTokens.Colors.accent)
                                Text("Share .ics File")
                                    .font(DesignTokens.Typography.quadBody)
                                    .foregroundStyle(DesignTokens.Colors.accent)
                            }
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            generateICSFile()
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                    .foregroundStyle(DesignTokens.Colors.accent)
                                Text("Export .ics File")
                                    .font(DesignTokens.Typography.quadBody)
                                    .foregroundStyle(DesignTokens.Colors.accent)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.xs)
            } header: {
                sectionHeader("Calendar Export")
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
        .sheet(isPresented: $showClassroomSheet) {
            ClassroomIntegrationSheet()
        }
        .sheet(isPresented: $showAspenSheet) {
            AspenIntegrationSheet()
        }
    }

    private func generateICSFile() {
        let engine = appState.scheduleEngine
        let today = Date()
        guard let sixMonths = Calendar.current.date(byAdding: .month, value: 6, to: today) else { return }

        let icsString = ICSGenerator().generate(
            courses: appState.courses,
            enrollments: appState.enrollments,
            engine: engine,
            from: today,
            to: sixMonths
        )

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("LHS_Schedule.ics")
        do {
            try icsString.write(to: tempURL, atomically: true, encoding: .utf8)
            icsExportURL = tempURL
        } catch {
            // If write fails, silently no-op — button remains visible for retry
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(DesignTokens.Typography.quadCaption.weight(.semibold))
            .foregroundStyle(DesignTokens.Colors.secondary)
            .textCase(nil)
    }
}

// MARK: - Classroom integration sheet

struct ClassroomIntegrationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showConnectAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.Colors.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                        // Icon + title
                        HStack(spacing: DesignTokens.Spacing.md) {
                            Image(systemName: "graduationcap.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(DesignTokens.Colors.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Google Classroom")
                                    .font(DesignTokens.Typography.quadTitle)
                                    .foregroundStyle(DesignTokens.Colors.primary)
                                Text("Automatic assignment sync")
                                    .font(DesignTokens.Typography.quadCaption)
                                    .foregroundStyle(DesignTokens.Colors.secondary)
                            }
                        }

                        // What it does
                        featureCard(
                            title: "What this does",
                            items: [
                                ("checkmark.circle.fill", "Pulls assignments and due dates automatically"),
                                ("checkmark.circle.fill", "Shows submission state — turned in, missing, late"),
                                ("checkmark.circle.fill", "Updates in the background — no manual entry"),
                            ]
                        )

                        // Known risk
                        featureCard(
                            title: "Known limitation",
                            items: [
                                ("exclamationmark.triangle.fill",
                                 "LPS manages Google accounts through Workspace for Education. Your school's IT policy may block third-party apps from accessing Classroom — even with your permission."),
                                ("info.circle.fill",
                                 "If access is blocked, The Quad falls back to manual assignment entry. Your data never leaves your device either way."),
                            ],
                            tintColor: .orange
                        )

                        // Note about docs
                        Text("See docs/INTEGRATIONS.md in the project for technical details on the OAuth approach being investigated.")
                            .font(DesignTokens.Typography.quadCaption)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                            .padding(DesignTokens.Spacing.md)
                            .background(DesignTokens.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))

                        // Connect button
                        Button {
                            showConnectAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Connect Google Account")
                                    .font(DesignTokens.Typography.quadBody.weight(.semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .padding(DesignTokens.Spacing.lg)
                            .background(DesignTokens.Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
                        }
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .padding(.bottom, DesignTokens.Spacing.xxxl)
                }
            }
            .navigationTitle("Classroom")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DesignTokens.Colors.accent)
                }
            }
            .alert("Classroom Sync — In Progress", isPresented: $showConnectAlert) {
                Button("Got it", role: .cancel) {}
            } message: {
                Text("Classroom sync requires your LPS Google account. This feature is in progress — you'll be notified when it's ready.")
            }
        }
    }

    @ViewBuilder
    private func featureCard(title: String, items: [(String, String)], tintColor: Color = .green) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(title)
                .font(DesignTokens.Typography.quadHeadline.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.primary)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: item.0)
                        .foregroundStyle(tintColor)
                        .frame(width: 20)
                    Text(item.1)
                        .font(DesignTokens.Typography.quadBody)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
    }
}

// MARK: - Aspen integration sheet

struct AspenIntegrationSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.Colors.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                        HStack(spacing: DesignTokens.Spacing.md) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(DesignTokens.Colors.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Aspen Grades")
                                    .font(DesignTokens.Typography.quadTitle)
                                    .foregroundStyle(DesignTokens.Colors.primary)
                                HStack(spacing: DesignTokens.Spacing.sm) {
                                    Text("Coming soon")
                                        .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                                        .foregroundStyle(DesignTokens.Colors.secondary)
                                        .padding(.horizontal, DesignTokens.Spacing.sm)
                                        .padding(.vertical, 3)
                                        .background(DesignTokens.Colors.secondary.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            Text("What this will do")
                                .font(DesignTokens.Typography.quadHeadline.weight(.semibold))
                                .foregroundStyle(DesignTokens.Colors.primary)
                            ForEach([
                                ("checkmark.circle.fill", "Pull grades from Aspen automatically"),
                                ("checkmark.circle.fill", "Power the what-if grade calculator with real weights"),
                                ("checkmark.circle.fill", "No account credentials stored outside your device"),
                            ], id: \.0) { item in
                                HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                                    Image(systemName: item.0)
                                        .foregroundStyle(DesignTokens.Colors.secondary)
                                        .frame(width: 20)
                                    Text(item.1)
                                        .font(DesignTokens.Typography.quadBody)
                                        .foregroundStyle(DesignTokens.Colors.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(DesignTokens.Spacing.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DesignTokens.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            Text("Technical approach (under investigation)")
                                .font(DesignTokens.Typography.quadHeadline.weight(.semibold))
                                .foregroundStyle(DesignTokens.Colors.primary)
                            Text("Aspen doesn't offer a public API. We're investigating a device-local session-based approach (similar to GradeKit) that authenticates on-device and reads your grades directly — no server ever sees your credentials. If you ever disconnect, all session data is deleted from your device immediately.")
                                .font(DesignTokens.Typography.quadBody)
                                .foregroundStyle(DesignTokens.Colors.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(DesignTokens.Spacing.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DesignTokens.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .padding(.bottom, DesignTokens.Spacing.xxxl)
                }
            }
            .navigationTitle("Aspen Grades")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DesignTokens.Colors.accent)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MeView()
    }
    .preferredColorScheme(.dark)
}
