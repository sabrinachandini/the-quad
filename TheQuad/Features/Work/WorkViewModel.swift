import Foundation
import Observation

@Observable
final class WorkViewModel {
    var assignments: [Assignment]

    init(assignments: [Assignment]? = nil) {
        self.assignments = assignments ?? WorkViewModel.mockAssignments()
    }

    /// Assignments grouped by due day, sorted by due date. Undated go last.
    var groupedByDueDate: [(date: Date?, items: [Assignment])] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: assignments.filter { !$0.isCompleted }) { assignment -> Date? in
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

    var isEmpty: Bool { assignments.allSatisfy { $0.isCompleted } }

    func toggleComplete(_ assignment: Assignment) {
        if let idx = assignments.firstIndex(where: { $0.id == assignment.id }) {
            assignments[idx].isCompleted.toggle()
        }
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
