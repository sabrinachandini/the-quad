import Foundation
import Observation
import SwiftUI

@Observable
final class OnboardingViewModel {

    static let studentId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    /// All eight LHS blocks shown during schedule entry.
    static let scheduleBlocks: [AcademicBlock] = [.a, .b, .c, .d, .e, .f, .g, .h]

    var courseNames: [AcademicBlock: String] = [:]
    var teachers: [AcademicBlock: String] = [:]
    var rooms: [AcademicBlock: String] = [:]

    // MARK: - Step state
    // 0 = welcome, 1 = import choice, 2 = manual entry, 3 = done
    var step: Int = 0

    // MARK: - Import flow state
    var showImagePicker = false
    var showDocumentPicker = false
    var isAnalyzing = false
    var importFailed = false       // true → fell back to manual after failed parse
    var importSucceeded = false   // true → parsed successfully, fields pre-filled

    var hasAtLeastOneCourse: Bool {
        courseNames.values.contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    // MARK: - Import handlers

    func handleImageSelected(_ image: UIImage) {
        isAnalyzing = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.8))
            prefillFromParsedSchedule()
            isAnalyzing = false
            withAnimation { step = 2 }
        }
    }

    func handleDocumentSelected() {
        isAnalyzing = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.8))
            prefillFromParsedSchedule()
            isAnalyzing = false
            withAnimation { step = 2 }
        }
    }

    /// Pre-fills course, teacher, and room data as if the schedule image was parsed by OCR.
    /// In production this would come from Vision + AI; here it uses fixture data matching
    /// the printed 2025-26 Q1 schedule (Bhattacharjya, Sabrina, GR: 10, HR: 178).
    private func prefillFromParsedSchedule() {
        importSucceeded = true
        importFailed = false
        courseNames = [
            .a: "Repertoire Orch/Strings",
            .b: "World History II",
            .c: "Spanish III",
            .d: "Biology",
            .e: "Math 3: Alg 2, Trig, Stat",
            .f: "Intro to Economics",
            .g: "Lit and Comp II",
            .h: "Mind Body Mechanics"
        ]
        teachers = [
            .a: "Billings-White",
            .b: "Prasad, Christine",
            .c: "Barbieri-Feeney, Olivia",
            .d: "Raboin, Anna",
            .e: "LeBlanc, Rachel",
            .f: "Cravedi, Sarah",
            .g: "Cooper, Edward",
            .h: "DeVincenzo, Tia"
        ]
        rooms = [
            .a: "133",
            .b: "225",
            .c: "612",
            .d: "408",
            .e: "827",
            .f: "235",
            .g: "164",
            .h: "140"
        ]
    }

    // MARK: - Build & persist

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
                schoolYear: "2026-27"
            )
        }
        AppState.shared.courses = courses
        AppState.shared.enrollments = enrollments
        AppState.shared.hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "quad_onboarding_complete")
    }
}
