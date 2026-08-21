import Foundation

/// Sabrina Bhattacharjya's 2025-26 LHS schedule used as prototype fixture data.
/// Eight courses across blocks A–H. Only 6 meet per day on the rotating schedule.
/// Block mapping matches the printed Q1 schedule from Aspen.
enum MockStudentSchedule {

    static let studentId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

    static let orchestraStrings = Course(
        id: UUID(uuidString: "AA000000-0000-0000-0000-000000000001")!,
        name: "Repertoire Orch/Strings", teacher: "Billings-White", room: "133",
        block: .a, classCode: "6910-001", colorIndex: 0, provenance: .parsedSchedule
    )
    static let worldHistory = Course(
        id: UUID(uuidString: "AA000000-0000-0000-0000-000000000002")!,
        name: "World History II", teacher: "Prasad, Christine", room: "225",
        block: .b, classCode: "2206-011", colorIndex: 1, provenance: .parsedSchedule
    )
    static let spanishIII = Course(
        id: UUID(uuidString: "AA000000-0000-0000-0000-000000000003")!,
        name: "Spanish III", teacher: "Barbieri-Feeney, Olivia", room: "612",
        block: .c, classCode: "5638-004", colorIndex: 2, provenance: .parsedSchedule
    )
    static let biology = Course(
        id: UUID(uuidString: "AA000000-0000-0000-0000-000000000004")!,
        name: "Biology", teacher: "Raboin, Anna", room: "408",
        block: .d, classCode: "4206-011", colorIndex: 3, provenance: .parsedSchedule
    )
    static let math3 = Course(
        id: UUID(uuidString: "AA000000-0000-0000-0000-000000000005")!,
        name: "Math 3: Alg 2, Trig, Stat", teacher: "LeBlanc, Rachel", room: "827",
        block: .e, classCode: "3338-005", colorIndex: 4, provenance: .parsedSchedule
    )
    static let economics = Course(
        id: UUID(uuidString: "AA000000-0000-0000-0000-000000000006")!,
        name: "Intro to Economics", teacher: "Cravedi, Sarah", room: "235",
        block: .f, classCode: "2660-001", colorIndex: 5, provenance: .parsedSchedule
    )
    static let litAndComp = Course(
        id: UUID(uuidString: "AA000000-0000-0000-0000-000000000007")!,
        name: "Lit and Comp II", teacher: "Cooper, Edward", room: "164",
        block: .g, classCode: "1208-026", colorIndex: 6, provenance: .parsedSchedule
    )
    static let mindBodyMechanics = Course(
        id: UUID(uuidString: "AA000000-0000-0000-0000-000000000008")!,
        name: "Mind Body Mechanics", teacher: "DeVincenzo, Tia", room: "140",
        block: .h, classCode: "7570-001", colorIndex: 7, provenance: .parsedSchedule
    )

    static let courses: [Course] = [
        orchestraStrings, worldHistory, spanishIII, biology,
        math3, economics, litAndComp, mindBodyMechanics
    ]

    static let enrollments: [Enrollment] = courses.map { course in
        Enrollment(id: UUID(), studentId: studentId, courseId: course.id, schoolYear: "2026-27")
    }

    static func engine() -> ScheduleEngine {
        ScheduleEngine(
            calendarDates: LHSFixtures_2025_26.calendarDates_2025_26
                        + LHSFixtures_2025_26.calendarDates_2026_27,
            overrides: [],
            bellSchedules: LHSFixtures_2025_26.allBellSchedules
        )
    }
}
