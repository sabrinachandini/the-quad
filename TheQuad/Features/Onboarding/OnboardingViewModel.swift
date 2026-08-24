import Foundation
import Observation
import UIKit

@Observable
final class OnboardingViewModel {

    static let studentId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    /// The six course blocks shown during schedule entry.
    static let scheduleBlocks: [AcademicBlock] = [.a, .b, .c, .d, .e, .f]

    // MARK: - Step navigation (new 6-step flow)
    /// 0=launch 1=lhs 2=profile 3=schedule 4=parsing 5=done
    var currentStep: Int = 0

    // Legacy alias used by old code (step 0/1/2 mapped into currentStep)
    var step: Int {
        get { currentStep }
        set { currentStep = newValue }
    }

    // MARK: - Profile
    var firstName: String = ""
    var lastName: String = ""
    var graduationYear: Int = 2026
    var profilePhoto: UIImage? = nil
    var showPhotoPicker: Bool = false

    // MARK: - Schedule
    var courseNames: [AcademicBlock: String] = [:]
    var teachers: [AcademicBlock: String] = [:]
    var rooms: [AcademicBlock: String] = [:]

    // MARK: - Import/camera state (kept from previous implementation)
    var showCamera: Bool = false
    var showFilePicker: Bool = false

    var hasAtLeastOneCourse: Bool {
        courseNames.values.contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var profileComplete: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
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
        // Persist profile
        let fullName = firstName.isEmpty ? "Student" : "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        AppState.shared.displayName = fullName
        AppState.shared.graduationYear = graduationYear
        if let photo = profilePhoto {
            AppState.shared.saveAvatar(photo)
        }

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
