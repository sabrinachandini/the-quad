import Foundation

// MARK: - Integration Status
// Aspen:    IMPLEMENTED (device-side authenticated web session)
// Parser:   TESTED WITH FIXTURE (not yet TESTED AGAINST REAL SERVICE)
// Auth:     TESTED WITH FIXTURE

protocol GradeProvider: AnyObject {
    var provenance: DataProvenance { get }
    var isConnected: Bool { get }

    func connect(username: String, password: String) async throws
    func fetchCourses() async throws -> [CourseGrade]
    func refresh() async throws
    func disconnect() async throws
}
