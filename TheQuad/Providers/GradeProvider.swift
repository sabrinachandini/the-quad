import Foundation

/// Source of grades. Concrete implementation (Aspen) arrives in Phase 5.
/// App logic couples only to this protocol.
protocol GradeProvider {
    var provenance: DataProvenance { get }
    var isAvailable: Bool { get }

    /// Fetch current grades for the given courses.
    func fetchGrades(for courseIds: [UUID]) async throws -> [CourseGrade]
}
