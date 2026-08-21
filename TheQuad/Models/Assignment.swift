import Foundation

struct Assignment: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String?
    var courseId: UUID?
    var dueDate: Date?
    var classroomURL: URL?
    var submissionState: SubmissionState
    var estimatedMinutes: Int?
    var provenance: DataProvenance
    var isCompleted: Bool
}

enum SubmissionState: String, Codable {
    case notStarted, inProgress, turnedIn, returned, missing, graded
}

struct StudentTask: Identifiable, Codable {
    let id: UUID
    var title: String
    var taskType: TaskType
    var courseId: UUID?
    var dueDate: Date?
    var estimatedMinutes: Int?
    var notes: String?
    var isCompleted: Bool
    var priority: Int  // 0 = normal, 1 = important, 2 = critical
}

enum TaskType: String, Codable, CaseIterable {
    case assignment, quiz, test, project, reading, study, other
}
