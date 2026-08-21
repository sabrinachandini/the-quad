import Foundation
import Observation

@Observable
final class OnboardingViewModel {

    static let studentId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    /// The six course blocks shown during schedule entry.
    static let scheduleBlocks: [AcademicBlock] = [.a, .b, .c, .d, .e, .f]

    var courseNames: [AcademicBlock: String] = [:]
    var teachers: [AcademicBlock: String] = [:]
    var rooms: [AcademicBlock: String] = [:]

    /// 0 = welcome, 1 = schedule entry, 2 = done
    var step: Int = 0

    var hasAtLeastOneCourse: Bool {
        courseNames.values.contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    func buildCourses() -> [Course] {
        Self.scheduleBlocks.enumerated().compactMap { index, block in
            let name = courseNames[block, default: ""].trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { return nil }
            let teacher = teachers[block, default: ""].trimmingCharacters(in: .whitespaces)
            let room = rooms[block, default: ""].trimmingCharacters(in: .whitespaces)
            return Course(
                id: UUID(),
                name: name,
                teacher: teacher.isEmpty ? nil : teacher,
                room: room.isEmpty ? nil : room,
                block: block,
                classCode: nil,
                colorIndex: index,
                provenance: .student
            )
        }
    }

    func complete() {
        let courses = buildCourses()
        let enrollments: [Enrollment] = courses.map { course in
            Enrollment(
                id: UUID(),
                studentId: Self.studentId,
                courseId: course.id,
                schoolYear: "2025-26"
            )
        }
        AppState.shared.courses = courses
        AppState.shared.enrollments = enrollments
        AppState.shared.hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "quad_onboarding_complete")
    }
}
