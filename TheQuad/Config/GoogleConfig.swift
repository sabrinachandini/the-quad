import Foundation

struct GoogleConfig {
    // Read from GoogleService.plist (not committed to git).
    // Returns nil if the file isn't present — app degrades gracefully.
    static var clientID: String? {
        plist?["CLIENT_ID"] as? String
    }
    static var reversedClientID: String? {
        plist?["REVERSED_CLIENT_ID"] as? String
    }
    static let redirectURISuffix = ":/oauth2callback"
    static let authorizationEndpoint = "https://accounts.google.com/o/oauth2/v2/auth"
    static let tokenEndpoint = "https://oauth2.googleapis.com/token"
    static let classroomAPIBase = "https://classroom.googleapis.com/v1"
    static let scopes = [
        "https://www.googleapis.com/auth/classroom.courses.readonly",
        "https://www.googleapis.com/auth/classroom.coursework.me.readonly",
        "https://www.googleapis.com/auth/classroom.student-submissions.me.readonly",
        "email",
        "profile"
    ]

    private static var plist: [String: Any]? {
        guard let url = Bundle.main.url(forResource: "GoogleService", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url) as? [String: Any] else {
            return nil
        }
        return dict
    }
}
