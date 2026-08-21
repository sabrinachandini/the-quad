import Foundation

/// A concrete meeting of a student's course on a specific date and time slot.
struct CourseSession: Identifiable {
    let id: UUID
    let course: Course
    let slot: MeetingSlot
    let date: Date

    var startDateTime: Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        comps.hour = slot.startTime.hour
        comps.minute = slot.startTime.minute
        return cal.date(from: comps) ?? date
    }

    var endDateTime: Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        comps.hour = slot.endTime.hour
        comps.minute = slot.endTime.minute
        return cal.date(from: comps) ?? date
    }
}

/// Resolves any date to the correct LHS rotation day, bell schedule, and the
/// student's concrete course sessions. Pure and unit-tested. See
/// docs/LHS_SCHEDULE_MODEL.md for the domain rules this enforces.
struct ScheduleEngine {
    let calendarDates: [SchoolCalendarDate]
    let overrides: [ScheduleOverride]
    let bellSchedules: [BellSchedule]

    private let calendar = Calendar.current

    // MARK: - Day Type

    /// Resolves the DayType for a date. Admin overrides trump the calendar.
    /// Returns nil for weekends and unknown/no-school dates.
    func dayType(for date: Date) -> DayType? {
        // Admin override wins, always.
        if let override = override(for: date) {
            return override.overrideDayType.isSchoolDay ? override.overrideDayType : nil
        }
        // Calendar entry next.
        if let entry = calendarDate(for: date) {
            return entry.dayType.isSchoolDay ? entry.dayType : nil
        }
        // Fall back: weekends are never school days.
        let weekday = calendar.component(.weekday, from: date)
        if weekday == 1 || weekday == 7 { // Sunday = 1, Saturday = 7
            return nil
        }
        // No data for a weekday: unknown, treat as no session.
        return nil
    }

    // MARK: - Bell Schedule

    /// The bell schedule that applies to a date: override schedule > calendar
    /// override schedule > the standard schedule matching the resolved DayType.
    func bellSchedule(for date: Date) -> BellSchedule? {
        if let override = override(for: date), let bs = override.overrideBellSchedule {
            return bs
        }
        if let entry = calendarDate(for: date), let bs = entry.bellScheduleOverride {
            return bs
        }
        guard let type = dayType(for: date) else { return nil }
        return bellSchedules.first { $0.dayType == type }
    }

    // MARK: - Meetings

    /// The ordered meeting slots for a date (empty if no school).
    func meetings(for date: Date) -> [MeetingSlot] {
        (bellSchedule(for: date)?.slots ?? []).sorted { $0.order < $1.order }
    }

    /// The student's concrete course sessions for a date: each non-lunch slot
    /// mapped to the course the student is enrolled in for that slot's block.
    func studentMeetings(for date: Date, enrollments: [Enrollment], courses: [Course]) -> [CourseSession] {
        let enrolledCourseIDs = Set(enrollments.map { $0.courseId })
        let enrolledCourses = courses.filter { enrolledCourseIDs.contains($0.id) }
        var sessions: [CourseSession] = []
        for slot in meetings(for: date) where !slot.isLunch {
            guard let course = enrolledCourses.first(where: { $0.block == slot.block }) else {
                continue // student has a free block here
            }
            sessions.append(CourseSession(id: UUID(), course: course, slot: slot, date: date))
        }
        return sessions.sorted { $0.startDateTime < $1.startDateTime }
    }

    /// The session happening right now (nil during passing time or outside school).
    func currentMeeting(at now: Date, enrollments: [Enrollment], courses: [Course]) -> CourseSession? {
        let sessions = studentMeetings(for: now, enrollments: enrollments, courses: courses)
        return sessions.first { now >= $0.startDateTime && now < $0.endDateTime }
    }

    /// The next session strictly after `now`. Looks ahead up to 14 days to find
    /// the first session of the next school day if none remain today.
    func nextMeeting(after now: Date, enrollments: [Enrollment], courses: [Course]) -> CourseSession? {
        // Remaining sessions today.
        let todaySessions = studentMeetings(for: now, enrollments: enrollments, courses: courses)
        if let next = todaySessions.first(where: { $0.startDateTime > now }) {
            return next
        }
        // Search forward for the next school day with sessions.
        for offset in 1...14 {
            guard let future = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
            let start = calendar.startOfDay(for: future)
            let sessions = studentMeetings(for: start, enrollments: enrollments, courses: courses)
            if let first = sessions.first {
                return first
            }
        }
        return nil
    }

    // MARK: - Lookups

    private func override(for date: Date) -> ScheduleOverride? {
        overrides.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func calendarDate(for date: Date) -> SchoolCalendarDate? {
        calendarDates.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
}
