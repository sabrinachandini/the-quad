import Foundation
import Observation

@Observable
final class GradesViewModel {

    var grades: [CourseGrade] {
        get { AppState.shared.grades }
        set { AppState.shared.grades = newValue }
    }

    var selectedCourseGradeId: UUID? = nil

    var selectedGrade: CourseGrade? {
        guard let id = selectedCourseGradeId else { return nil }
        return grades.first { $0.id == id }
    }

    // MARK: - What-If State

    var hypotheticalScore: String = ""
    var hypotheticalPossible: String = ""
    var hypotheticalCategoryId: UUID? = nil
    var targetGradePercent: Double = 90.0

    // MARK: - Computed What-If Grade

    var whatIfGrade: Double? {
        guard let grade = selectedGrade,
              let catId = hypotheticalCategoryId,
              let scoreVal = Double(hypotheticalScore),
              let possibleVal = Double(hypotheticalPossible),
              possibleVal > 0 else { return nil }

        var mutatedGrade = grade
        mutatedGrade.categories = grade.categories.map { cat in
            if cat.id == catId {
                var mutCat = cat
                let hypoEntry = GradeEntry(
                    id: UUID(),
                    title: "What-If",
                    pointsEarned: scoreVal,
                    pointsPossible: possibleVal,
                    isDropped: false,
                    date: nil,
                    provenance: .student
                )
                mutCat.entries.append(hypoEntry)
                return mutCat
            }
            return cat
        }
        return GradeEngine.overallPercentage(mutatedGrade)
    }

    // MARK: - Helpers

    func overallPercentage(for grade: CourseGrade) -> Double? {
        GradeEngine.overallPercentage(grade)
    }

    func letterGrade(for grade: CourseGrade) -> String {
        guard let pct = overallPercentage(for: grade) else { return "—" }
        return GradeEngine.letterGrade(from: pct)
    }

    func course(for grade: CourseGrade) -> Course? {
        AppState.shared.courses.first { $0.id == grade.courseId }
    }

    var isEmpty: Bool { grades.isEmpty }

    // MARK: - What-If Actions

    func applyWhatIf() {
        guard let grade = selectedGrade,
              let catId = hypotheticalCategoryId,
              let scoreVal = Double(hypotheticalScore),
              let possibleVal = Double(hypotheticalPossible),
              possibleVal > 0 else { return }

        if let gradeIdx = grades.firstIndex(where: { $0.id == grade.id }),
           let catIdx = grades[gradeIdx].categories.firstIndex(where: { $0.id == catId }) {
            let newEntry = GradeEntry(
                id: UUID(),
                title: "What-If Entry",
                pointsEarned: scoreVal,
                pointsPossible: possibleVal,
                isDropped: false,
                date: nil,
                provenance: .student
            )
            grades[gradeIdx].categories[catIdx].entries.append(newEntry)
        }
        clearWhatIf()
    }

    func clearWhatIf() {
        hypotheticalScore = ""
        hypotheticalPossible = ""
        hypotheticalCategoryId = nil
    }

    // MARK: - Mock Data

    static func mockGrades() -> [CourseGrade] {
        func entry(_ title: String, _ earned: Double, _ possible: Double = 100) -> GradeEntry {
            GradeEntry(id: UUID(), title: title, pointsEarned: earned, pointsPossible: possible,
                       isDropped: false, date: nil, provenance: .aspen)
        }

        return [
            // AP Chemistry — Tests 50%, Homework 30%, Labs 20%
            CourseGrade(
                id: UUID(),
                courseId: MockStudentSchedule.apChemistry.id,
                currentGrade: nil,
                letterGrade: nil,
                categories: [
                    GradeCategory(id: UUID(), name: "Tests", weight: 0.50, entries: [
                        entry("Unit 1 Test", 88),
                        entry("Unit 2 Test", 92),
                        entry("Unit 3 Test", 79)
                    ]),
                    GradeCategory(id: UUID(), name: "Homework", weight: 0.30, entries: [
                        entry("HW Set 1", 95),
                        entry("HW Set 2", 88),
                        entry("HW Set 3", 100),
                        entry("HW Set 4", 78)
                    ]),
                    GradeCategory(id: UUID(), name: "Labs", weight: 0.20, entries: [
                        entry("Lab 1", 90),
                        entry("Lab 2", 85)
                    ])
                ],
                provenance: .aspen
            ),

            // AP US History — Essays 60%, Participation 40%
            CourseGrade(
                id: UUID(),
                courseId: MockStudentSchedule.apUSHistory.id,
                currentGrade: nil,
                letterGrade: nil,
                categories: [
                    GradeCategory(id: UUID(), name: "Essays", weight: 0.60, entries: [
                        entry("DBQ Essay", 91),
                        entry("LEQ Essay", 87)
                    ]),
                    GradeCategory(id: UUID(), name: "Participation", weight: 0.40, entries: [
                        entry("Q1 Participation", 95)
                    ])
                ],
                provenance: .aspen
            ),

            // Orchestra — Performance 100%
            CourseGrade(
                id: UUID(),
                courseId: MockStudentSchedule.orchestra.id,
                currentGrade: nil,
                letterGrade: nil,
                categories: [
                    GradeCategory(id: UUID(), name: "Performance", weight: 1.00, entries: [
                        entry("Fall Concert", 98),
                        entry("Chair Audition", 94)
                    ])
                ],
                provenance: .aspen
            ),

            // English 11 — Essays 50%, Reading 30%, Discussion 20%
            CourseGrade(
                id: UUID(),
                courseId: MockStudentSchedule.english11.id,
                currentGrade: nil,
                letterGrade: nil,
                categories: [
                    GradeCategory(id: UUID(), name: "Essays", weight: 0.50, entries: [
                        entry("Analytical Essay 1", 85),
                        entry("Analytical Essay 2", 89)
                    ]),
                    GradeCategory(id: UUID(), name: "Reading", weight: 0.30, entries: [
                        entry("Reading Quiz 1", 92),
                        entry("Reading Quiz 2", 88),
                        entry("Reading Quiz 3", 95)
                    ]),
                    GradeCategory(id: UUID(), name: "Discussion", weight: 0.20, entries: [
                        entry("Socratic Seminar", 90)
                    ])
                ],
                provenance: .aspen
            ),

            // Pre-Calculus — Tests 60%, Homework 30%, Quizzes 10%
            CourseGrade(
                id: UUID(),
                courseId: MockStudentSchedule.preCalculus.id,
                currentGrade: nil,
                letterGrade: nil,
                categories: [
                    GradeCategory(id: UUID(), name: "Tests", weight: 0.60, entries: [
                        entry("Test 1: Functions", 94),
                        entry("Test 2: Trig", 88)
                    ]),
                    GradeCategory(id: UUID(), name: "Homework", weight: 0.30, entries: [
                        entry("HW 1", 100),
                        entry("HW 2", 95),
                        entry("HW 3", 88),
                        entry("HW 4", 92)
                    ]),
                    GradeCategory(id: UUID(), name: "Quizzes", weight: 0.10, entries: [
                        entry("Quiz 1", 85),
                        entry("Quiz 2", 90),
                        entry("Quiz 3", 78)
                    ])
                ],
                provenance: .aspen
            ),

            // Spanish IV — Speaking 40%, Written 60%
            CourseGrade(
                id: UUID(),
                courseId: MockStudentSchedule.spanishIV.id,
                currentGrade: nil,
                letterGrade: nil,
                categories: [
                    GradeCategory(id: UUID(), name: "Speaking", weight: 0.40, entries: [
                        entry("Oral Presentation 1", 92),
                        entry("Oral Presentation 2", 88)
                    ]),
                    GradeCategory(id: UUID(), name: "Written", weight: 0.60, entries: [
                        entry("Written Exam 1", 85),
                        entry("Written Exam 2", 90),
                        entry("Written Exam 3", 78)
                    ])
                ],
                provenance: .aspen
            )
        ]
    }
}
