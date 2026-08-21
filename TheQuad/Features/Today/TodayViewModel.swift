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
        self.now = previewDate ?? Date()

        if previewDate == nil {
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
        if let type = engine.dayType(for: now), let n = type.rotationIndex {
            return "Day \(n + 1)"
        }
        if engine.dayType(for: now) == nil { return "No School" }
        return "Special"
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

    /// Up to 2 friends who share the next (or current) free block with me today.
    var friendsFreeSoon: [(friend: User, sharedBlock: AvailabilityInterval)] {
        let today = now
        let allSlotsList = engine.meetings(for: today)
        guard !allSlotsList.isEmpty else { return [] }

        let mySessions = engine.studentMeetings(for: today, enrollments: enrollments, courses: courses)
        let freeEngine = FreeBlockEngine()
        let myFree = freeEngine.freeBlocks(for: today, allSlots: allSlotsList, studentSessions: mySessions)

        // Find the next free block at or after now (includes currently-in-progress free blocks)
        let minutesNow = Calendar.current.component(.hour, from: now) * 60
            + Calendar.current.component(.minute, from: now)
        guard let nextFree = myFree.first(where: {
            let endMin = (Calendar.current.component(.hour, from: $0.end) * 60
                + Calendar.current.component(.minute, from: $0.end))
            return endMin > minutesNow
        }) else {
            return []
        }

        var result: [(User, AvailabilityInterval)] = []
        for friend in AppState.shared.friends.prefix(3) {
            guard let theirCourses = AppState.shared.friendCourses[friend.id] else { continue }
            let theirEnrollments = theirCourses.map {
                Enrollment(id: UUID(), studentId: friend.id, courseId: $0.id, schoolYear: "2025-26")
            }
            let theirSessions = engine.studentMeetings(for: today, enrollments: theirEnrollments, courses: theirCourses)
            let theirFree = freeEngine.freeBlocks(for: today, studentId: friend.id, allSlots: allSlotsList, studentSessions: theirSessions)
            let shared = freeEngine.sharedFreeBlocks(studentA: [nextFree], studentB: theirFree)
            if let overlap = shared.first {
                result.append((friend, overlap))
            }
        }
        return Array(result.prefix(2))
    }
}
