import Foundation
import Observation

@Observable
final class GradesViewModel {
    var grades: [CourseGrade]

    init(grades: [CourseGrade]? = nil) {
        self.grades = grades ?? GradesViewModel.mockGrades()
    }

    var isEmpty: Bool { grades.isEmpty }

    func course(for grade: CourseGrade) -> Course? {
        MockStudentSchedule.courses.first { $0.id == grade.courseId }
    }

    static func mockGrades() -> [CourseGrade] {
        func entry(_ title: String, _ earned: Double, _ possible: Double) -> GradeEntry {
            GradeEntry(id: UUID(), title: title, pointsEarned: earned, pointsPossible: possible, isDropped: false, date: nil, provenance: .aspen)
        }
        return [
            CourseGrade(id: UUID(), courseId: MockStudentSchedule.apChemistry.id, currentGrade: 91.5, letterGrade: "A-", categories: [
                GradeCategory(id: UUID(), name: "Tests", weight: 0.6, entries: [entry("Unit 1 Test", 88, 100), entry("Unit 2 Test", 94, 100)]),
                GradeCategory(id: UUID(), name: "Homework", weight: 0.4, entries: [entry("PSet 1", 10, 10), entry("PSet 2", 9, 10)])
            ], provenance: .aspen),
            CourseGrade(id: UUID(), courseId: MockStudentSchedule.apUSHistory.id, currentGrade: 87.0, letterGrade: "B+", categories: [
                GradeCategory(id: UUID(), name: "Essays", weight: 0.5, entries: [entry("DBQ 1", 85, 100)]),
                GradeCategory(id: UUID(), name: "Quizzes", weight: 0.5, entries: [entry("Quiz 1", 18, 20), entry("Quiz 2", 17, 20)])
            ], provenance: .aspen),
            CourseGrade(id: UUID(), courseId: MockStudentSchedule.preCalculus.id, currentGrade: 94.2, letterGrade: "A", categories: [
                GradeCategory(id: UUID(), name: "Tests", weight: 0.7, entries: [entry("Test 1", 95, 100)]),
                GradeCategory(id: UUID(), name: "Homework", weight: 0.3, entries: [entry("HW Avg", 92, 100)])
            ], provenance: .aspen)
        ]
    }
}
