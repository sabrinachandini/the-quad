import XCTest
@testable import TheQuad

final class ScheduleEngineTests: XCTestCase {

    private let cal = Calendar.current

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    /// Engine seeded with reference fixtures + mock student.
    private func makeEngine(
        calendarDates: [SchoolCalendarDate]? = nil,
        overrides: [ScheduleOverride] = []
    ) -> ScheduleEngine {
        ScheduleEngine(
            calendarDates: calendarDates ?? LHSFixtures_2025_26.sampleCalendarDates,
            overrides: overrides,
            bellSchedules: LHSFixtures_2025_26.allBellSchedules
        )
    }

    // MARK: - Rotation day ordering

    func testAllSixRotationDaysHaveCorrectBlockOrdering() {
        let expected: [(DayType, [AcademicBlock])] = [
            (.day1, [.a, .b, .c, .d, .e, .f]),
            (.day2, [.b, .c, .d, .e, .f, .a]),
            (.day3, [.c, .d, .e, .f, .a, .b]),
            (.day4, [.d, .e, .f, .a, .b, .c]),
            (.day5, [.e, .f, .a, .b, .c, .d]),
            (.day6, [.f, .a, .b, .c, .d, .e])
        ]
        for (dayType, blocks) in expected {
            let schedule = LHSFixtures_2025_26.allBellSchedules.first { $0.dayType == dayType }
            XCTAssertNotNil(schedule, "Missing schedule for \(dayType)")
            let academicBlocks = schedule!.slots.filter { !$0.isLunch }.sorted { $0.order < $1.order }.map { $0.block }
            XCTAssertEqual(academicBlocks, blocks, "Wrong block order for \(dayType)")
        }
    }

    // MARK: - Non-school days

    func testWeekendReturnsNilDayType() {
        let engine = makeEngine(calendarDates: [])
        // 2025-09-06 is a Saturday.
        XCTAssertNil(engine.dayType(for: date(2025, 9, 6)))
        // 2025-09-07 is a Sunday.
        XCTAssertNil(engine.dayType(for: date(2025, 9, 7)))
    }

    func testNoSchoolDateReturnsNil() {
        let holiday = SchoolCalendarDate(id: UUID(), date: date(2025, 11, 27), dayType: .noSchool, bellScheduleOverride: nil, note: "Thanksgiving", isVerified: true)
        let engine = makeEngine(calendarDates: [holiday])
        XCTAssertNil(engine.dayType(for: date(2025, 11, 27)))
    }

    // MARK: - Overrides

    func testAdminOverrideBeatsDefaultRotation() {
        // Calendar says 2025-09-04 is Day 3.
        XCTAssertEqual(makeEngine().dayType(for: date(2025, 9, 4)), .day3)
        // Admin overrides that date to an assembly.
        let override = ScheduleOverride(id: UUID(), date: date(2025, 9, 4), overrideDayType: .assembly, overrideBellSchedule: nil, reason: "Pep rally", setBy: "admin", setAt: Date())
        let engine = makeEngine(overrides: [override])
        XCTAssertEqual(engine.dayType(for: date(2025, 9, 4)), .assembly)
    }

    // MARK: - Half day

    func testHalfDayUsesExplicitTemplateNotHalvedTimes() {
        let engine = makeEngine()
        // 2025-09-12 is marked halfDay in fixtures.
        let bs = engine.bellSchedule(for: date(2025, 9, 12))
        XCTAssertEqual(bs?.dayType, .halfDay)
        // Half-day last slot should end by ~11:30, not the standard 14:20.
        let lastEnd = bs?.slots.sorted { $0.order < $1.order }.last?.endTime
        XCTAssertEqual(lastEnd?.hour, 11)
        XCTAssertEqual(lastEnd?.minute, 30)
        // And it's explicitly NOT the standard schedule (which ends at 14:20).
        XCTAssertNotEqual(lastEnd?.hour, 14)
    }

    // MARK: - Free block detection

    func testNoCoursesMeansFullDayFree() {
        let engine = makeEngine()
        let sessions = engine.studentMeetings(for: date(2025, 9, 4), enrollments: [], courses: [])
        XCTAssertTrue(sessions.isEmpty, "A student with no enrollments has no sessions (all free)")
    }

    func testAllCoursesMeansNoFreeBlocks() {
        let engine = makeEngine()
        let sessions = engine.studentMeetings(for: date(2025, 9, 4), enrollments: MockStudentSchedule.enrollments, courses: MockStudentSchedule.courses)
        // 6 academic slots on a standard day, student enrolled in all 6 blocks A–F.
        XCTAssertEqual(sessions.count, 6)
    }

    func testGapsBetweenCoursesProduceFreeBlocks() {
        let engine = makeEngine()
        // Enroll only in A and C blocks — B, D, E, F are free.
        let onlyAC = MockStudentSchedule.enrollments.filter { e in
            let course = MockStudentSchedule.courses.first { $0.id == e.courseId }
            return course?.block == .a || course?.block == .c
        }
        let sessions = engine.studentMeetings(for: date(2025, 9, 4), enrollments: onlyAC, courses: MockStudentSchedule.courses)
        XCTAssertEqual(sessions.count, 2)
    }

    // MARK: - Current / next meeting

    func testCurrentMeetingBeforeSchoolIsNil() {
        let engine = makeEngine()
        let before = date(2025, 9, 4, 6, 0) // 6:00 AM, before 7:55
        XCTAssertNil(engine.currentMeeting(at: before, enrollments: MockStudentSchedule.enrollments, courses: MockStudentSchedule.courses))
    }

    func testCurrentMeetingDuringFirstSlotReturnsCorrectCourse() {
        let engine = makeEngine()
        // 8:00 AM on Day 3: first slot is block C = Orchestra.
        let during = date(2025, 9, 4, 8, 0)
        let session = engine.currentMeeting(at: during, enrollments: MockStudentSchedule.enrollments, courses: MockStudentSchedule.courses)
        XCTAssertEqual(session?.course.block, .c)
        XCTAssertEqual(session?.course.name, "Orchestra")
    }

    func testCurrentMeetingDuringPassingIsNil() {
        let engine = makeEngine()
        // 8:52 AM: between first (ends 8:50) and second (starts 8:55) slot.
        let passing = date(2025, 9, 4, 8, 52)
        XCTAssertNil(engine.currentMeeting(at: passing, enrollments: MockStudentSchedule.enrollments, courses: MockStudentSchedule.courses))
    }

    func testNextMeetingAfterLastPeriodIsFirstPeriodOfNextSchoolDay() {
        let engine = makeEngine()
        // After 2:20 PM on Day 3 (2025-09-04). Next school day is 2025-09-05 (Day 4),
        // whose first slot is block D = English 11.
        let afterSchool = date(2025, 9, 4, 15, 0)
        let next = engine.nextMeeting(after: afterSchool, enrollments: MockStudentSchedule.enrollments, courses: MockStudentSchedule.courses)
        XCTAssertEqual(next?.course.block, .d)
        XCTAssertTrue(cal.isDate(next!.date, inSameDayAs: date(2025, 9, 5)))
    }
}
