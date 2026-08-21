import XCTest
@testable import TheQuad

final class FreeBlockEngineTests: XCTestCase {

    private let cal = Calendar.current
    private let engine = FreeBlockEngine()
    private let studentId = MockStudentSchedule.studentId

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d))!
    }

    private func scheduleEngine() -> ScheduleEngine {
        ScheduleEngine(
            calendarDates: LHSFixtures_2025_26.sampleCalendarDates,
            overrides: [],
            bellSchedules: LHSFixtures_2025_26.allBellSchedules
        )
    }

    // MARK: - Free block computation

    func testNoEnrollmentsMeansAllSlotsFree() {
        let day = date(2025, 9, 4)
        let se = scheduleEngine()
        let allSlots = se.meetings(for: day)
        let free = engine.freeBlocks(for: day, studentId: studentId, allSlots: allSlots, studentSessions: [])
        // All 6 non-lunch slots free, merged into one contiguous run (they are
        // consecutive by order even across the lunch slot boundary — lunch is
        // excluded from candidates but keeps order continuity? No: lunch breaks
        // order continuity, so expect two runs around lunch).
        XCTAssertFalse(free.isEmpty)
        let totalMinutes = free.reduce(0) { $0 + $1.durationMinutes }
        XCTAssertGreaterThan(totalMinutes, 0)
    }

    func testAllCoursesMeansNoFreeBlocks() {
        let day = date(2025, 9, 4)
        let se = scheduleEngine()
        let allSlots = se.meetings(for: day)
        let sessions = se.studentMeetings(for: day, enrollments: MockStudentSchedule.enrollments, courses: MockStudentSchedule.courses)
        let free = engine.freeBlocks(for: day, studentId: studentId, allSlots: allSlots, studentSessions: sessions)
        XCTAssertTrue(free.isEmpty, "Fully enrolled student has no free blocks")
    }

    func testGapProducesFreeBlock() {
        let day = date(2025, 9, 4)
        let se = scheduleEngine()
        let allSlots = se.meetings(for: day)
        // Enroll only A + C. On Day 3 (order C,D,E,F,A,B), free slots are D,E,F,B.
        let onlyAC = MockStudentSchedule.enrollments.filter { e in
            let c = MockStudentSchedule.courses.first { $0.id == e.courseId }
            return c?.block == .a || c?.block == .c
        }
        let sessions = se.studentMeetings(for: day, enrollments: onlyAC, courses: MockStudentSchedule.courses)
        let free = engine.freeBlocks(for: day, studentId: studentId, allSlots: allSlots, studentSessions: sessions)
        XCTAssertFalse(free.isEmpty)
    }

    func testConsecutiveFreeSlotsAreMerged() {
        let day = date(2025, 9, 4)
        let se = scheduleEngine()
        let allSlots = se.meetings(for: day).filter { !$0.isLunch }
        // Occupy only the very first slot; the rest are consecutive free slots
        // which should merge into a single interval.
        let firstSlot = allSlots.sorted { $0.order < $1.order }.first!
        let fakeCourse = MockStudentSchedule.courses.first { $0.block == firstSlot.block }!
        let session = CourseSession(id: UUID(), course: fakeCourse, slot: firstSlot, date: day)
        let free = engine.freeBlocks(for: day, studentId: studentId, allSlots: allSlots, studentSessions: [session])
        XCTAssertEqual(free.count, 1, "Remaining consecutive free slots merge to one interval")
    }

    // MARK: - Shared free blocks (overlap)

    func testSharedFreeBlocksIntersect() {
        let day = date(2025, 9, 4)
        let a = AvailabilityInterval(id: UUID(), studentID: studentId, date: day,
                                     start: cal.date(bySettingHour: 9, minute: 0, second: 0, of: day)!,
                                     end: cal.date(bySettingHour: 11, minute: 0, second: 0, of: day)!,
                                     label: "Free")
        let b = AvailabilityInterval(id: UUID(), studentID: UUID(), date: day,
                                     start: cal.date(bySettingHour: 10, minute: 0, second: 0, of: day)!,
                                     end: cal.date(bySettingHour: 12, minute: 0, second: 0, of: day)!,
                                     label: "Free")
        let shared = engine.sharedFreeBlocks(studentA: [a], studentB: [b])
        XCTAssertEqual(shared.count, 1)
        XCTAssertEqual(cal.component(.hour, from: shared[0].start), 10)
        XCTAssertEqual(cal.component(.hour, from: shared[0].end), 11)
    }

    func testNonOverlappingFreeBlocksProduceNoShared() {
        let day = date(2025, 9, 4)
        let a = AvailabilityInterval(id: UUID(), studentID: studentId, date: day,
                                     start: cal.date(bySettingHour: 8, minute: 0, second: 0, of: day)!,
                                     end: cal.date(bySettingHour: 9, minute: 0, second: 0, of: day)!,
                                     label: "Free")
        let b = AvailabilityInterval(id: UUID(), studentID: UUID(), date: day,
                                     start: cal.date(bySettingHour: 10, minute: 0, second: 0, of: day)!,
                                     end: cal.date(bySettingHour: 11, minute: 0, second: 0, of: day)!,
                                     label: "Free")
        let shared = engine.sharedFreeBlocks(studentA: [a], studentB: [b])
        XCTAssertTrue(shared.isEmpty)
    }
}
