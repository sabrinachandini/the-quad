import Foundation

/// Source of a student's schedule (e.g. parsed from an uploaded screenshot/PDF).
/// Yields the courses + enrollments the student is in.
protocol ScheduleSource {
    var provenance: DataProvenance { get }

    /// Produce the courses and enrollments this source knows about for a year.
    func loadSchedule(schoolYear: String) async throws -> (courses: [Course], enrollments: [Enrollment])
}
