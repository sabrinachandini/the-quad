import Foundation
import Observation

@Observable
final class TodayViewModel {
    private let engine: ScheduleEngine
    private let enrollments: [Enrollment]
    private let courses: [Course]

    /// The current time used for all computed properties.
    /// Updated every 30 seconds by a live timer in production.
    private(set) var now: Date

    private var timer: Timer?

    /// - Parameter previewDate: When set (Previews only), `now` is pinned to
    ///   this value and the live timer is never started.
    init(
        engine: ScheduleEngine = AppState.shared.scheduleEngine,
        enrollments: [Enrollment] = AppState.shared.enrollments,
        courses: [Course] = AppState.shared.courses,
        previewDate: Date? = nil
    ) {
        self.engine = engine
        self.enrollments = enrollments
        self.courses = courses

        // DEBUG: pin to a school day to preview the full schedule UI.
        // To disable, delete this block or set debugDate = nil.
        #if DEBUG
        let debugDate: Date? = {
            // First check env var (xcrun simctl launch --setenv QUAD_DEBUG_DATE="yyyy-MM-dd HH:mm")
            if let s = ProcessInfo.processInfo.environment["QUAD_DEBUG_DATE"] {
                let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm"
                if let d = f.date(from: s) { return d }
                let g = DateFormatter(); g.dateFormat = "yyyy-MM-dd"
                if let d = g.date(from: s) { return d }
            }
            // Fallback: hardcoded school-day preview (Sept 8 2026, 10:00 AM = Day 1, B block active)
            return Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 8, hour: 10))
        }()
        self.now = previewDate ?? debugDate ?? Date()
        // Don't start the live timer when pinned to a debug date — it would override the pin after 30s.
        let startTimer = previewDate == nil && debugDate == nil
        #else
        self.now = previewDate ?? Date()
        let startTimer = previewDate == nil
        #endif

        if startTimer {
            // Start a repeating timer that keeps `now` current.
            let t = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
                self?.now = Date()
            }
            RunLoop.main.add(t, forMode: .common)
            self.timer = t
        }
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Today

    var todayLabel: String {
        let weekday = now.formatted(.dateTime.weekday(.wide))
        if let type = engine.dayType(for: now), let n = type.rotationIndex {
            return "\(weekday), Day \(n + 1)"
        }
        return weekday
    }

    var dayBadge: String {
        guard let type = engine.dayType(for: now) else { return "No School" }
        if let n = type.rotationIndex { return "Day \(n + 1)" }
        switch type {
        case .halfDay:         return "Half Day"
        case .delayedOpening: return "Delayed Start"
        case .assembly:       return "Assembly"
        case .examSchedule:   return "Exams"
        default:              return "Special"
        }
    }

    var isSchoolDay: Bool {
        engine.dayType(for: now) != nil
    }

    /// Returns true if a given date is a school day (has a non-nil day type).
    func isSchoolDayOn(_ date: Date) -> Bool {
        engine.dayType(for: date) != nil
    }

    /// The first upcoming school day visible in the calendar, for long-break empty states.
    var nextCalendarSchoolDay: SchoolCalendarDate? {
        guard !isSchoolDay else { return nil }
        return engine.nextCalendarSchoolDay(after: now)
    }

    var currentSession: CourseSession? {
        engine.currentMeeting(at: now, enrollments: enrollments, courses: courses)
    }

    var nextSession: CourseSession? {
        engine.nextMeeting(after: now, enrollments: enrollments, courses: courses)
    }

    var allSessions: [CourseSession] {
        engine.studentMeetings(for: now, enrollments: enrollments, courses: courses)
    }

    /// All ordered slots for today (including free ones) for full-day rendering.
    var allSlots: [MeetingSlot] {
        engine.meetings(for: now)
    }

    var timeRemainingInCurrentSession: String? {
        guard let current = currentSession else { return nil }
        let remaining = current.endDateTime.timeIntervalSince(now)
        guard remaining > 0 else { return nil }
        let minutes = Int(remaining / 60)
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m left"
        }
        return "\(minutes)m left"
    }

    // MARK: - Tomorrow

    private var tomorrowDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
    }

    var tomorrowLabel: String {
        let weekday = tomorrowDate.formatted(.dateTime.weekday(.wide))
        if let type = engine.dayType(for: tomorrowDate), let n = type.rotationIndex {
            return "\(weekday), Day \(n + 1)"
        }
        return weekday
    }

    var tomorrowSessions: [CourseSession] {
        engine.studentMeetings(for: tomorrowDate, enrollments: enrollments, courses: courses)
    }

    // MARK: - Time of day

    /// True if the current time is after 3:00 PM.
    var isEvening: Bool {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: now)
        let hour = comps.hour ?? 0
        let minute = comps.minute ?? 0
        return hour > 15 || (hour == 15 && minute > 0)
    }

    // MARK: - Slot helpers

    /// True if a given slot is a free block for this student (no enrolled course).
    func isFree(slot: MeetingSlot) -> Bool {
        guard !slot.isLunch else { return false }
        return !allSessions.contains { $0.slot.id == slot.id }
    }

    /// Course occupying a slot, if any.
    func course(for slot: MeetingSlot) -> Course? {
        allSessions.first { $0.slot.id == slot.id }?.course
    }

    // MARK: - Friend free-block preview

    /// Up to 2 friends who share a free block overlapping the given slot.
    /// Returns non-empty only for the first upcoming free slot — prevents the
    /// same friend names from duplicating across every free row.
    func friendsFreeSoon(forSlot slot: MeetingSlot) -> [(friend: User, sharedBlock: AvailabilityInterval)] {
        let today = now
        let allSlotsList = engine.meetings(for: today)
        guard !allSlotsList.isEmpty else { return [] }

        let mySessions = engine.studentMeetings(for: today, enrollments: enrollments, courses: courses)
        let freeEngine = FreeBlockEngine()
        let myFree = freeEngine.freeBlocks(for: today, allSlots: allSlotsList, studentSessions: mySessions)

        // Find the AvailabilityInterval that corresponds to this slot.
        let slotStartMin = (slot.startTime.hour ?? 0) * 60 + (slot.startTime.minute ?? 0)
        let slotEndMin   = (slot.endTime.hour ?? 0) * 60 + (slot.endTime.minute ?? 0)
        guard let matchingFree = myFree.first(where: {
            let freeStart = Calendar.current.component(.hour, from: $0.start) * 60
                          + Calendar.current.component(.minute, from: $0.start)
            let freeEnd   = Calendar.current.component(.hour, from: $0.end) * 60
                          + Calendar.current.component(.minute, from: $0.end)
            return freeStart == slotStartMin && freeEnd == slotEndMin
        }) else {
            return []
        }

        // Only show overlap for slots that haven't ended yet.
        let minutesNow = Calendar.current.component(.hour, from: now) * 60
                       + Calendar.current.component(.minute, from: now)
        guard slotEndMin > minutesNow else { return [] }

        var result: [(User, AvailabilityInterval)] = []
        for friend in AppState.shared.friends.prefix(3) {
            guard let theirCourses = AppState.shared.friendCourses[friend.id] else { continue }
            let theirEnrollments = theirCourses.map {
                Enrollment(id: UUID(), studentId: friend.id, courseId: $0.id, schoolYear: "2026-27")
            }
            let theirSessions = engine.studentMeetings(for: today, enrollments: theirEnrollments, courses: theirCourses)
            let theirFree = freeEngine.freeBlocks(for: today, studentId: friend.id, allSlots: allSlotsList, studentSessions: theirSessions)
            let shared = freeEngine.sharedFreeBlocks(studentA: [matchingFree], studentB: theirFree)
            if let overlap = shared.first {
                result.append((friend, overlap))
            }
        }
        return Array(result.prefix(2))
    }
}
