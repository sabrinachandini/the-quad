import Foundation
import Observation
import UIKit

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
            // Use the actual Mon–Sun calendar week, not a rolling 7-day window.
            let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? startOfToday
            let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart) ?? startOfNextWeek
            filtered = assignments.filter { a in
                guard !a.isCompleted, let due = a.dueDate else { return false }
                let startOfDue = cal.startOfDay(for: due)
                return startOfDue >= startOfToday && startOfDue < weekEnd
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
            if AppState.shared.assignments[idx].isCompleted {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
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
        // Anchor to Sept 8, 2026 (first day of 2026-27 school year, Day 1)
        let anchor = cal.date(from: DateComponents(year: 2026, month: 9, day: 8, hour: 10)) ?? Date()
        func due(_ days: Int, _ hour: Int) -> Date {
            cal.date(byAdding: .day, value: days, to:
                cal.date(bySettingHour: hour, minute: 59, second: 0, of: anchor) ?? anchor) ?? anchor
        }
        return [
            Assignment(
                id: UUID(), title: "Trig Functions Problem Set",
                description: "Section 4.1–4.3, odds only",
                courseId: MockStudentSchedule.math3.id,
                dueDate: due(0, 23), classroomURL: nil,
                submissionState: .notStarted, estimatedMinutes: 40,
                provenance: .classroom, isCompleted: false
            ),
            Assignment(
                id: UUID(), title: "Spanish III Vocab Quiz",
                description: "Unidad 2 vocabulary list",
                courseId: MockStudentSchedule.spanishIII.id,
                dueDate: due(1, 8), classroomURL: nil,
                submissionState: .notStarted, estimatedMinutes: 20,
                provenance: .classroom, isCompleted: false
            ),
            Assignment(
                id: UUID(), title: "World History Chapter 3 Reading",
                description: "Causes of WWI, pp. 58–74 — annotate",
                courseId: MockStudentSchedule.worldHistory.id,
                dueDate: due(2, 8), classroomURL: nil,
                submissionState: .inProgress, estimatedMinutes: 35,
                provenance: .classroom, isCompleted: false
            ),
            Assignment(
                id: UUID(), title: "Analytical Essay Draft",
                description: "Thesis + 2 body paragraphs",
                courseId: MockStudentSchedule.litAndComp.id,
                dueDate: due(3, 23), classroomURL: nil,
                submissionState: .notStarted, estimatedMinutes: 75,
                provenance: .classroom, isCompleted: false
            ),
            Assignment(
                id: UUID(), title: "Biology Lab Report",
                description: "Cell membrane diffusion lab",
                courseId: MockStudentSchedule.biology.id,
                dueDate: due(5, 23), classroomURL: nil,
                submissionState: .notStarted, estimatedMinutes: 60,
                provenance: .classroom, isCompleted: false
            ),
            Assignment(
                id: UUID(), title: "Economics Supply & Demand Graph",
                description: "Draw and label equilibrium scenarios",
                courseId: MockStudentSchedule.economics.id,
                dueDate: due(7, 8), classroomURL: nil,
                submissionState: .notStarted, estimatedMinutes: 30,
                provenance: .student, isCompleted: false
            ),
        ]
    }
}
