import Foundation

/// Computes free blocks (AvailabilityInterval) and free-block overlap between
/// students. Free blocks are ALWAYS derived — bell schedule minus enrolled
/// courses. Never stored as source of truth. See docs/DATA_MODEL.md.
struct FreeBlockEngine {

    private let calendar = Calendar.current

    /// Free blocks for a student on a date: every non-lunch meeting slot that is
    /// NOT covered by one of the student's sessions becomes free time. Adjacent
    /// free slots are merged into a single interval.
    func freeBlocks(
        for date: Date,
        studentId: UUID,
        allSlots: [MeetingSlot],
        studentSessions: [CourseSession]
    ) -> [AvailabilityInterval] {
        // Slots occupied by the student's courses (by slot id).
        let occupiedSlotIDs = Set(studentSessions.map { $0.slot.id })

        // Candidate free slots: non-lunch slots the student is not in, ordered.
        let freeSlots = allSlots
            .filter { !$0.isLunch && !occupiedSlotIDs.contains($0.id) }
            .sorted { $0.order < $1.order }

        // Build intervals, merging consecutive slots.
        var intervals: [AvailabilityInterval] = []
        var runStart: (slot: MeetingSlot, block: AcademicBlock)?
        var runEndSlot: MeetingSlot?
        var lastOrder: Int?

        func flush() {
            guard let start = runStart, let end = runEndSlot else { return }
            let label = start.slot.block == end.block
                ? "Free (\(start.block.rawValue) block)"
                : "Free"
            intervals.append(makeInterval(
                studentId: studentId, date: date,
                startSlot: start.slot, endSlot: end, label: label
            ))
            runStart = nil; runEndSlot = nil
        }

        for slot in freeSlots {
            if let last = lastOrder, slot.order == last + 1 {
                // consecutive — extend the run
                runEndSlot = slot
            } else {
                // gap — close previous run, start a new one
                flush()
                runStart = (slot, slot.block)
                runEndSlot = slot
            }
            lastOrder = slot.order
        }
        flush()
        return intervals
    }

    /// The intersection of two students' free intervals: overlapping windows
    /// where both are free. Requires the intervals to be on the same date.
    func sharedFreeBlocks(
        studentA: [AvailabilityInterval],
        studentB: [AvailabilityInterval]
    ) -> [AvailabilityInterval] {
        var shared: [AvailabilityInterval] = []
        for a in studentA {
            for b in studentB where calendar.isDate(a.date, inSameDayAs: b.date) {
                let start = max(a.start, b.start)
                let end = min(a.end, b.end)
                guard start < end else { continue }
                shared.append(AvailabilityInterval(
                    id: UUID(),
                    studentID: a.studentID,
                    date: a.date,
                    start: start,
                    end: end,
                    label: "Both free"
                ))
            }
        }
        return shared.sorted { $0.start < $1.start }
    }

    // MARK: - Helpers

    private func makeInterval(
        studentId: UUID, date: Date,
        startSlot: MeetingSlot, endSlot: MeetingSlot, label: String
    ) -> AvailabilityInterval {
        AvailabilityInterval(
            id: UUID(),
            studentID: studentId,
            date: date,
            start: dateTime(on: date, comps: startSlot.startTime),
            end: dateTime(on: date, comps: endSlot.endTime),
            label: label
        )
    }

    private func dateTime(on date: Date, comps: DateComponents) -> Date {
        var c = calendar.dateComponents([.year, .month, .day], from: date)
        c.hour = comps.hour
        c.minute = comps.minute
        return calendar.date(from: c) ?? date
    }
}
