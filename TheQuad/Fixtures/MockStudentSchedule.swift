import Foundation

/// A realistic fictional LHS student schedule for development and previews.
/// Six courses, one per block A–F, each with a stable course color.
enum MockStudentSchedule {

    static let studentId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

    static let apChemistry = Course(
        id: UUID(uuidString: "AA000000-0000-0000-0000-000000000001")!,
        name: "AP Chemistry", teacher: "Ms. Chen", room: "234",
        block: .a, classCode: nil, colorIndex: 0, provenance: .parsedSchedule
    )
    static let apUSHistory = Course(
        id: UUID(uuidString: "AA000000-0000-0000-0000-000000000002")!,
        name: "AP US History", teacher: "Mr. Rodriguez", room: "115",
        block: .b, classCode: nil, colorIndex: 1, provenance: .parsedSchedule
    )
    static let orchestra = Course(
        id: UUID(uuidString: "AA000000-0000-0000-0000-000000000003")!,
        name: "Orchestra", teacher: "Mr. Kim", room: "Auditorium",
        block: .c, classCode: nil, colorIndex: 2, provenance: .parsedSchedule
    )
    static let english11 = Course(
        id: UUID(uuidString: "AA000000-0000-0000-0000-000000000004")!,
        name: "English 11", teacher: "Ms. Thompson", room: "203",
        block: .d, classCode: nil, colorIndex: 3, provenance: .parsedSchedule
    )
    static let preCalculus = Course(
        id: UUID(uuidString: "AA000000-0000-0000-0000-000000000005")!,
        name: "Pre-Calculus", teacher: "Ms. Patel", room: "318",
        block: .e, classCode: nil, colorIndex: 4, provenance: .parsedSchedule
    )
    static let spanishIV = Course(
        id: UUID(uuidString: "AA000000-0000-0000-0000-000000000006")!,
        name: "Spanish IV", teacher: "Mr. Garcia", room: "127",
        block: .f, classCode: nil, colorIndex: 5, provenance: .parsedSchedule
    )

    static let courses: [Course] = [
        apChemistry, apUSHistory, orchestra, english11, preCalculus, spanishIV
    ]

    static let enrollments: [Enrollment] = courses.map { course in
        Enrollment(id: UUID(), studentId: studentId, courseId: course.id, schoolYear: "2025-26")
    }

    /// A ScheduleEngine seeded with reference fixtures + the mock student's data.
    static func engine() -> ScheduleEngine {
        ScheduleEngine(
            calendarDates: LHSFixtures_2025_26.calendarDates_2025_26,
            overrides: [],
            bellSchedules: LHSFixtures_2025_26.allBellSchedules
        )
    }
}
