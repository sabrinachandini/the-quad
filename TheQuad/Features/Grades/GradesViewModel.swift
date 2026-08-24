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
            // Repertoire Orch/Strings — Performance 100%
            CourseGrade(
                id: UUID(), courseId: MockStudentSchedule.orchestraStrings.id,
                name: MockStudentSchedule.orchestraStrings.name,
                currentGrade: nil, letterGrade: nil,
                categories: [
                    GradeCategory(id: UUID(), name: "Performance", weight: 1.00, entries: [
                        entry("Fall Audition", 96),
                        entry("Section Recording", 92),
                    ])
                ],
                provenance: .aspen
            ),

            // World History II — Essays 50%, Quizzes 30%, Participation 20%
            CourseGrade(
                id: UUID(), courseId: MockStudentSchedule.worldHistory.id,
                name: MockStudentSchedule.worldHistory.name,
                currentGrade: nil, letterGrade: nil,
                categories: [
                    GradeCategory(id: UUID(), name: "Essays", weight: 0.50, entries: [
                        entry("Document Analysis 1", 88),
                        entry("Thesis Paragraph", 91),
                    ]),
                    GradeCategory(id: UUID(), name: "Quizzes", weight: 0.30, entries: [
                        entry("Ch. 1 Quiz", 84),
                        entry("Ch. 2 Quiz", 90),
                    ]),
                    GradeCategory(id: UUID(), name: "Participation", weight: 0.20, entries: [
                        entry("Q1 Discussion", 95),
                    ])
                ],
                provenance: .aspen
            ),

            // Spanish III — Speaking 40%, Tests 40%, Homework 20%
            CourseGrade(
                id: UUID(), courseId: MockStudentSchedule.spanishIII.id,
                name: MockStudentSchedule.spanishIII.name,
                currentGrade: nil, letterGrade: nil,
                categories: [
                    GradeCategory(id: UUID(), name: "Speaking", weight: 0.40, entries: [
                        entry("Oral Presentation 1", 94),
                    ]),
                    GradeCategory(id: UUID(), name: "Tests", weight: 0.40, entries: [
                        entry("Unidad 1 Test", 87),
                        entry("Unidad 2 Test", 91),
                    ]),
                    GradeCategory(id: UUID(), name: "Homework", weight: 0.20, entries: [
                        entry("HW 1–4", 98),
                        entry("HW 5–8", 94),
                    ])
                ],
                provenance: .aspen
            ),

            // Biology — Tests 50%, Labs 30%, Homework 20%
            CourseGrade(
                id: UUID(), courseId: MockStudentSchedule.biology.id,
                name: MockStudentSchedule.biology.name,
                currentGrade: nil, letterGrade: nil,
                categories: [
                    GradeCategory(id: UUID(), name: "Tests", weight: 0.50, entries: [
                        entry("Cell Biology Test", 82),
                        entry("Genetics Quiz", 89),
                    ]),
                    GradeCategory(id: UUID(), name: "Labs", weight: 0.30, entries: [
                        entry("Microscopy Lab", 93),
                        entry("Diffusion Lab", 88),
                    ]),
                    GradeCategory(id: UUID(), name: "Homework", weight: 0.20, entries: [
                        entry("HW Set 1", 96),
                        entry("HW Set 2", 90),
                    ])
                ],
                provenance: .aspen
            ),

            // Math 3: Alg 2, Trig, Stat — Tests 60%, Homework 30%, Quizzes 10%
            CourseGrade(
                id: UUID(), courseId: MockStudentSchedule.math3.id,
                name: MockStudentSchedule.math3.name,
                currentGrade: nil, letterGrade: nil,
                categories: [
                    GradeCategory(id: UUID(), name: "Tests", weight: 0.60, entries: [
                        entry("Functions Test", 90),
                        entry("Trig Ratios Test", 85),
                    ]),
                    GradeCategory(id: UUID(), name: "Homework", weight: 0.30, entries: [
                        entry("HW 1", 100),
                        entry("HW 2", 95),
                        entry("HW 3", 88),
                    ]),
                    GradeCategory(id: UUID(), name: "Quizzes", weight: 0.10, entries: [
                        entry("Quiz 1", 88),
                        entry("Quiz 2", 92),
                    ])
                ],
                provenance: .aspen
            ),

            // Intro to Economics — Tests 60%, Projects 40%
            CourseGrade(
                id: UUID(), courseId: MockStudentSchedule.economics.id,
                name: MockStudentSchedule.economics.name,
                currentGrade: nil, letterGrade: nil,
                categories: [
                    GradeCategory(id: UUID(), name: "Tests", weight: 0.60, entries: [
                        entry("Supply & Demand Test", 93),
                    ]),
                    GradeCategory(id: UUID(), name: "Projects", weight: 0.40, entries: [
                        entry("Market Analysis", 89),
                    ])
                ],
                provenance: .aspen
            ),

            // Lit and Comp II — Essays 60%, Discussion 30%, Reading 10%
            CourseGrade(
                id: UUID(), courseId: MockStudentSchedule.litAndComp.id,
                name: MockStudentSchedule.litAndComp.name,
                currentGrade: nil, letterGrade: nil,
                categories: [
                    GradeCategory(id: UUID(), name: "Essays", weight: 0.60, entries: [
                        entry("Analytical Essay 1", 86),
                        entry("Close Reading", 91),
                    ]),
                    GradeCategory(id: UUID(), name: "Discussion", weight: 0.30, entries: [
                        entry("Socratic Seminar", 93),
                    ]),
                    GradeCategory(id: UUID(), name: "Reading", weight: 0.10, entries: [
                        entry("Reading Checks", 97),
                    ])
                ],
                provenance: .aspen
            ),

            // Mind Body Mechanics — Participation 70%, Assessments 30%
            CourseGrade(
                id: UUID(), courseId: MockStudentSchedule.mindBodyMechanics.id,
                name: MockStudentSchedule.mindBodyMechanics.name,
                currentGrade: nil, letterGrade: nil,
                categories: [
                    GradeCategory(id: UUID(), name: "Participation", weight: 0.70, entries: [
                        entry("Q1 Effort", 98),
                    ]),
                    GradeCategory(id: UUID(), name: "Assessments", weight: 0.30, entries: [
                        entry("Fitness Assessment", 95),
                    ])
                ],
                provenance: .aspen
            ),
        ]
    }
}
