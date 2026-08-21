import Foundation

// MARK: - Identity & People

struct User: Identifiable, Codable {
    let id: UUID
    var appleUserID: String?        // Sign in with Apple
    var lpsGoogleEmail: String?     // secondary LPS identity
    var displayName: String
    var createdAt: Date
}

struct StudentProfile: Identifiable, Codable {
    let id: UUID
    let userID: UUID
    var gradeLevel: Int             // 9–12
    var schoolYear: String          // "2025-26"
    var shareFreeBlocks: Bool       // opt-in availability sharing (never location)
    var enrollmentIDs: [UUID]
}

enum FriendshipStatus: String, Codable {
    case pending, accepted, declined, blocked
}

/// Friendship requires MUTUAL approval — only meaningful once `status == .accepted`.
struct Friendship: Identifiable, Codable {
    let id: UUID
    let requesterID: UUID
    let addresseeID: UUID
    var status: FriendshipStatus
    var requestedAt: Date
    var respondedAt: Date?

    var isMutual: Bool { status == .accepted }
}

// MARK: - Availability (COMPUTED, never stored as source of truth)

/// An interval when a student is free. This value is ALWAYS computed from the
/// bell schedule minus enrolled courses (see FreeBlockEngine). It is never
/// manually entered or persisted as authoritative. See docs/DATA_MODEL.md.
struct AvailabilityInterval: Identifiable, Codable, Equatable {
    let id: UUID
    let studentID: UUID
    let date: Date
    let start: Date
    let end: Date
    let label: String               // e.g. "Free (C block)"

    var durationMinutes: Int {
        Int(end.timeIntervalSince(start) / 60.0)
    }
}

// MARK: - Preferences & Integrations

struct NotificationPreference: Identifiable, Codable {
    let id: UUID
    var classChangeRemindersEnabled: Bool
    var classChangeLeadMinutes: Int
    var assignmentDueRemindersEnabled: Bool
    var assignmentDueLeadHours: Int
    var quietHoursStart: DateComponents?
    var quietHoursEnd: DateComponents?

    static let `default` = NotificationPreference(
        id: UUID(),
        classChangeRemindersEnabled: true,
        classChangeLeadMinutes: 5,
        assignmentDueRemindersEnabled: true,
        assignmentDueLeadHours: 12,
        quietHoursStart: nil,
        quietHoursEnd: nil
    )
}

enum IntegrationProvider: String, Codable {
    case googleClassroom, aspen, googleIdentity, apple
}

/// A per-provider connection. OAuth tokens / session data live in the device
/// Keychain and are referenced by `keychainRef` — never stored inline here.
struct IntegrationConnection: Identifiable, Codable {
    let id: UUID
    var provider: IntegrationProvider
    var isConnected: Bool
    var connectedEmail: String?
    var keychainRef: String?
    var lastSyncedAt: Date?
}

struct ICSSubscription: Identifiable, Codable {
    let id: UUID
    let userID: UUID
    var feedURL: URL
    var lastGeneratedAt: Date
    var includesAssignments: Bool
}

struct SchoolYear: Identifiable, Codable {
    let id: UUID
    var label: String               // "2025-26"
    var firstDay: Date
    var lastDay: Date
    var isVerified: Bool            // 2026-27 = false (needs_verification)
}
