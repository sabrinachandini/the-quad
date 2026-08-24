import SwiftUI

struct MeView: View {
    @State private var appState = AppState.shared
    @State private var aspenProvider = AspenGradeProvider.shared
    @State private var classroomProvider = ClassroomAuthProvider.shared
    @State private var showClassroomSheet = false
    @State private var showAspenSheet = false
    @State private var showAspenConnectSheet = false
    @State private var icsExportURL: URL? = nil
    @State private var showShareSheet = false
    @State private var showCalendarOpenFailed = false

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
                        classroomBadge
                    }
                }
                .buttonStyle(.plain)

                // Aspen Grades row
                Button {
                    if aspenProvider.isConnected {
                        showAspenSheet = true
                    } else {
                        showAspenConnectSheet = true
                    }
                } label: {
                    HStack {
                        Label("Aspen Grades", systemImage: "chart.bar.fill")
                            .font(DesignTokens.Typography.quadBody)
                            .foregroundStyle(DesignTokens.Colors.primary)
                        Spacer()
                        if aspenProvider.isConnected {
                            if case .connected(let lastSync) = aspenProvider.connectionState {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.caption)
                                    VStack(alignment: .trailing, spacing: 0) {
                                        Text("Connected")
                                            .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                                            .foregroundStyle(.green)
                                        Text(lastSync, style: .relative)
                                            .font(.system(size: 10))
                                            .foregroundStyle(DesignTokens.Colors.secondary)
                                    }
                                }
                            }
                        } else {
                            Text("Connect")
                                .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                                .foregroundStyle(DesignTokens.Colors.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
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
                    Text("Add your rotating LHS schedule directly to Apple Calendar.")
                        .font(DesignTokens.Typography.quadCaption)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Primary: open .ics directly so iOS shows the native "Add to Calendar" dialog
                    Button {
                        openInCalendar()
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundStyle(DesignTokens.Colors.accent)
                            Text("Add to Apple Calendar")
                                .font(DesignTokens.Typography.quadBody)
                                .foregroundStyle(DesignTokens.Colors.accent)
                        }
                    }
                    .buttonStyle(.plain)

                    // Secondary: share sheet for other calendar apps
                    if let url = icsExportURL {
                        ShareLink(
                            item: url,
                            preview: SharePreview("LHS Schedule", image: Image(systemName: "calendar"))
                        ) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(DesignTokens.Colors.secondary)
                                Text("Share .ics File")
                                    .font(DesignTokens.Typography.quadCaption)
                                    .foregroundStyle(DesignTokens.Colors.secondary)
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
            if case .connected = classroomProvider.authState {
                ClassroomIntegrationSheet()
            } else {
                ClassroomConnectView()
            }
        }
        .sheet(isPresented: $showAspenSheet) {
            AspenConnectedSheet()
        }
        .sheet(isPresented: $showAspenConnectSheet) {
            AspenConnectView()
        }
        .alert("Couldn't Open Calendar", isPresented: $showCalendarOpenFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("iOS couldn't open the .ics file. Make sure the Calendar app is installed.")
        }
    }

    @ViewBuilder
    private var classroomBadge: some View {
        switch classroomProvider.authState {
        case .connected(let email, _):
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
                VStack(alignment: .trailing, spacing: 0) {
                    Text("Connected")
                        .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                        .foregroundStyle(.green)
                    Text(email)
                        .font(.system(size: 10))
                        .foregroundStyle(DesignTokens.Colors.secondary)
                        .lineLimit(1)
                }
            }
        case .blockedBySchoolPolicy:
            Text("Policy Blocked")
                .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                .foregroundStyle(.orange)
        case .notConfigured:
            Text("Setup Required")
                .font(DesignTokens.Typography.quadCaption)
                .foregroundStyle(DesignTokens.Colors.secondary)
        default:
            Text("Connect")
                .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.accent)
        }
    }

    /// Opens the .ics file directly in iOS Calendar — shows the native "Add to Calendar" dialog.
    private func openInCalendar() {
        guard let url = buildICSFile() else { return }
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                showCalendarOpenFailed = true
            }
        }
    }

    @discardableResult
    private func buildICSFile() -> URL? {
        let engine = appState.scheduleEngine
        let today = Date()
        guard let sixMonths = Calendar.current.date(byAdding: .month, value: 6, to: today) else { return nil }

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
            return tempURL
        } catch {
            return nil
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

// MARK: - Aspen connected sheet (shown when Aspen is connected)

struct AspenConnectedSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var aspenProvider = AspenGradeProvider.shared
    @State private var showDisconnectAlert = false

    private func gradeColor(_ letter: String) -> Color {
        switch letter {
        case "A", "A+", "A-": return .green
        case "B+", "B", "B-": return DesignTokens.Colors.accent
        case "C+", "C", "C-": return .orange
        default: return .red
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.Colors.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                        // Header
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            HStack(spacing: DesignTokens.Spacing.md) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(DesignTokens.Colors.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Aspen Grades")
                                        .font(DesignTokens.Typography.quadTitle)
                                        .foregroundStyle(DesignTokens.Colors.primary)
                                    Text("Live grade sync")
                                        .font(DesignTokens.Typography.quadCaption)
                                        .foregroundStyle(DesignTokens.Colors.secondary)
                                }
                            }

                            HStack(spacing: DesignTokens.Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Connected to Aspen")
                                    .font(DesignTokens.Typography.quadCaption.weight(.medium))
                                    .foregroundStyle(.green)
                            }
                            .padding(.horizontal, DesignTokens.Spacing.md)
                            .padding(.vertical, DesignTokens.Spacing.sm)
                            .background(Color.green.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
                        }

                        // Grade list
                        if aspenProvider.courses.isEmpty {
                            VStack(spacing: DesignTokens.Spacing.sm) {
                                Image(systemName: "tray")
                                    .font(.system(size: 32))
                                    .foregroundStyle(DesignTokens.Colors.secondary)
                                Text("No grades synced yet")
                                    .font(DesignTokens.Typography.quadBody)
                                    .foregroundStyle(DesignTokens.Colors.secondary)
                                Button("Refresh Now") {
                                    Task { await aspenProvider.refresh() }
                                }
                                .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                                .foregroundStyle(DesignTokens.Colors.accent)
                                .buttonStyle(.plain)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(DesignTokens.Spacing.xl)
                            .background(DesignTokens.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
                        } else {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                                HStack {
                                    Text("Grade Summary")
                                        .font(DesignTokens.Typography.quadHeadline.weight(.semibold))
                                        .foregroundStyle(DesignTokens.Colors.primary)
                                    Spacer()
                                    if let syncDate = aspenProvider.lastSyncDate {
                                        Text(syncDate, style: .relative)
                                            .font(DesignTokens.Typography.quadCaption)
                                            .foregroundStyle(DesignTokens.Colors.secondary)
                                    }
                                }

                                ForEach(Array(aspenProvider.courses.enumerated()), id: \.offset) { i, grade in
                                    let letter = grade.letterGrade ??
                                        (grade.currentGrade.map { GradeEngine.letterGrade(from: $0) } ?? "—")
                                    let pctStr = grade.currentGrade.map { String(format: "%.1f%%", $0) } ?? "—"
                                    HStack(spacing: DesignTokens.Spacing.md) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Course \(i + 1)")
                                                .font(DesignTokens.Typography.quadBody.weight(.medium))
                                                .foregroundStyle(DesignTokens.Colors.primary)
                                            Text(pctStr)
                                                .font(DesignTokens.Typography.quadCaption)
                                                .foregroundStyle(DesignTokens.Colors.secondary)
                                        }
                                        Spacer()
                                        Text(letter)
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundStyle(gradeColor(letter))
                                            .frame(minWidth: 36, alignment: .trailing)
                                    }
                                    .padding(.vertical, 4)
                                    if i < aspenProvider.courses.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                            .padding(DesignTokens.Spacing.lg)
                            .background(DesignTokens.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
                        }

                        // Refresh button
                        Button {
                            Task { await aspenProvider.refresh() }
                        } label: {
                            HStack {
                                Spacer()
                                if case .connecting = aspenProvider.connectionState {
                                    ProgressView()
                                        .scaleEffect(0.9)
                                        .tint(DesignTokens.Colors.accent)
                                    Text("Refreshing…")
                                        .font(DesignTokens.Typography.quadBody)
                                        .foregroundStyle(DesignTokens.Colors.accent)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundStyle(DesignTokens.Colors.accent)
                                    Text("Refresh Grades")
                                        .font(DesignTokens.Typography.quadBody)
                                        .foregroundStyle(DesignTokens.Colors.accent)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)

                        // Disconnect
                        Button {
                            showDisconnectAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Disconnect")
                                    .font(DesignTokens.Typography.quadBody.weight(.semibold))
                                    .foregroundStyle(.red)
                                Spacer()
                            }
                            .padding(DesignTokens.Spacing.lg)
                            .background(Color.red.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
                        }
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
            .alert("Disconnect Aspen?", isPresented: $showDisconnectAlert) {
                Button("Disconnect", role: .destructive) {
                    aspenProvider.disconnect()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your grades will no longer sync automatically. Credentials are removed from this device immediately.")
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
