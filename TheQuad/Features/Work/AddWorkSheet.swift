import SwiftUI

struct AddWorkSheet: View {
    @Environment(\.dismiss) private var dismiss
    var model: WorkViewModel

    @State private var title: String = ""
    @State private var taskType: TaskType = .assignment
    @State private var selectedCourseId: UUID? = nil
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400)
    @State private var estimatedMinutes: Int = 30
    @State private var notes: String = ""

    @State private var showCoursePicker = false
    @State private var showDatePicker = false
    @State private var showDurationPicker = false
    @State private var showTypePicker = false

    @FocusState private var titleFocused: Bool

    private let estimateOptions: [(label: String, minutes: Int)] = [
        ("15m", 15), ("30m", 30), ("45m", 45), ("1h", 60), ("1.5h", 90), ("2h+", 120)
    ]

    private var selectedCourse: Course? {
        AppState.shared.courses.first { $0.id == selectedCourseId }
    }

    private var courseChipLabel: String {
        selectedCourse?.name ?? "Course"
    }

    private var dateChipLabel: String {
        guard hasDueDate else { return "Due date" }
        let cal = Calendar.current
        let today = Date()
        if cal.isDate(dueDate, inSameDayAs: today) { return "Today" }
        if cal.isDate(dueDate, inSameDayAs: cal.date(byAdding: .day, value: 1, to: today) ?? today) { return "Tomorrow" }
        return dueDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    private var durationChipLabel: String {
        estimateOptions.first { $0.minutes == estimatedMinutes }?.label ?? "\(estimatedMinutes)m"
    }

    private var typeChipLabel: String {
        taskType.rawValue.capitalized
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.Colors.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 0) {

                    // Large title input
                    TextField("What's due?", text: $title, axis: .vertical)
                        .font(DesignTokens.Typography.quadHeadline)
                        .foregroundStyle(DesignTokens.Colors.primary)
                        .focused($titleFocused)
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        .padding(.top, DesignTokens.Spacing.xl)
                        .padding(.bottom, DesignTokens.Spacing.lg)

                    Divider()
                        .overlay(DesignTokens.Colors.secondary.opacity(0.3))
                        .padding(.horizontal, DesignTokens.Spacing.lg)

                    // Chip row
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            chip(
                                label: courseChipLabel,
                                isSet: selectedCourseId != nil
                            ) { showCoursePicker = true }

                            chip(
                                label: dateChipLabel,
                                isSet: hasDueDate
                            ) { showDatePicker = true }

                            chip(
                                label: durationChipLabel,
                                isSet: true
                            ) { showDurationPicker = true }

                            chip(
                                label: typeChipLabel,
                                isSet: taskType != .assignment
                            ) { showTypePicker = true }
                        }
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        .padding(.vertical, DesignTokens.Spacing.lg)
                    }

                    Divider()
                        .overlay(DesignTokens.Colors.secondary.opacity(0.3))
                        .padding(.horizontal, DesignTokens.Spacing.lg)

                    // Optional notes
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .font(DesignTokens.Typography.quadBody)
                        .foregroundStyle(DesignTokens.Colors.primary)
                        .lineLimit(3, reservesSpace: true)
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        .padding(.top, DesignTokens.Spacing.md)

                    Spacer()

                    // Add button
                    Button {
                        saveAndDismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("ADD")
                                .font(DesignTokens.Typography.quadLabel)
                                .foregroundStyle(
                                    title.trimmingCharacters(in: .whitespaces).isEmpty
                                        ? DesignTokens.Colors.secondary
                                        : DesignTokens.Colors.background
                                )
                            Spacer()
                        }
                        .padding(.vertical, DesignTokens.Spacing.lg)
                        .background(
                            title.trimmingCharacters(in: .whitespaces).isEmpty
                                ? DesignTokens.Colors.surface
                                : DesignTokens.Colors.accent
                        )
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    .animation(DesignTokens.Animations.standard, value: title.isEmpty)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DesignTokens.Colors.secondary)
                }
            }
            .onAppear {
                titleFocused = true
            }
            // Course picker sheet
            .sheet(isPresented: $showCoursePicker) {
                coursePicker
            }
            // Date picker sheet
            .sheet(isPresented: $showDatePicker) {
                datePicker
            }
            // Duration picker sheet
            .sheet(isPresented: $showDurationPicker) {
                durationPicker
            }
            // Type picker sheet
            .sheet(isPresented: $showTypePicker) {
                typePicker
            }
        }
    }

    // MARK: - Chip

    private func chip(label: String, isSet: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(DesignTokens.Typography.quadCaption)
                .foregroundStyle(isSet ? DesignTokens.Colors.accent : DesignTokens.Colors.secondary)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(DesignTokens.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
        }
    }

    // MARK: - Sub-sheets

    private var coursePicker: some View {
        NavigationStack {
            ZStack {
                DesignTokens.Colors.background.ignoresSafeArea()
                List {
                    Button {
                        selectedCourseId = nil
                        showCoursePicker = false
                    } label: {
                        HStack {
                            Text("No course")
                                .font(DesignTokens.Typography.quadBody)
                                .foregroundStyle(DesignTokens.Colors.secondary)
                            Spacer()
                            if selectedCourseId == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(DesignTokens.Colors.accent)
                            }
                        }
                    }
                    ForEach(AppState.shared.courses) { course in
                        Button {
                            selectedCourseId = course.id
                            showCoursePicker = false
                        } label: {
                            HStack(spacing: DesignTokens.Spacing.md) {
                                Circle()
                                    .fill(CourseColors.color(atIndex: course.colorIndex))
                                    .frame(width: 10, height: 10)
                                Text(course.name)
                                    .font(DesignTokens.Typography.quadBody)
                                    .foregroundStyle(DesignTokens.Colors.primary)
                                Spacer()
                                if selectedCourseId == course.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(DesignTokens.Colors.accent)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showCoursePicker = false }
                }
            }
        }
    }

    private var datePicker: some View {
        NavigationStack {
            ZStack {
                DesignTokens.Colors.background.ignoresSafeArea()
                VStack(spacing: DesignTokens.Spacing.xl) {
                    Toggle("Has due date", isOn: $hasDueDate)
                        .font(DesignTokens.Typography.quadBody)
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        .padding(.top, DesignTokens.Spacing.xl)

                    if hasDueDate {
                        DatePicker("", selection: $dueDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                    }
                    Spacer()
                }
            }
            .navigationTitle("Due Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showDatePicker = false }
                }
            }
        }
    }

    private var durationPicker: some View {
        NavigationStack {
            ZStack {
                DesignTokens.Colors.background.ignoresSafeArea()
                List {
                    ForEach(estimateOptions, id: \.minutes) { opt in
                        Button {
                            estimatedMinutes = opt.minutes
                            showDurationPicker = false
                        } label: {
                            HStack {
                                Text(opt.label)
                                    .font(DesignTokens.Typography.quadBody)
                                    .foregroundStyle(DesignTokens.Colors.primary)
                                Spacer()
                                if estimatedMinutes == opt.minutes {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(DesignTokens.Colors.accent)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Estimated Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showDurationPicker = false }
                }
            }
        }
    }

    private var typePicker: some View {
        NavigationStack {
            ZStack {
                DesignTokens.Colors.background.ignoresSafeArea()
                List {
                    ForEach(TaskType.allCases, id: \.self) { type in
                        Button {
                            taskType = type
                            showTypePicker = false
                        } label: {
                            HStack {
                                Text(type.rawValue.capitalized)
                                    .font(DesignTokens.Typography.quadBody)
                                    .foregroundStyle(DesignTokens.Colors.primary)
                                Spacer()
                                if taskType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(DesignTokens.Colors.accent)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showTypePicker = false }
                }
            }
        }
    }

    // MARK: - Save

    private func saveAndDismiss() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let a = Assignment(
            id: UUID(),
            title: trimmed,
            description: notes.isEmpty ? nil : notes,
            courseId: selectedCourseId,
            dueDate: hasDueDate ? dueDate : nil,
            classroomURL: nil,
            submissionState: .notStarted,
            estimatedMinutes: estimatedMinutes,
            provenance: .student,
            isCompleted: false
        )
        model.addAssignment(a)
        dismiss()
    }
}
