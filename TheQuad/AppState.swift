import Foundation
import Observation

@Observable
final class AppState {
    static let shared = AppState()

    var courses: [Course]
    var enrollments: [Enrollment]
    var hasCompletedOnboarding: Bool
    var assignments: [Assignment]

    var scheduleEngine: ScheduleEngine {
        ScheduleEngine(
            calendarDates: LHSFixtures_2025_26.calendarDates_2025_26,
            overrides: [],
            bellSchedules: LHSFixtures_2025_26.allBellSchedules
        )
    }

    private init() {
        self.courses = MockStudentSchedule.courses
        self.enrollments = MockStudentSchedule.enrollments
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "quad_onboarding_complete")
        self.assignments = WorkViewModel.mockAssignments()
    }
}
