import SwiftUI
import EventKit

struct MeView: View {
    @State private var appState = AppState.shared
    @State private var showClassroomSheet = false
    @State private var showAspenSheet = false
    @State private var calendarSyncState: CalendarSyncState = .idle

    enum CalendarSyncState {
        case idle, syncing, done, denied, failed(String)
    }

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
                        Text("Class of \(String(appState.graduationYear)) · LHS")
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
                        if appState.classroomConnected {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                Text("Connected")
                                    .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                                    .foregroundStyle(.green)
                            }
                        } else {
                            Text("Connect")
                                .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                                .foregroundStyle(DesignTokens.Colors.accent)
                        }
                    }
                }
                .buttonStyle(.plain)

                // Aspen Grades row
                Button {
                    showAspenSheet = true
                } label: {
                    HStack {
                        Label("Aspen Grades", systemImage: "chart.bar.fill")
                            .font(DesignTokens.Typography.quadBody)
                            .foregroundStyle(DesignTokens.Colors.primary)
                        Spacer()
                        Text("Connect")
                            .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                            .foregroundStyle(DesignTokens.Colors.accent)
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

            // MARK: - Calendar
            Section {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Add your rotating schedule to Apple Calendar. The Quad keeps it updated automatically.")
                        .font(DesignTokens.Typography.quadCaption)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    switch calendarSyncState {
                    case .idle:
                        Button { syncCalendar() } label: {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                    .foregroundStyle(DesignTokens.Colors.accent)
                                Text("Add to Apple Calendar")
                                    .font(DesignTokens.Typography.quadBody)
                                    .foregroundStyle(DesignTokens.Colors.accent)
                            }
                        }
                        .buttonStyle(.plain)

                    case .syncing:
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Syncing schedule…")
                                .font(DesignTokens.Typography.quadBody)
                                .foregroundStyle(DesignTokens.Colors.secondary)
                        }

                    case .done:
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Schedule synced to Calendar")
                                .font(DesignTokens.Typography.quadBody)
                                .foregroundStyle(DesignTokens.Colors.primary)
                        }
                        Button { syncCalendar() } label: {
                            Text("Sync again")
                                .font(DesignTokens.Typography.quadCaption)
                                .foregroundStyle(DesignTokens.Colors.accent)
                        }
                        .buttonStyle(.plain)

                    case .denied:
                        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundStyle(.orange)
                            Text("Calendar access denied. Enable it in Settings → Privacy → Calendars.")
                                .font(DesignTokens.Typography.quadCaption)
                                .foregroundStyle(DesignTokens.Colors.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                    case .failed(let msg):
                        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                            Text(msg)
                                .font(DesignTokens.Typography.quadCaption)
                                .foregroundStyle(DesignTokens.Colors.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Button { syncCalendar() } label: {
                            Text("Try again")
                                .font(DesignTokens.Typography.quadCaption)
                                .foregroundStyle(DesignTokens.Colors.accent)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.xs)
            } header: {
                sectionHeader("Calendar")
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

    private func syncCalendar() {
        calendarSyncState = .syncing
        let courses = appState.courses
        let enrollments = appState.enrollments
        let engine = appState.scheduleEngine
        Task {
            do {
                let result = try await CalendarSync.shared.sync(
                    courses: courses,
                    enrollments: enrollments,
                    engine: engine
                )
                await MainActor.run {
                    calendarSyncState = result == .denied ? .denied : .done
                }
            } catch {
                await MainActor.run {
                    calendarSyncState = .failed(error.localizedDescription)
                }
            }
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
    @State private var appState = AppState.shared
    @State private var showDisconnectAlert = false

    private let syncTime = "Today, 10:00 AM"

    private var connectedCourses: [(name: String, badge: String)] {
        appState.courses.map { course in
            let badge: String
            switch course.provenance {
            case .classroom: badge = "Classroom"
            default: badge = "Classroom"
            }
            return (name: course.name, badge: badge)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.Colors.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                        // Connected header
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
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

                            HStack(spacing: DesignTokens.Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Connected as sbhattacharjya@lps.lexingtonma.org")
                                    .font(DesignTokens.Typography.quadCaption.weight(.medium))
                                    .foregroundStyle(.green)
                            }
                            .padding(.horizontal, DesignTokens.Spacing.md)
                            .padding(.vertical, DesignTokens.Spacing.sm)
                            .background(Color.green.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
                        }

                        // Synced courses list
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            HStack {
                                Text("Synced Courses")
                                    .font(DesignTokens.Typography.quadHeadline.weight(.semibold))
                                    .foregroundStyle(DesignTokens.Colors.primary)
                                Spacer()
                                Text("\(connectedCourses.count) courses")
                                    .font(DesignTokens.Typography.quadCaption)
                                    .foregroundStyle(DesignTokens.Colors.secondary)
                            }

                            ForEach(Array(connectedCourses.enumerated()), id: \.offset) { _, item in
                                HStack(spacing: DesignTokens.Spacing.md) {
                                    Image(systemName: "book.closed.fill")
                                        .foregroundStyle(DesignTokens.Colors.accent)
                                        .frame(width: 20)
                                    Text(item.name)
                                        .font(DesignTokens.Typography.quadBody)
                                        .foregroundStyle(DesignTokens.Colors.primary)
                                    Spacer()
                                    Text(item.badge)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(DesignTokens.Colors.accent)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(DesignTokens.Colors.accent.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                                .padding(.vertical, 4)
                                if item.name != connectedCourses.last?.name {
                                    Divider()
                                }
                            }
                        }
                        .padding(DesignTokens.Spacing.lg)
                        .background(DesignTokens.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))

                        // Last synced
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(DesignTokens.Colors.secondary)
                                .font(.caption)
                            Text("Last synced: \(syncTime)")
                                .font(DesignTokens.Typography.quadCaption)
                                .foregroundStyle(DesignTokens.Colors.secondary)
                        }

                        // Disconnect button
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
            .navigationTitle("Classroom")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DesignTokens.Colors.accent)
                }
            }
            .alert("Disconnect Classroom?", isPresented: $showDisconnectAlert) {
                Button("Disconnect", role: .destructive) {
                    appState.classroomConnected = false
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Assignments synced from Classroom will remain, but won't update automatically.")
            }
        }
    }
}

// MARK: - Aspen integration sheet

struct AspenIntegrationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var appState = AppState.shared
    @State private var showDisconnectAlert = false

    private let syncTime = "Today, 10:00 AM"

    private var gradeRows: [(courseName: String, letterGrade: String, percentage: String)] {
        appState.grades.compactMap { grade in
            guard let course = appState.courses.first(where: { $0.id == grade.courseId }) else { return nil }
            let pct = GradeEngine.overallPercentage(grade)
            let letter = pct.map { GradeEngine.letterGrade(from: $0) } ?? "—"
            let pctStr = pct.map { String(format: "%.1f%%", $0) } ?? "—"
            return (courseName: course.name, letterGrade: letter, percentage: pctStr)
        }
    }

    private func gradeColor(_ letter: String) -> Color {
        switch letter {
        case "A", "A-": return .green
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
                        // Connected header
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

                        // Grade summary list
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            HStack {
                                Text("Grade Summary")
                                    .font(DesignTokens.Typography.quadHeadline.weight(.semibold))
                                    .foregroundStyle(DesignTokens.Colors.primary)
                                Spacer()
                                Text("Q1 2026–27")
                                    .font(DesignTokens.Typography.quadCaption)
                                    .foregroundStyle(DesignTokens.Colors.secondary)
                            }

                            ForEach(Array(gradeRows.enumerated()), id: \.offset) { _, row in
                                HStack(spacing: DesignTokens.Spacing.md) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(row.courseName)
                                            .font(DesignTokens.Typography.quadBody.weight(.medium))
                                            .foregroundStyle(DesignTokens.Colors.primary)
                                        Text(row.percentage)
                                            .font(DesignTokens.Typography.quadCaption)
                                            .foregroundStyle(DesignTokens.Colors.secondary)
                                    }
                                    Spacer()
                                    Text(row.letterGrade)
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundStyle(gradeColor(row.letterGrade))
                                        .frame(minWidth: 36, alignment: .trailing)
                                }
                                .padding(.vertical, 4)
                                if row.courseName != gradeRows.last?.courseName {
                                    Divider()
                                }
                            }
                        }
                        .padding(DesignTokens.Spacing.lg)
                        .background(DesignTokens.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))

                        // Last synced
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(DesignTokens.Colors.secondary)
                                .font(.caption)
                            Text("Last synced: \(syncTime)")
                                .font(DesignTokens.Typography.quadCaption)
                                .foregroundStyle(DesignTokens.Colors.secondary)
                        }

                        // Disconnect button
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
                Button("Disconnect", role: .destructive) { dismiss() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your grades will no longer sync automatically. Existing data stays on your device.")
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
