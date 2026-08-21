import Foundation

/// Google Classroom integration — Phase 2 implementation.
///
/// Uses OAuth 2.0 + PKCE (ASWebAuthenticationSession) to obtain tokens,
/// then calls the Classroom REST API to fetch courses, coursework, and
/// student submissions, normalizing them into [Assignment].
///
/// Known risk: LPS Workspace policy may restrict third-party OAuth.
/// Fallback: ManualAssignmentProvider (already implemented).
///
/// REST endpoints:
///   GET https://classroom.googleapis.com/v1/courses
///   GET https://classroom.googleapis.com/v1/courses/{courseId}/courseWork
///   GET https://classroom.googleapis.com/v1/courses/{courseId}/courseWork/{id}/studentSubmissions?userId=me

// MARK: - Classroom API response models

struct ClassroomCourse: Codable {
    let id: String?
    let name: String?
    let section: String?
    let room: String?
}

struct ClassroomCourseWork: Codable {
    let id: String?
    let courseId: String?
    let title: String?
    let description: String?
    let dueDate: GDate?
    let dueTime: GTime?
    let maxPoints: Double?
    let state: String?
    let alternateLink: String?
}

struct GDate: Codable {
    let year: Int?
    let month: Int?
    let day: Int?
}

struct GTime: Codable {
    let hours: Int?
    let minutes: Int?
}

struct ClassroomSubmission: Codable {
    let id: String?
    let courseId: String?
    let courseWorkId: String?
    let userId: String?
    let state: String?
    let late: Bool?
    let assignedGrade: Double?
}

private struct CourseListResponse: Codable {
    let courses: [ClassroomCourse]?
}

private struct CourseWorkListResponse: Codable {
    let courseWork: [ClassroomCourseWork]?
}

private struct SubmissionListResponse: Codable {
    let studentSubmissions: [ClassroomSubmission]?
}

// MARK: - ClassroomAssignmentProvider

final class ClassroomAssignmentProvider: AssignmentProvider {
    static let shared = ClassroomAssignmentProvider()

    let provenance: DataProvenance = .classroom
    var isAvailable: Bool {
        (try? ClassroomTokenStore.shared.loadAccessToken()) != nil
    }

    private init() {}

    // MARK: - AssignmentProvider

    func fetchAssignments(for courseIds: [UUID]) async throws -> [Assignment] {
        let accessToken = try await validAccessToken()
        let courses = try await fetchCourses(accessToken: accessToken)

        var assignments: [Assignment] = []

        for course in courses {
            guard let courseId = course.id else { continue }
            let courseWorkItems: [ClassroomCourseWork]
            do {
                courseWorkItems = try await fetchCourseWork(courseId: courseId, accessToken: accessToken)
            } catch {
                continue
            }

            for work in courseWorkItems {
                guard let workId = work.id else { continue }
                let submissions: [ClassroomSubmission]
                do {
                    submissions = try await fetchSubmissions(courseId: courseId, courseWorkId: workId, accessToken: accessToken)
                } catch {
                    submissions = []
                }

                let submission = submissions.first
                let dueDate = buildDueDate(date: work.dueDate, time: work.dueTime)
                let submissionState = mapSubmissionState(submission?.state)
                let classroomURL = work.alternateLink.flatMap { URL(string: $0) }

                let assignment = Assignment(
                    id: UUID(),
                    title: work.title ?? "Untitled",
                    description: work.description,
                    courseId: nil,  // Classroom course IDs are strings; no UUID mapping without onboarding match
                    dueDate: dueDate,
                    classroomURL: classroomURL,
                    submissionState: submissionState,
                    estimatedMinutes: nil,
                    provenance: .classroom,
                    isCompleted: submissionState == .turnedIn || submissionState == .returned || submissionState == .graded
                )
                assignments.append(assignment)
            }
        }

        return assignments
    }

    // MARK: - REST methods

    func fetchCourses(accessToken: String) async throws -> [ClassroomCourse] {
        let url = URL(string: "\(GoogleConfig.classroomAPIBase)/courses?studentId=me&courseStates=ACTIVE")!
        let data = try await authorizedGet(url: url, accessToken: accessToken, retryOnUnauthorized: true)
        let response = try JSONDecoder().decode(CourseListResponse.self, from: data)
        return response.courses ?? []
    }

    func fetchCourseWork(courseId: String, accessToken: String) async throws -> [ClassroomCourseWork] {
        let url = URL(string: "\(GoogleConfig.classroomAPIBase)/courses/\(courseId)/courseWork?courseWorkStates=PUBLISHED")!
        let data = try await authorizedGet(url: url, accessToken: accessToken, retryOnUnauthorized: true)
        let response = try JSONDecoder().decode(CourseWorkListResponse.self, from: data)
        return response.courseWork ?? []
    }

    func fetchSubmissions(courseId: String, courseWorkId: String, accessToken: String) async throws -> [ClassroomSubmission] {
        let url = URL(string: "\(GoogleConfig.classroomAPIBase)/courses/\(courseId)/courseWork/\(courseWorkId)/studentSubmissions?userId=me")!
        let data = try await authorizedGet(url: url, accessToken: accessToken, retryOnUnauthorized: true)
        let response = try JSONDecoder().decode(SubmissionListResponse.self, from: data)
        return response.studentSubmissions ?? []
    }

    // MARK: - Legacy auth result type (kept for source compatibility)

    enum ClassroomAuthResult {
        case success(token: String)
        case blockedBySchoolPolicy
        case userCancelled
        case error(Error)
    }

    // MARK: - Error types

    enum ClassroomError: LocalizedError {
        case notAuthenticated
        case notImplemented
        case scopesDenied
        case networkError(Error)

        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "Sign in to Google Classroom first."
            case .notImplemented:
                return "Classroom sync not yet implemented."
            case .scopesDenied:
                return "Your school's Google account doesn't allow third-party Classroom access."
            case .networkError(let e):
                return e.localizedDescription
            }
        }
    }

    // MARK: - Private helpers

    private func validAccessToken() async throws -> String {
        if let expiry = try ClassroomTokenStore.shared.loadExpiry(), expiry < Date() {
            await ClassroomAuthProvider.shared.refresh()
        }
        guard let token = try ClassroomTokenStore.shared.loadAccessToken() else {
            throw ClassroomError.notAuthenticated
        }
        return token
    }

    private func authorizedGet(url: URL, accessToken: String, retryOnUnauthorized: Bool) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode == 401, retryOnUnauthorized {
            // Refresh and retry once
            await ClassroomAuthProvider.shared.refresh()
            guard let freshToken = try ClassroomTokenStore.shared.loadAccessToken() else {
                throw ClassroomError.notAuthenticated
            }
            var retryRequest = URLRequest(url: url)
            retryRequest.setValue("Bearer \(freshToken)", forHTTPHeaderField: "Authorization")
            let (retryData, _) = try await URLSession.shared.data(for: retryRequest)
            return retryData
        }
        return data
    }

    private func mapSubmissionState(_ state: String?) -> SubmissionState {
        switch state {
        case "CREATED": return .inProgress
        case "TURNED_IN": return .turnedIn
        case "RETURNED": return .returned
        case "RECLAIMED_BY_STUDENT": return .inProgress
        default: return .notStarted
        }
    }

    private func buildDueDate(date: GDate?, time: GTime?) -> Date? {
        guard let date = date, let year = date.year, let month = date.month, let day = date.day else { return nil }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = time?.hours ?? 23
        components.minute = time?.minutes ?? 59
        components.timeZone = TimeZone.current
        return Calendar.current.date(from: components)
    }
}
