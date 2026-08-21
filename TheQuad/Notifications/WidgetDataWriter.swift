import Foundation
import WidgetKit

/// Writes current schedule state to the shared widget data store.
/// Call whenever schedule or date changes.
final class WidgetDataWriter {
    static let shared = WidgetDataWriter()
    private init() {}

    func update() {
        let engine = AppState.shared.scheduleEngine
        let enrollments = AppState.shared.enrollments
        let courses = AppState.shared.courses
        let now = Date()
        let cal = Calendar.current

        let currentSession = engine.currentMeeting(at: now, enrollments: enrollments, courses: courses)
        let nextSession = engine.nextMeeting(after: now, enrollments: enrollments, courses: courses)

        let dayType = engine.dayType(for: now)
        let dayBadge: String
        if let dt = dayType, let n = dt.rotationIndex {
            dayBadge = "Day \(n + 1)"
        } else if dayType == nil {
            dayBadge = "No School"
        } else {
            dayBadge = "Special"
        }

        let assignmentsDueToday = AppState.shared.assignments.filter { a in
            guard !a.isCompleted, let due = a.dueDate else { return false }
            return cal.isDate(due, inSameDayAs: now)
        }.count

        let data = WidgetScheduleData(
            currentCourseName: currentSession?.course.name,
            currentCourseRoom: currentSession?.course.room,
            currentEndTime: currentSession?.endDateTime,
            nextCourseName: nextSession?.course.name,
            nextCourseRoom: nextSession?.course.room,
            nextStartTime: nextSession?.startDateTime,
            dayBadge: dayBadge,
            todayDateLabel: now.formatted(.dateTime.weekday(.wide)),
            assignmentsDueToday: assignmentsDueToday,
            updatedAt: now
        )
        WidgetDataStore.write(data)
    }
}
