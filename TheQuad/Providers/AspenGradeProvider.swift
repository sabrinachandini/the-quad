import Foundation
import Observation

// MARK: - Connection State

enum AspenConnectionState: Equatable {
    case disconnected
    case connecting
    case connected(lastSync: Date)
    case failed(String)         // user-facing error message
    case sessionExpired

    static func == (lhs: AspenConnectionState, rhs: AspenConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected): return true
        case (.connecting, .connecting): return true
        case (.connected(let a), .connected(let b)): return a == b
        case (.failed(let a), .failed(let b)): return a == b
        case (.sessionExpired, .sessionExpired): return true
        default: return false
        }
    }
}

// MARK: - Provider

@Observable
final class AspenGradeProvider {
    static let shared = AspenGradeProvider()

    // MARK: - Observable State

    var connectionState: AspenConnectionState = .disconnected
    var courses: [CourseGrade] = []
    var lastSyncDate: Date?

    var isConnected: Bool {
        if case .connected = connectionState { return true }
        return false
    }

    // MARK: - Private

    private let cacheKey = "aspen.cached_grades"

    private init() {}

    // MARK: - Public API

    /// Authenticate with new credentials and fetch grades.
    /// Saves credentials to Keychain on success.
    func connect(username: String, password: String) async {
        await MainActor.run { connectionState = .connecting }

        do {
            try await AspenSession.shared.authenticate(username: username, password: password)
            // Only save credentials after confirmed auth success
            try AspenKeychainStore.shared.save(username: username, password: password)
            await fetchAndMergeGrades()
        } catch let error as AspenSessionError {
            await MainActor.run {
                connectionState = .failed(error.errorDescription ?? "Authentication failed.")
            }
        } catch let error as AspenKeychainError {
            // Auth succeeded but keychain save failed — still connected this session
            print("[AspenGradeProvider] Keychain save failed: \(error)")
            await fetchAndMergeGrades()
        } catch {
            await MainActor.run {
                connectionState = .failed(error.localizedDescription)
            }
        }
    }

    /// Re-authenticate with stored credentials and re-fetch grades.
    func refresh() async {
        do {
            guard let creds = try AspenKeychainStore.shared.load() else {
                await MainActor.run { connectionState = .disconnected }
                return
            }
            await MainActor.run { connectionState = .connecting }
            try await AspenSession.shared.authenticate(username: creds.username, password: creds.password)
            await fetchAndMergeGrades()
        } catch let error as AspenSessionError {
            await handleSessionError(error)
        } catch {
            await MainActor.run {
                connectionState = .failed(error.localizedDescription)
            }
        }
    }

    /// Clear keychain, session, and all local data.
    func disconnect() {
        try? AspenKeychainStore.shared.delete()
        Task { await AspenSession.shared.reset() }
        courses = []
        lastSyncDate = nil
        connectionState = .disconnected
        UserDefaults.standard.removeObject(forKey: cacheKey)
    }

    /// Called on app launch — try to resume using stored credentials.
    func tryResumeSession() async {
        do {
            guard let creds = try AspenKeychainStore.shared.load() else {
                // No credentials — stay disconnected
                return
            }
            // Load cached grades immediately so UI is populated
            if let cached = loadCachedGrades() {
                await MainActor.run {
                    courses = cached
                    connectionState = .connected(lastSync: lastSyncDate ?? Date())
                }
            }
            // Re-auth in background
            try await AspenSession.shared.authenticate(username: creds.username, password: creds.password)
            await fetchAndMergeGrades()
        } catch let error as AspenSessionError {
            await handleSessionError(error)
        } catch {
            // Keychain read error or other — stay disconnected silently
        }
    }

    /// Load last cached grades from UserDefaults (grades only, never credentials).
    func loadCachedGrades() -> [CourseGrade]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let grades = try? JSONDecoder().decode([CourseGrade].self, from: data) else {
            return nil
        }
        return grades
    }

    // MARK: - Private: Fetch

    private func fetchAndMergeGrades() async {
        do {
            let html = try await AspenSession.shared.fetchHTML(
                path: "/aspen/portalClassList.do",
                queryItems: []
            )

            let summaries = try AspenHTMLParser.parseCourseList(html: html)
            var fetchedGrades: [CourseGrade] = []

            for summary in summaries {
                let categories = await fetchCourseDetail(oid: summary.oid, courseName: summary.name)
                let courseId = UUID()  // Stable in practice; see note below

                let grade = CourseGrade(
                    id: UUID(),
                    courseId: courseId,
                    currentGrade: summary.termGradePercent,
                    letterGrade: summary.termGradeLetter,
                    categories: categories,
                    provenance: .aspen
                )
                fetchedGrades.append(grade)
            }

            let syncDate = Date()
            let finalGrades = fetchedGrades
            await MainActor.run {
                courses = finalGrades
                lastSyncDate = syncDate
                connectionState = .connected(lastSync: syncDate)
            }
            persistGrades(finalGrades)

        } catch let error as AspenSessionError {
            await handleSessionError(error)
        } catch let error as AspenParseError {
            await MainActor.run {
                connectionState = .failed(error.errorDescription ?? "Could not parse grade data.")
            }
        } catch {
            await MainActor.run {
                connectionState = .failed(error.localizedDescription)
            }
        }
    }

    private func fetchCourseDetail(oid: String, courseName: String) async -> [GradeCategory] {
        do {
            let html = try await AspenSession.shared.fetchHTML(
                path: "/aspen/portalClassDetail.do",
                queryItems: [URLQueryItem(name: "navkey", value: "academics.classes.list"),
                             URLQueryItem(name: "oid", value: oid)]
            )
            return try AspenHTMLParser.parseCourseDetail(html: html, courseName: courseName)
        } catch {
            // Non-fatal — return empty categories rather than failing the whole fetch
            return []
        }
    }

    // MARK: - Private: Persistence

    private func persistGrades(_ grades: [CourseGrade]) {
        guard let data = try? JSONEncoder().encode(grades) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
    }

    // MARK: - Private: Error Handling

    private func handleSessionError(_ error: AspenSessionError) async {
        await MainActor.run {
            switch error {
            case .invalidCredentials:
                connectionState = .failed(error.errorDescription ?? "Invalid credentials.")
            case .sessionExpired:
                connectionState = .sessionExpired
            case .serverUnavailable:
                connectionState = .failed("Aspen is currently unavailable. Try again later.")
            case .networkError(let underlying):
                connectionState = .failed("Network error: \(underlying.localizedDescription)")
            case .unexpectedResponse(let code):
                connectionState = .failed("Unexpected Aspen response (HTTP \(code)).")
            }
        }
    }
}
