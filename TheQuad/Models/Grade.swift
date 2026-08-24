import Foundation

struct CourseGrade: Identifiable, Codable {
    let id: UUID
    let courseId: UUID
    var name: String          // display name — either from Aspen or the linked Course
    var currentGrade: Double?
    var letterGrade: String?
    var categories: [GradeCategory]
    var provenance: DataProvenance
}

struct GradeCategory: Identifiable, Codable {
    let id: UUID
    var name: String
    var weight: Double  // 0.0-1.0
    var entries: [GradeEntry]

    var average: Double? {
        let gradedEntries = entries.filter { !$0.isDropped && $0.pointsEarned != nil }
        guard !gradedEntries.isEmpty else { return nil }
        let total = gradedEntries.reduce(0.0) { $0 + ($1.pointsEarned! / $1.pointsPossible) }
        return (total / Double(gradedEntries.count)) * 100.0
    }
}

struct GradeEntry: Identifiable, Codable {
    let id: UUID
    var title: String
    var pointsEarned: Double?
    var pointsPossible: Double
    var isDropped: Bool
    var date: Date?
    var provenance: DataProvenance
}
