# The Quad — Data Model

Swift-style pseudo-code for every core entity. Concrete Swift lives in `TheQuad/Models/`.

## Identity & People

```swift
struct User {
    let id: UUID
    var appleUserID: String?        // Sign in with Apple
    var lpsGoogleEmail: String?     // secondary identity
    var displayName: String
    var createdAt: Date
}

struct StudentProfile {
    let id: UUID
    let userID: UUID
    var gradeLevel: Int             // 9–12
    var schoolYear: String          // "2025-26"
    var shareFreeBlocks: Bool       // opt-in availability sharing (never location)
    var enrollmentIDs: [UUID]
}

// Friendship requires MUTUAL approval. It only exists once both sides accept.
struct Friendship {
    let id: UUID
    let requesterID: UUID
    let addresseeID: UUID
    var status: FriendshipStatus    // .pending, .accepted, .declined, .blocked
    var requestedAt: Date
    var respondedAt: Date?
}

enum FriendshipStatus { case pending, accepted, declined, blocked }
```

## Academics

```swift
struct Course {
    let id: UUID
    var name: String
    var teacher: String?
    var room: String?
    var block: AcademicBlock        // A–I or Homeroom
    var classCode: String?
    var colorIndex: Int
    var provenance: DataProvenance
}

struct Enrollment {
    let id: UUID
    let studentID: UUID
    let courseID: UUID
    let schoolYear: String
}

// A–I plus Homeroom/Flex (the "I block"). The block letter identifies the COURSE,
// not its time slot. Time slot depends on the DayType. See LHS_SCHEDULE_MODEL.md.
enum AcademicBlock { case a, b, c, d, e, f, g, h, i, homeroom, flex }
```

## Calendar & Schedule

```swift
struct SchoolYear {
    let id: UUID
    var label: String               // "2025-26"
    var firstDay: Date
    var lastDay: Date
    var isVerified: Bool            // 2026-27 = false (needs_verification)
}

// One row per calendar day. Maps a date to a DayType and optional overrides.
struct CalendarDate {
    let id: UUID
    var date: Date
    var dayType: DayType
    var bellScheduleOverride: BellSchedule?
    var note: String?
    var isVerified: Bool            // false = needs_verification
}

enum DayType {
    case day1, day2, day3, day4, day5, day6      // the 6-day rotation
    case noSchool, halfDay, delayedOpening        // special days
    case assembly, examSchedule, special
}

// The ordered set of meeting slots for a given day type.
struct BellSchedule {
    let id: UUID
    var name: String
    var dayType: DayType
    var slots: [MeetingSlot]        // ordered by .order
}

// One ordered meeting within a day. Ties a time slot to a block letter.
struct MeetingSlot {
    let id: UUID
    var order: Int
    var block: AcademicBlock
    var startTime: DateComponents   // hour + minute only
    var endTime: DateComponents
    var isLunch: Bool
}

// Admin override for a specific date. TRUMPS the generated rotation.
struct ScheduleOverride {
    let id: UUID
    var date: Date
    var overrideDayType: DayType
    var overrideBellSchedule: BellSchedule?
    var reason: String
    var setBy: String
    var setAt: Date
}
```

## Work

```swift
struct Assignment {                 // typically from Classroom
    let id: UUID
    var title: String
    var description: String?
    var courseID: UUID?
    var dueDate: Date?
    var classroomURL: URL?
    var submissionState: SubmissionState
    var estimatedMinutes: Int?
    var provenance: DataProvenance
    var isCompleted: Bool
}

enum SubmissionState { case notStarted, inProgress, turnedIn, returned, missing, graded }

struct Task {                       // student-created
    let id: UUID
    var title: String
    var taskType: TaskType
    var courseID: UUID?
    var dueDate: Date?
    var estimatedMinutes: Int?
    var notes: String?
    var isCompleted: Bool
    var priority: Int               // 0 normal, 1 important, 2 critical
}

enum TaskType { case assignment, quiz, test, project, reading, study, other }
```

## Grades

```swift
struct CourseGrade {
    let id: UUID
    let courseID: UUID
    var currentGrade: Double?
    var letterGrade: String?
    var categories: [GradeCategory]
    var provenance: DataProvenance
}

struct GradeCategory {
    let id: UUID
    var name: String
    var weight: Double               // 0.0–1.0
    var entries: [GradeEntry]
}

struct GradeEntry {
    let id: UUID
    var title: String
    var pointsEarned: Double?
    var pointsPossible: Double
    var isDropped: Bool
    var date: Date?
    var provenance: DataProvenance
}
```

## Availability (COMPUTED)

```swift
// AvailabilityInterval is ALWAYS COMPUTED — bell schedule minus enrolled courses.
// It is NEVER manually stored or entered. Recompute on demand from the schedule.
struct AvailabilityInterval {
    let id: UUID
    let studentID: UUID
    let date: Date
    let start: Date
    let end: Date
    let label: String                // e.g. "Free (C block)"
}
```

> **Invariant:** There is no user-facing way to "add a free block." Free time is a *derivation*, not a record. Any code that tries to persist `AvailabilityInterval` as source-of-truth is a bug.

## Outputs & Integrations

```swift
struct ICSSubscription {
    let id: UUID
    let userID: UUID
    var feedURL: URL
    var lastGeneratedAt: Date
    var includesAssignments: Bool
}

struct NotificationPreference {
    let id: UUID
    var classChangeRemindersEnabled: Bool
    var classChangeLeadMinutes: Int
    var assignmentDueRemindersEnabled: Bool
    var assignmentDueLeadHours: Int
    var quietHoursStart: DateComponents?
    var quietHoursEnd: DateComponents?
}

struct IntegrationConnection {
    let id: UUID
    var provider: IntegrationProvider   // .googleClassroom, .aspen, .googleIdentity, .apple
    var isConnected: Bool
    var connectedEmail: String?
    // OAuth tokens / session data stored in device Keychain, referenced by handle — never inline here.
    var keychainRef: String?
    var lastSyncedAt: Date?
}

enum IntegrationProvider { case googleClassroom, aspen, googleIdentity, apple }

enum DataProvenance { case classroom, aspen, student, parsedSchedule, admin, inferred }
```
