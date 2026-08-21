import Foundation

/// Generates an RFC 5545-compliant .ics calendar feed from the student's schedule.
/// The ICS file can be imported into any calendar app or served as a live feed.
struct ICSGenerator {

    /// Generate a complete ICS string for the student's schedule across the given date range.
    func generate(
        courses: [Course],
        enrollments: [Enrollment],
        engine: ScheduleEngine,
        from startDate: Date,
        to endDate: Date,
        calendarName: String = "The Quad – My Schedule"
    ) -> String {
        var lines: [String] = []
        lines.append("BEGIN:VCALENDAR")
        lines.append("VERSION:2.0")
        lines.append("PRODID:-//The Quad//LHS Schedule//EN")
        lines.append("CALSCALE:GREGORIAN")
        lines.append("METHOD:PUBLISH")
        lines.append("X-WR-CALNAME:\(calendarName)")
        lines.append("X-WR-TIMEZONE:America/New_York")

        var current = Calendar.current.startOfDay(for: startDate)
        while current <= endDate {
            let sessions = engine.studentMeetings(for: current, enrollments: enrollments, courses: courses)
            for session in sessions {
                lines.append(contentsOf: vevent(for: session))
            }
            guard let next = Calendar.current.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        lines.append("END:VCALENDAR")
        return lines.joined(separator: "\r\n")
    }

    // MARK: - VEVENT builder

    private func vevent(for session: CourseSession) -> [String] {
        let dtStart = icsDate(session.startDateTime)
        let dtEnd = icsDate(session.endDateTime)
        let uid = "\(session.course.id)-\(dtStart)@thequad.app"
        let summary = foldedLine("SUMMARY:\(session.course.name)")
        let location = session.course.room ?? ""
        let description = session.course.teacher.map { "Teacher: \($0)" } ?? ""
        let now = icsDate(Date())

        return [
            "BEGIN:VEVENT",
            "UID:\(uid)",
            "DTSTAMP:\(now)Z",
            "DTSTART;TZID=America/New_York:\(dtStart)",
            "DTEND;TZID=America/New_York:\(dtEnd)",
            summary,
            "LOCATION:\(location)",
            "DESCRIPTION:\(description)",
            "END:VEVENT"
        ]
    }

    // MARK: - Helpers

    /// Format a Date as ICS local datetime: YYYYMMDDTHHmmss
    private func icsDate(_ date: Date) -> String {
        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        return String(
            format: "%04d%02d%02dT%02d%02d%02d",
            comps.year ?? 0, comps.month ?? 0, comps.day ?? 0,
            comps.hour ?? 0, comps.minute ?? 0, comps.second ?? 0
        )
    }

    /// Fold long lines at 75 octets per RFC 5545 §3.1.
    private func foldedLine(_ line: String) -> String {
        let limit = 75
        guard line.count > limit else { return line }
        var result = ""
        var chars = Array(line)
        var i = 0
        while i < chars.count {
            let end = min(i + (i == 0 ? limit : limit - 1), chars.count)
            if i > 0 { result += "\r\n " }
            result += String(chars[i..<end])
            i = end
        }
        return result
    }
}
