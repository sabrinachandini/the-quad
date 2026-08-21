import Foundation

/// Source of assignments. Concrete providers (Classroom, manual) conform so app
/// logic never couples to a vendor. See docs/ARCHITECTURE.md.
protocol AssignmentProvider {
    var provenance: DataProvenance { get }
    var isAvailable: Bool { get }

    /// Fetch assignments for the given courses. Implementations may be async
    /// (network) or synchronous (local).
    func fetchAssignments(for courseIds: [UUID]) async throws -> [Assignment]
}

/// Local, always-available provider backing manually entered work. This is the
/// schedule-only-tier fallback when Classroom is unavailable.
final class ManualAssignmentProvider: AssignmentProvider {
    let provenance: DataProvenance = .student
    let isAvailable: Bool = true

    private var store: [Assignment]

    init(assignments: [Assignment] = []) {
        self.store = assignments
    }

    func fetchAssignments(for courseIds: [UUID]) async throws -> [Assignment] {
        guard !courseIds.isEmpty else { return store }
        let idSet = Set(courseIds)
        return store.filter { assignment in
            guard let cid = assignment.courseId else { return true }
            return idSet.contains(cid)
        }
    }

    func add(_ assignment: Assignment) {
        store.append(assignment)
    }

    func update(_ assignment: Assignment) {
        if let idx = store.firstIndex(where: { $0.id == assignment.id }) {
            store[idx] = assignment
        }
    }

    func remove(id: UUID) {
        store.removeAll { $0.id == id }
    }
}
