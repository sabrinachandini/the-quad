import Foundation

/// Google Classroom integration spike.
///
/// SPIKE STATUS: Investigating whether LPS-managed Google accounts can authorize
/// the required OAuth scopes for third-party apps. See docs/OPEN_QUESTIONS.md.
///
/// Required OAuth scopes:
///   - https://www.googleapis.com/auth/classroom.courses.readonly
///   - https://www.googleapis.com/auth/classroom.coursework.me.readonly
///   - https://www.googleapis.com/auth/classroom.student-submissions.me.readonly
///
/// Known risk: LPS Workspace policy may restrict third-party OAuth.
/// Fallback: ManualAssignmentProvider (already implemented).
///
/// Implementation approach:
/// 1. Use GoogleSignIn SDK (add via SPM: https://github.com/google/GoogleSignIn-iOS)
/// 2. Request scopes above during sign-in
/// 3. Use URLSession with OAuth bearer token to call Classroom REST API
/// 4. Normalize response into [Assignment] via this provider
///
/// REST endpoints:
///   GET https://classroom.googleapis.com/v1/courses
///   GET https://classroom.googleapis.com/v1/courses/{courseId}/courseWork
///   GET https://classroom.googleapis.com/v1/courses/{courseId}/courseWork/{id}/studentSubmissions/me
final class ClassroomAssignmentProvider: AssignmentProvider {
    let provenance: DataProvenance = .classroom
    var isAvailable: Bool { oauthToken != nil }

    private var oauthToken: String?  // stored in Keychain in production

    // MARK: - Auth

    /// Attempt to sign in and acquire Classroom scopes.
    /// Returns true if scopes were granted, false if blocked by school policy.
    func signIn() async -> ClassroomAuthResult {
        // TODO: integrate GoogleSignIn SDK
        // For now, simulate the policy-blocked failure mode
        return .blockedBySchoolPolicy
    }

    enum ClassroomAuthResult {
        case success(token: String)
        case blockedBySchoolPolicy  // LPS Workspace may deny third-party scopes
        case userCancelled
        case error(Error)
    }

    // MARK: - AssignmentProvider

    func fetchAssignments(for courseIds: [UUID]) async throws -> [Assignment] {
        guard isAvailable else {
            throw ClassroomError.notAuthenticated
        }
        // TODO: implement REST calls
        // GET /v1/courses → map to internal Course IDs by matching course name
        // GET /v1/courses/{id}/courseWork → map to [Assignment]
        // GET /v1/.../studentSubmissions → set submissionState
        throw ClassroomError.notImplemented
    }

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
}
