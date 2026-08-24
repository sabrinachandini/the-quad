import Foundation
import Observation

@Observable
final class SchoolViewModel {
    private let engine = AppState.shared.scheduleEngine

    var searchText: String = ""
    var selectedFriendId: UUID? = nil

    // MARK: - Directory

    /// All directory users, filtered by the live search text.
    var filteredDirectory: [User] {
        let all = AppState.shared.directory
        guard !searchText.isEmpty else { return all }
        return all.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Social lists

    var friends: [User] { AppState.shared.friends }
    var pendingRequests: [User] { AppState.shared.pendingFriends }

    var filteredFriends: [User] {
        guard !searchText.isEmpty else { return friends }
        return friends.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }

    var filteredClassmates: [User] {
        guard !searchText.isEmpty else { return classmates }
        return classmates.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Classmates

    /// Directory users who share at least one block with the current user.
    var classmates: [User] {
        let myBlocks = Set(AppState.shared.courses.map { $0.block })
        return AppState.shared.directory.filter { user in
            guard let theirCourses = AppState.shared.friendCourses[user.id] else { return false }
            let theirBlocks = Set(theirCourses.map { $0.block })
            return !myBlocks.isDisjoint(with: theirBlocks)
        }
    }

    /// Shared block letters between me and a specific classmate.
    func sharedBlocks(with user: User) -> [AcademicBlock] {
        let myBlocks = Set(AppState.shared.courses.map { $0.block })
        guard let theirCourses = AppState.shared.friendCourses[user.id] else { return [] }
        let theirBlocks = Set(theirCourses.map { $0.block })
        return Array(myBlocks.intersection(theirBlocks)).sorted { $0.rawValue < $1.rawValue }
    }

    // MARK: - Free-block overlap

    /// Shared free blocks with a specific friend today.
    func sharedFreeBlocks(with friend: User) -> [AvailabilityInterval] {
        let today = Date()
        let allSlots = engine.meetings(for: today)
        guard !allSlots.isEmpty else { return [] }

        let myEnrollments = AppState.shared.enrollments
        let myCourses = AppState.shared.courses
        let mySessions = engine.studentMeetings(for: today, enrollments: myEnrollments, courses: myCourses)

        let freeEngine = FreeBlockEngine()
        let myFree = freeEngine.freeBlocks(for: today, allSlots: allSlots, studentSessions: mySessions)

        guard let theirCourses = AppState.shared.friendCourses[friend.id] else { return myFree }
        let theirEnrollments = theirCourses.map { course in
            Enrollment(id: UUID(), studentId: friend.id, courseId: course.id, schoolYear: "2026-27")
        }
        let theirSessions = engine.studentMeetings(for: today, enrollments: theirEnrollments, courses: theirCourses)
        let theirFree = freeEngine.freeBlocks(for: today, studentId: friend.id, allSlots: allSlots, studentSessions: theirSessions)

        return freeEngine.sharedFreeBlocks(studentA: myFree, studentB: theirFree)
    }

    // MARK: - Friend request actions

    func acceptFriend(_ user: User) {
        AppState.shared.pendingFriends.removeAll { $0.id == user.id }
        if !AppState.shared.friends.contains(where: { $0.id == user.id }) {
            AppState.shared.friends.append(user)
        }
    }

    func declineFriend(_ user: User) {
        AppState.shared.pendingFriends.removeAll { $0.id == user.id }
    }

    // MARK: - Free block formatting helpers

    /// Returns a short human-readable label for a free-block overlap relative to now.
    func freeOverlapLabel(for friend: User) -> String? {
        let shared = sharedFreeBlocks(with: friend)
        guard !shared.isEmpty else { return nil }
        let now = Date()
        if let current = shared.first(where: { $0.start <= now && now < $0.end }) {
            let mins = current.durationMinutes - Int(now.timeIntervalSince(current.start) / 60)
            return "Free now · \(mins)m"
        }
        if let next = shared.first(where: { $0.start > now }) {
            let fmt = next.start.formatted(.dateTime.hour().minute())
            return "Next free: \(fmt)"
        }
        return nil
    }
}
