import Foundation

/// A suggested unit of work placed into a window of free time.
struct PlannerSuggestion: Identifiable {
    let id: UUID
    let taskId: UUID
    let title: String
    let score: Double            // higher = more urgent/important
    let suggestedInterval: AvailabilityInterval?
}

/// Deterministic priority scoring + free-time allocation. Deterministic first,
/// AI enrichment later — inspectability over magic (see docs/DECISIONS.md).
struct PlannerEngine {

    /// Score a task's urgency/importance. Deterministic: driven by due date
    /// proximity, explicit priority, and estimated effort.
    func score(for task: Task, now: Date) -> Double {
        // TODO: implement deterministic scoring in Phase 6.
        // Sketch: urgency from (dueDate - now), boosted by task.priority,
        // and estimatedMinutes as a tie-breaker.
        return 0
    }

    /// Rank tasks by score, most urgent first.
    func prioritize(tasks: [Task], now: Date) -> [Task] {
        // TODO: implement in Phase 6.
        return tasks
    }

    /// Allocate ranked tasks into available free intervals for a day.
    func plan(
        tasks: [Task],
        freeBlocks: [AvailabilityInterval],
        now: Date
    ) -> [PlannerSuggestion] {
        // TODO: implement greedy allocation in Phase 6.
        return []
    }
}
