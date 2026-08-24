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

    // MARK: - Today State

    enum TodayState {
        case beforeSchool
        case duringClass
        case freeBlock
        case afterSchool
        case noSchool
    }

    var todayState: TodayState {
        guard engine.dayType(for: now) != nil else { return .noSchool }
        let slots = engine.meetings(for: now)
        guard !slots.isEmpty else { return .noSchool }

        let minutesNow = Calendar.current.component(.hour, from: now) * 60
            + Calendar.current.component(.minute, from: now)

        // Find first and last slot boundaries
        let firstSlotStart = (slots.first.map { ($0.startTime.hour ?? 0) * 60 + ($0.startTime.minute ?? 0) }) ?? 0
        let lastSlotEnd = (slots.last.map { ($0.endTime.hour ?? 0) * 60 + ($0.endTime.minute ?? 0) }) ?? 0

        if minutesNow < firstSlotStart {
            return .beforeSchool
        }
        if minutesNow >= lastSlotEnd {
            return .afterSchool
        }
        if currentSession != nil {
            return .duringClass
        }
        // We're between first start and last end, no class — free block
        return .freeBlock
    }

    // MARK: - Free Block

    var freeBlockMinutesRemaining: Int {
        let slots = engine.meetings(for: now)
        let mySessions = engine.studentMeetings(for: now, enrollments: enrollments, courses: courses)
        let occupiedIDs = Set(mySessions.map { $0.slot.id })

        let minutesNow = Calendar.current.component(.hour, from: now) * 60
            + Calendar.current.component(.minute, from: now)

        // Find the current free slot (the one we're currently inside)
        let currentFreeSlot = slots.first { slot in
            guard !slot.isLunch, !occupiedIDs.contains(slot.id) else { return false }
            let slotStart = (slot.startTime.hour ?? 0) * 60 + (slot.startTime.minute ?? 0)
            let slotEnd = (slot.endTime.hour ?? 0) * 60 + (slot.endTime.minute ?? 0)
            return minutesNow >= slotStart && minutesNow < slotEnd
        }
        guard let freeSlot = currentFreeSlot else { return 0 }
        let slotEnd = (freeSlot.endTime.hour ?? 0) * 60 + (freeSlot.endTime.minute ?? 0)
        return max(0, slotEnd - minutesNow)
    }

    var upcomingAssignmentsForFree: [Assignment] {
        let remaining = freeBlockMinutesRemaining
        guard remaining > 0 else { return [] }
        return AppState.shared.assignments
            .filter { !$0.isCompleted }
            .filter { ($0.estimatedMinutes ?? 0) <= remaining && ($0.estimatedMinutes ?? 0) > 0 }
            .sorted { ($0.estimatedMinutes ?? 0) < ($1.estimatedMinutes ?? 0) }
            .prefix(2)
            .map { $0 }
    }

    // MARK: - Today

    var todayLabel: String {
        let weekday = now.formatted(.dateTime.weekday(.wide))
        if let type = engine.dayType(for: now), let n = type.rotationIndex {
            return "\(weekday), Day \(n + 1)"
        }
        return weekday
    }

    /// "TUESDAY" uppercase weekday
    var weekdayUppercase: String {
        now.formatted(.dateTime.weekday(.wide)).uppercased()
    }

    /// "DAY 4" or "NO SCHOOL" or "SPECIAL"
    var dayNumberLabel: String {
        if let type = engine.dayType(for: now), let n = type.rotationIndex {
            return "DAY \(n + 1)"
        }
        if engine.dayType(for: now) == nil { return "NO SCHOOL" }
        return "SPECIAL"
    }

    /// "SEP 8" style date
    var shortDateLabel: String {
        now.formatted(.dateTime.month(.abbreviated).day())
            .uppercased()
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

    /// Minutes remaining in current class session (integer)
    var minutesRemainingInCurrent: Int {
        guard let current = currentSession else { return 0 }
        let remaining = current.endDateTime.timeIntervalSince(now)
        return max(0, Int(remaining / 60))
    }

    /// Progress fraction 0–1 for time elapsed in current session
    var currentSessionProgress: Double {
        guard let current = currentSession else { return 0 }
        let total = current.endDateTime.timeIntervalSince(current.startDateTime)
        let elapsed = now.timeIntervalSince(current.startDateTime)
        guard total > 0 else { return 0 }
        return min(1, max(0, elapsed / total))
    }

    // MARK: - Slot status

    enum SlotStatus {
        case past
        case current
        case free(minutes: Int)
        case future
        case lunch
    }

    func slotStatus(for slot: MeetingSlot) -> SlotStatus {
        if slot.isLunch { return .lunch }

        let minutesNow = Calendar.current.component(.hour, from: now) * 60
            + Calendar.current.component(.minute, from: now)
        let slotStart = (slot.startTime.hour ?? 0) * 60 + (slot.startTime.minute ?? 0)
        let slotEnd = (slot.endTime.hour ?? 0) * 60 + (slot.endTime.minute ?? 0)

        // Check if this slot is occupied by current session
        if let current = currentSession, current.slot.id == slot.id {
            return .current
        }

        if slotEnd <= minutesNow {
            return .past
        }

        // Free block check
        if course(for: slot) == nil && !slot.isLunch {
            let mins = slotEnd - slotStart
            return .free(minutes: mins)
        }

        return .future
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

    /// "MONDAY · DAY 2" for next school day
    var nextSchoolDayLabel: String {
        // Search forward up to 7 days
        let cal = Calendar.current
        for offset in 1...7 {
            guard let candidate = cal.date(byAdding: .day, value: offset, to: now) else { continue }
            if let type = engine.dayType(for: candidate), let n = type.rotationIndex {
                let weekday = candidate.formatted(.dateTime.weekday(.wide)).uppercased()
                return "\(weekday) · DAY \(n + 1)"
            }
        }
        return "NO SCHOOL UPCOMING"
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

    /// Friends free right now (during current free block)
    var friendsFreeNow: [(friend: User, sharedBlock: AvailabilityInterval)] {
        guard todayState == .freeBlock else { return [] }
        return friendsFreeSoon
    }
}
