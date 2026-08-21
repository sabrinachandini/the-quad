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

    private let estimateOptions: [(label: String, minutes: Int)] = [
        ("15m", 15), ("30m", 30), ("45m", 45), ("1h", 60), ("1.5h", 90), ("2h+", 120)
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .font(DesignTokens.Typography.quadBody)
                }

                Section("Type") {
                    Picker("Type", selection: $taskType) {
                        ForEach(TaskType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Course") {
                    Picker("Course", selection: $selectedCourseId) {
                        Text("No course").tag(Optional<UUID>.none)
                        ForEach(AppState.shared.courses) { course in
                            Text(course.name).tag(Optional(course.id))
                        }
                    }
                }

                Section("Due Date") {
                    Toggle("Has due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                }

                Section("Estimated Time") {
                    Picker("Time", selection: $estimatedMinutes) {
                        ForEach(estimateOptions, id: \.minutes) { opt in
                            Text(opt.label).tag(opt.minutes)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("New Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let a = Assignment(
                            id: UUID(),
                            title: title.trimmingCharacters(in: .whitespaces),
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
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
