import Foundation

struct Course: Identifiable, Codable {
    let id: UUID
    var name: String
    var teacher: String?
    var room: String?
    var block: AcademicBlock
    var classCode: String?
    var colorIndex: Int
    var provenance: DataProvenance
}

struct Enrollment: Identifiable, Codable {
    let id: UUID
    let studentId: UUID
    let courseId: UUID
    let schoolYear: String  // e.g. "2025-26"
}

enum DataProvenance: String, Codable {
    case classroom, aspen, student, parsedSchedule, admin, inferred
}
