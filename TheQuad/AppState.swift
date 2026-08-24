import Foundation
import Observation

@Observable
final class AppState {
    static let shared = AppState()

    var courses: [Course]
    var enrollments: [Enrollment]
    var hasCompletedOnboarding: Bool
    var assignments: [Assignment]
    var grades: [CourseGrade]
    var displayName: String
    var graduationYear: Int
    var classRemindersEnabled: Bool

    // MARK: - Providers
    var aspenProvider: AspenGradeProvider = .shared
    var classroomProvider: ClassroomAuthProvider = .shared

    // MARK: - Social

    /// The signed-in student as a User record.
    var currentUser: User

    /// Students who have accepted a mutual friendship.
    var friends: [User]

    /// Inbound friend requests waiting for my response.
    var pendingFriends: [User]

    /// All LHS students who are discoverable in the directory.
    var directory: [User]

    /// Courses for each friend (friendId → their courses). Used for free-overlap.
    var friendCourses: [UUID: [Course]]

    var scheduleEngine: ScheduleEngine {
        ScheduleEngine(
            calendarDates: LHSFixtures_2025_26.calendarDates_2026_27,
            overrides: [],
            bellSchedules: LHSFixtures_2025_26.allBellSchedules
        )
    }

    private init() {
        self.courses = MockStudentSchedule.courses
        self.enrollments = MockStudentSchedule.enrollments
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "quad_onboarding_complete")
        self.assignments = WorkViewModel.mockAssignments()
        // Load cached Aspen grades if available; fall back to mock for dev
        if let cached = AspenGradeProvider.shared.loadCachedGrades() {
            self.grades = cached
        } else {
            self.grades = GradesViewModel.mockGrades()  // dev fallback
        }
        self.displayName = "Student"
        self.graduationYear = 2026
        self.classRemindersEnabled = true

        let dir = AppState.mockDirectory()
        self.directory = dir
        self.currentUser = User(
            id: MockStudentSchedule.studentId,
            appleUserID: nil,
            lpsGoogleEmail: "student@lps.lexingtonma.org",
            displayName: "Student",
            graduationYear: 2026,
            isInDirectory: true,
            showClassesInDirectory: true,
            createdAt: Date()
        )

        // Three accepted friends from the directory
        let friendIDs = [dir[0].id, dir[2].id, dir[5].id]
        self.friends = dir.filter { friendIDs.contains($0.id) }

        // Two pending inbound requests
        self.pendingFriends = [dir[8], dir[11]]

        // Mock courses for each friend — spread across different blocks for realistic overlap
        var fc: [UUID: [Course]] = [:]
        fc[dir[0].id] = [
            Course(id: UUID(), name: "AP Biology", teacher: "Ms. Lee", room: "210",
                   block: .a, classCode: nil, colorIndex: 0, provenance: .parsedSchedule),
            Course(id: UUID(), name: "AP English Lit", teacher: "Mr. Walsh", room: "104",
                   block: .c, classCode: nil, colorIndex: 3, provenance: .parsedSchedule),
            Course(id: UUID(), name: "Statistics", teacher: "Ms. Nguyen", room: "321",
                   block: .e, classCode: nil, colorIndex: 4, provenance: .parsedSchedule),
            Course(id: UUID(), name: "French IV", teacher: "Mme. Bernard", room: "132",
                   block: .g, classCode: nil, colorIndex: 5, provenance: .parsedSchedule),
        ]
        fc[dir[2].id] = [
            Course(id: UUID(), name: "AP Calculus BC", teacher: "Mr. Park", room: "316",
                   block: .b, classCode: nil, colorIndex: 1, provenance: .parsedSchedule),
            Course(id: UUID(), name: "AP US History", teacher: "Mr. Rodriguez", room: "115",
                   block: .b, classCode: nil, colorIndex: 1, provenance: .parsedSchedule),
            Course(id: UUID(), name: "Orchestra", teacher: "Mr. Kim", room: "Auditorium",
                   block: .c, classCode: nil, colorIndex: 2, provenance: .parsedSchedule),
            Course(id: UUID(), name: "Computer Science A", teacher: "Ms. Torres", room: "Lab 2",
                   block: .h, classCode: nil, colorIndex: 6, provenance: .parsedSchedule),
        ]
        fc[dir[5].id] = [
            Course(id: UUID(), name: "AP Chemistry", teacher: "Ms. Chen", room: "234",
                   block: .a, classCode: nil, colorIndex: 0, provenance: .parsedSchedule),
            Course(id: UUID(), name: "English 11", teacher: "Ms. Thompson", room: "203",
                   block: .d, classCode: nil, colorIndex: 3, provenance: .parsedSchedule),
            Course(id: UUID(), name: "Studio Art", teacher: "Mr. Osei", room: "Art Wing",
                   block: .f, classCode: nil, colorIndex: 7, provenance: .parsedSchedule),
        ]
        self.friendCourses = fc

        // Try to resume provider sessions in background
        Task { await AspenGradeProvider.shared.tryResumeSession() }
        Task { await ClassroomAuthProvider.shared.tryResumeSession() }
    }

    // MARK: - Mock Directory

    static func mockDirectory() -> [User] {
        let names: [(String, Int)] = [
            ("Maya Patel", 2026),
            ("Jordan Lee", 2027),
            ("Alex Rivera", 2026),
            ("Sam Chen", 2028),
            ("Priya Nair", 2026),
            ("Chris Okafor", 2027),
            ("Lily Zhao", 2026),
            ("Marcus Webb", 2028),
            ("Sofia Hernandez", 2027),
            ("Ethan Kim", 2026),
            ("Aisha Johnson", 2027),
            ("Noah Goldstein", 2026),
            ("Zoe Andersen", 2028),
            ("Caleb Murphy", 2027),
            ("Riya Shah", 2026),
            ("Dylan Park", 2027),
            ("Nia Brooks", 2026),
            ("Luca Romano", 2028),
        ]
        return names.enumerated().map { idx, pair in
            User(
                id: UUID(uuidString: String(format: "BBBBBBBB-BBBB-BBBB-BBBB-%012d", idx + 1))!,
                appleUserID: nil,
                lpsGoogleEmail: nil,
                displayName: pair.0,
                graduationYear: pair.1,
                isInDirectory: true,
                showClassesInDirectory: true,
                createdAt: Date()
            )
        }
    }
}
