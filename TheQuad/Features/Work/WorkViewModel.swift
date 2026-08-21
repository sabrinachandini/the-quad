import Foundation
import Observation

enum WorkFilter: String, CaseIterable {
    case all = "All"
    case today = "Today"
    case thisWeek = "This Week"
}

@Observable
final class WorkViewModel {
    var filter: WorkFilter = .all

    var assignments: [Assignment] {
        get { AppState.shared.assignments }
        set { AppState.shared.assignments = newValue }
    }

    init() {
        if AppState.shared.assignments.isEmpty {
            AppState.shared.assignments = WorkViewModel.mockAssignments()
        }
    }

    /// Assignments grouped by due day, sorted by due date, filtered by the current filter.
    /// Undated items go last (only shown in .all).
    var groupedByDueDate: [(date: Date?, items: [Assignment])] {
        let cal = Calendar.current
        let today = Date()
        let startOfToday = cal.startOfDay(for: today)
        let startOfNextWeek = cal.date(byAdding: .day, value: 7, to: startOfToday) ?? startOfToday

        let filtered: [Assignment]
        switch filter {
        case .all:
            filtered = assignments.filter { !$0.isCompleted }
        case .today:
            filtered = assignments.filter { a in
                guard !a.isCompleted, let due = a.dueDate else { return false }
                return cal.isDate(due, inSameDayAs: today)
            }
        case .thisWeek:
            filtered = assignments.filter { a in
                guard !a.isCompleted, let due = a.dueDate else { return false }
                let startOfDue = cal.startOfDay(for: due)
                return startOfDue >= startOfToday && startOfDue < startOfNextWeek
            }
        }

        let grouped = Dictionary(grouping: filtered) { assignment -> Date? in
            guard let due = assignment.dueDate else { return nil }
            return cal.startOfDay(for: due)
        }
        return grouped
            .sorted { lhs, rhs in
                switch (lhs.key, rhs.key) {
                case let (l?, r?): return l < r
                case (nil, _): return false
                case (_, nil): return true
                }
            }
            .map { (date: $0.key, items: $0.value.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }) }
    }

    var isEmpty: Bool {
        groupedByDueDate.isEmpty
    }

    var todayDueCount: Int {
        let cal = Calendar.current
        let today = Date()
        return AppState.shared.assignments.filter { a in
            !a.isCompleted && a.dueDate.map { cal.isDate($0, inSameDayAs: today) } ?? false
        }.count
    }

    func toggleComplete(_ assignment: Assignment) {
        if let idx = AppState.shared.assignments.firstIndex(where: { $0.id == assignment.id }) {
            AppState.shared.assignments[idx].isCompleted.toggle()
        }
    }

    func addAssignment(_ a: Assignment) {
        AppState.shared.assignments.append(a)
    }

    func deleteAssignment(_ a: Assignment) {
        AppState.shared.assignments.removeAll { $0.id == a.id }
    }

    func addStudentTask(_ t: StudentTask) {
        let a = Assignment(
            id: t.id,
            title: t.title,
            description: t.notes,
            courseId: t.courseId,
            dueDate: t.dueDate,
            classroomURL: nil,
            submissionState: .notStarted,
            estimatedMinutes: t.estimatedMinutes,
            provenance: .student,
            isCompleted: t.isCompleted
        )
        addAssignment(a)
    }

    static func mockAssignments() -> [Assignment] {
        let cal = Calendar.current
        let now = cal.date(from: DateComponents(year: 2025, month: 9, day: 4, hour: 10)) ?? Date()
        func due(_ days: Int, _ hour: Int) -> Date {
            cal.date(byAdding: .day, value: days, to: cal.date(bySettingHour: hour, minute: 0, second: 0, of: now) ?? now) ?? now
        }
        return [
            Assignment(id: UUID(), title: "Ch. 4 Problem Set", description: "Stoichiometry", courseId: MockStudentSchedule.apChemistry.id, dueDate: due(0, 15), classroomURL: nil, submissionState: .notStarted, estimatedMinutes: 45, provenance: .student, isCompleted: false),
            Assignment(id: UUID(), title: "DBQ Essay Draft", description: "Revolution causes", courseId: MockStudentSchedule.apUSHistory.id, dueDate: due(1, 8), classroomURL: nil, submissionState: .inProgress, estimatedMinutes: 90, provenance: .student, isCompleted: false),
            Assignment(id: UUID(), title: "Read Ch. 12", description: nil, courseId: MockStudentSchedule.english11.id, dueDate: due(1, 8), classroomURL: nil, submissionState: .notStarted, estimatedMinutes: 30, provenance: .student, isCompleted: false),
            Assignment(id: UUID(), title: "Problem Set 3", description: "Trig identities", courseId: MockStudentSchedule.preCalculus.id, dueDate: due(3, 8), classroomURL: nil, submissionState: .notStarted, estimatedMinutes: 40, provenance: .student, isCompleted: false)
        ]
    }
}
