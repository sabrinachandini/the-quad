import Foundation
import UserNotifications

/// Schedules and cancels all app notifications. Call `scheduleAll()` whenever
/// schedule, assignments, or settings change. All notifications are identified
/// by stable string IDs so re-scheduling is idempotent.
final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private let center = UNUserNotificationCenter.current()
    private init() {}

    // MARK: - Permission

    /// Request notification permission. Call once (e.g. on onboarding completion).
    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Schedule everything

    /// Re-computes and schedules all notifications from current AppState.
    /// Cancels all previously scheduled notifications first.
    func scheduleAll() {
        guard AppState.shared.classRemindersEnabled else {
            cancelAll()
            return
        }
        center.removeAllPendingNotificationRequests()
        scheduleClassReminders()
        scheduleAssignmentReminders()
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Class reminders

    /// Schedule a "class in 10 minutes" notification for every session
    /// in the next 14 school days.
    private func scheduleClassReminders() {
        let engine = AppState.shared.scheduleEngine
        let enrollments = AppState.shared.enrollments
        let courses = AppState.shared.courses
        let cal = Calendar.current
        let today = Date()

        for dayOffset in 0..<14 {
            guard let date = cal.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let sessions = engine.studentMeetings(for: date, enrollments: enrollments, courses: courses)
            for session in sessions {
                scheduleClassReminder(session: session)
            }
        }
    }

    private func scheduleClassReminder(session: CourseSession) {
        let fireDate = session.startDateTime.addingTimeInterval(-10 * 60) // 10 min before
        guard fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = session.course.name
        content.body = "Starts in 10 minutes · \(session.course.room ?? "check schedule")"
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        // Stable ID: course id + date string so re-scheduling is idempotent
        let dateStr = fireDate.formatted(.iso8601.year().month().day())
        let id = "class-\(session.course.id)-\(dateStr)-\(session.slot.order)"
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    // MARK: - Assignment reminders

    /// Schedule reminders for assignments due in the next 7 days.
    /// Fires at 8:00 PM the evening before, and at 7:00 AM the morning of.
    private func scheduleAssignmentReminders() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let nextWeek = cal.date(byAdding: .day, value: 7, to: today) else { return }

        let upcoming = AppState.shared.assignments.filter { a in
            guard !a.isCompleted, let due = a.dueDate else { return false }
            return due >= today && due <= nextWeek
        }

        for assignment in upcoming {
            guard let due = assignment.dueDate else { continue }
            // Evening before
            if let dayBefore = cal.date(byAdding: .day, value: -1, to: due),
               let evening = cal.date(bySettingHour: 20, minute: 0, second: 0, of: dayBefore),
               evening > Date() {
                scheduleAssignmentNotification(
                    assignment: assignment,
                    fireDate: evening,
                    suffix: "evening",
                    body: "Due tomorrow"
                )
            }
            // Morning of
            if let morning = cal.date(bySettingHour: 7, minute: 0, second: 0, of: due),
               morning > Date() {
                scheduleAssignmentNotification(
                    assignment: assignment,
                    fireDate: morning,
                    suffix: "morning",
                    body: "Due today"
                )
            }
        }
    }

    private func scheduleAssignmentNotification(assignment: Assignment, fireDate: Date, suffix: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = assignment.title
        content.body = body
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let id = "assignment-\(assignment.id)-\(suffix)"
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
