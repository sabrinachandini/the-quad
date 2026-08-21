import EventKit
import Foundation

enum CalendarAccessResult {
    case granted, denied
}

/// Writes The Quad schedule directly into Apple Calendar, keeping it updated
/// across syncs. A dedicated "The Quad" calendar is created on first run.
/// All operations are async and off the main thread.
actor CalendarSync {
    static let shared = CalendarSync()

    private let store = EKEventStore()
    private let calendarTitle = "The Quad"
    private let calendarColor = CGColor(red: 0.345, green: 0.337, blue: 0.839, alpha: 1) // indigo

    // MARK: - Public sync entry point

    func sync(
        courses: [Course],
        enrollments: [Enrollment],
        engine: ScheduleEngine
    ) async throws -> CalendarAccessResult {
        let granted = await requestAccess()
        guard granted else { return .denied }

        let calendar = try findOrCreateCalendar()
        try removeStaleEvents(in: calendar)

        let today = Date()
        // Sync the rest of the current school year (up to 10 months ahead).
        guard let endDate = Calendar.current.date(byAdding: .month, value: 10, to: today) else { return .granted }

        var current = Calendar.current.startOfDay(for: today)
        while current <= endDate {
            let sessions = engine.studentMeetings(for: current, enrollments: enrollments, courses: courses)
            for session in sessions {
                let event = buildEvent(for: session, on: current, calendar: calendar)
                try store.save(event, span: .thisEvent)
            }
            guard let next = Calendar.current.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        try store.commit()
        return .granted
    }

    // MARK: - Access

    private func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            return (try? await store.requestWriteOnlyAccessToEvents()) ?? false
        } else {
            return await withCheckedContinuation { cont in
                store.requestAccess(to: .event) { granted, _ in
                    cont.resume(returning: granted)
                }
            }
        }
    }

    // MARK: - Calendar management

    private func findOrCreateCalendar() throws -> EKCalendar {
        if let existing = store.calendars(for: .event).first(where: { $0.title == calendarTitle }) {
            return existing
        }
        let cal = EKCalendar(for: .event, eventStore: store)
        cal.title = calendarTitle
        cal.cgColor = calendarColor
        // Use the default local calendar source so it appears immediately.
        if let local = store.sources.first(where: { $0.sourceType == .local })
            ?? store.sources.first {
            cal.source = local
        }
        try store.saveCalendar(cal, commit: true)
        return cal
    }

    private func removeStaleEvents(in calendar: EKCalendar) throws {
        let today = Date()
        guard let end = Calendar.current.date(byAdding: .month, value: 10, to: today) else { return }
        let predicate = store.predicateForEvents(withStart: today, end: end, calendars: [calendar])
        let existing = store.events(matching: predicate)
        for event in existing {
            try store.remove(event, span: .thisEvent)
        }
    }

    // MARK: - Event builder

    private func buildEvent(for session: CourseSession, on date: Date, calendar: EKCalendar) -> EKEvent {
        let event = EKEvent(eventStore: store)
        event.calendar = calendar
        event.title = session.course.name
        event.location = session.course.room
        event.notes = session.course.teacher.map { "Teacher: \($0)" }

        let cal = Calendar.current
        var startComps = cal.dateComponents([.year, .month, .day], from: date)
        startComps.hour = session.slot.startTime.hour
        startComps.minute = session.slot.startTime.minute
        var endComps = cal.dateComponents([.year, .month, .day], from: date)
        endComps.hour = session.slot.endTime.hour
        endComps.minute = session.slot.endTime.minute

        event.startDate = cal.date(from: startComps) ?? date
        event.endDate = cal.date(from: endComps) ?? date

        // 5-minute reminder before class.
        let alarm = EKAlarm(relativeOffset: -300)
        event.addAlarm(alarm)

        return event
    }
}
