import Foundation
import Observation

@Observable
final class TodayViewModel {
    private let engine: ScheduleEngine
    private let enrollments: [Enrollment]
    private let courses: [Course]
    private let referenceDate: Date

    // For dev/preview correctness, anchor "today" to a known reference school day
    // from the 2025-26 fixtures (Day 3 = 2025-09-04) so the mock always renders.
    init(
        engine: ScheduleEngine = MockStudentSchedule.engine(),
        enrollments: [Enrollment] = MockStudentSchedule.enrollments,
        courses: [Course] = MockStudentSchedule.courses,
        referenceDate: Date? = nil
    ) {
        self.engine = engine
        self.enrollments = enrollments
        self.courses = courses
        self.referenceDate = referenceDate
            ?? Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 4, hour: 10, minute: 20))
            ?? Date()
    }

    var todayLabel: String {
        let weekday = referenceDate.formatted(.dateTime.weekday(.wide))
        if let type = engine.dayType(for: referenceDate), let n = type.rotationIndex {
            return "\(weekday), Day \(n + 1)"
        }
        return weekday
    }

    var dayBadge: String {
        if let type = engine.dayType(for: referenceDate), let n = type.rotationIndex {
            return "Day \(n + 1)"
        }
        if engine.dayType(for: referenceDate) == nil { return "No School" }
        return "Special"
    }

    var currentSession: CourseSession? {
        engine.currentMeeting(at: referenceDate, enrollments: enrollments, courses: courses)
    }

    var nextSession: CourseSession? {
        engine.nextMeeting(after: referenceDate, enrollments: enrollments, courses: courses)
    }

    var allSessions: [CourseSession] {
        engine.studentMeetings(for: referenceDate, enrollments: enrollments, courses: courses)
    }

    /// All ordered slots for today (including free ones) for full-day rendering.
    var allSlots: [MeetingSlot] {
        engine.meetings(for: referenceDate)
    }

    var timeRemainingInCurrentSession: String? {
        guard let current = currentSession else { return nil }
        let remaining = current.endDateTime.timeIntervalSince(referenceDate)
        guard remaining > 0 else { return nil }
        let minutes = Int(remaining / 60)
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m left"
        }
        return "\(minutes)m left"
    }

    /// True if a given slot is a free block for this student (no enrolled course).
    func isFree(slot: MeetingSlot) -> Bool {
        guard !slot.isLunch else { return false }
        return !allSessions.contains { $0.slot.id == slot.id }
    }

    /// Course occupying a slot, if any.
    func course(for slot: MeetingSlot) -> Course? {
        allSessions.first { $0.slot.id == slot.id }?.course
    }
}
