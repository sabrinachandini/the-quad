import Foundation

/// reference_2025_26
///
/// Reference LHS bell schedules and calendar dates for the 2025-26 year.
/// These values are REFERENCE ONLY — not authoritative. Confirm with admin
/// before treating any time as ground truth. See docs/LHS_SCHEDULE_MODEL.md.
enum LHSFixtures_2025_26 {

    // MARK: - Slot times (reference_2025_26)
    // 55-min periods, 5-min passing, ~30-min embedded lunch. School ~7:55–2:20.
    private static func hm(_ h: Int, _ m: Int) -> DateComponents {
        DateComponents(hour: h, minute: m)
    }

    // Standard period start/end times, indexed by "period position" 1...6 plus lunch.
    private struct Period {
        let start: DateComponents
        let end: DateComponents
    }
    private static let p1 = Period(start: hm(7, 55), end: hm(8, 50))
    private static let p2 = Period(start: hm(8, 55), end: hm(9, 50))
    private static let p3 = Period(start: hm(9, 55), end: hm(10, 50))
    private static let lunch = Period(start: hm(10, 55), end: hm(11, 25))
    private static let p4 = Period(start: hm(11, 30), end: hm(12, 25))
    private static let p5 = Period(start: hm(12, 30), end: hm(13, 25))
    private static let p6 = Period(start: hm(13, 30), end: hm(14, 20))

    private static let standardPeriods: [Period] = [p1, p2, p3, p4, p5, p6]

    // MARK: - Rotating block order by day (reference_2025_26)
    // The block letter identifies the COURSE; its slot depends on the Day.
    static let blockOrder: [DayType: [AcademicBlock]] = [
        .day1: [.a, .b, .c, .d, .e, .f],
        .day2: [.b, .c, .d, .e, .f, .a],
        .day3: [.c, .d, .e, .f, .a, .b],
        .day4: [.d, .e, .f, .a, .b, .c],
        .day5: [.e, .f, .a, .b, .c, .d],
        .day6: [.f, .a, .b, .c, .d, .e]
    ]

    // MARK: - Bell schedules

    /// A standard rotation day's bell schedule for the given day type.
    /// Six academic blocks with an embedded lunch after the third block.
    private static func standardSchedule(for dayType: DayType) -> BellSchedule {
        guard let blocks = blockOrder[dayType] else {
            return BellSchedule(id: UUID(), name: "\(dayType.rawValue)", dayType: dayType, slots: [])
        }
        var slots: [MeetingSlot] = []
        var order = 0
        for (index, block) in blocks.enumerated() {
            let period = standardPeriods[index]
            slots.append(MeetingSlot(
                id: UUID(), order: order, block: block,
                startTime: period.start, endTime: period.end, isLunch: false
            ))
            order += 1
            // Embed lunch after the third academic block.
            if index == 2 {
                slots.append(MeetingSlot(
                    id: UUID(), order: order, block: .flex, // lunch/flex placeholder block
                    startTime: lunch.start, endTime: lunch.end, isLunch: true
                ))
                order += 1
            }
        }
        let dayNumber = (dayType.rotationIndex ?? 0) + 1
        return BellSchedule(id: UUID(), name: "Day \(dayNumber)", dayType: dayType, slots: slots)
    }

    static let day1Schedule = standardSchedule(for: .day1)
    static let day2Schedule = standardSchedule(for: .day2)
    static let day3Schedule = standardSchedule(for: .day3)
    static let day4Schedule = standardSchedule(for: .day4)
    static let day5Schedule = standardSchedule(for: .day5)
    static let day6Schedule = standardSchedule(for: .day6)

    /// Half-day schedule (reference_2025_26). Explicit template — NOT the full
    /// day halved. Shortened periods ending by ~11:30. Uses Day 1 block order.
    static let halfDaySchedule: BellSchedule = {
        let blocks = blockOrder[.day1] ?? []
        let shortPeriods: [Period] = [
            Period(start: hm(7, 55), end: hm(8, 30)),
            Period(start: hm(8, 35), end: hm(9, 10)),
            Period(start: hm(9, 15), end: hm(9, 50)),
            Period(start: hm(9, 55), end: hm(10, 30)),
            Period(start: hm(10, 35), end: hm(11, 5)),
            Period(start: hm(11, 10), end: hm(11, 30))
        ]
        var slots: [MeetingSlot] = []
        for (index, block) in blocks.enumerated() {
            let p = shortPeriods[index]
            slots.append(MeetingSlot(
                id: UUID(), order: index, block: block,
                startTime: p.start, endTime: p.end, isLunch: false
            ))
        }
        return BellSchedule(id: UUID(), name: "Half Day", dayType: .halfDay, slots: slots)
    }()

    /// Delayed opening schedule (reference_2025_26).
    /// School starts 9:55 AM. Six ~45-min academic blocks with a short lunch.
    static let delayedOpeningSchedule: BellSchedule = {
        let blocks = blockOrder[.day1] ?? []
        let delayedPeriods: [Period] = [
            Period(start: hm(9, 55), end: hm(10, 35)),
            Period(start: hm(10, 40), end: hm(11, 20)),
            Period(start: hm(11, 25), end: hm(12, 5)),
            Period(start: hm(12, 35), end: hm(13, 15)),
            Period(start: hm(13, 20), end: hm(14, 0)),
            Period(start: hm(14, 5), end: hm(14, 20))
        ]
        let delayedLunch = Period(start: hm(12, 5), end: hm(12, 30))
        var slots: [MeetingSlot] = []
        var order = 0
        for (index, block) in blocks.enumerated() {
            let p = delayedPeriods[index]
            slots.append(MeetingSlot(
                id: UUID(), order: order, block: block,
                startTime: p.start, endTime: p.end, isLunch: false
            ))
            order += 1
            // Embed lunch after the third block (same pattern as standard).
            if index == 2 {
                slots.append(MeetingSlot(
                    id: UUID(), order: order, block: .flex,
                    startTime: delayedLunch.start, endTime: delayedLunch.end, isLunch: true
                ))
                order += 1
            }
        }
        return BellSchedule(id: UUID(), name: "Delayed Opening", dayType: .delayedOpening, slots: slots)
    }()

    /// Assembly schedule (reference_2025_26).
    /// Periods are shortened to ~45 min to fit a 30-min assembly block.
    /// Only 5 academic blocks on assembly days; assembly slot after period 2.
    static let assemblySchedule: BellSchedule = {
        let blocks = blockOrder[.day1] ?? []
        // Five academic periods around the assembly slot.
        let assemblyPeriods: [Period] = [
            Period(start: hm(7, 55), end: hm(8, 40)),
            Period(start: hm(8, 45), end: hm(9, 30)),
            // Assembly: 9:35–10:05
            Period(start: hm(10, 10), end: hm(10, 55)),
            Period(start: hm(11, 35), end: hm(12, 20)),
            Period(start: hm(12, 25), end: hm(13, 10))
        ]
        let assemblyLunch = Period(start: hm(11, 0), end: hm(11, 30))
        // Use first 5 blocks from Day 1 order.
        let usedBlocks = Array(blocks.prefix(5))
        var slots: [MeetingSlot] = []
        var order = 0
        for (index, block) in usedBlocks.enumerated() {
            let p = assemblyPeriods[index]
            slots.append(MeetingSlot(
                id: UUID(), order: order, block: block,
                startTime: p.start, endTime: p.end, isLunch: false
            ))
            order += 1
            // Embed lunch after the third academic block (index 2).
            if index == 2 {
                slots.append(MeetingSlot(
                    id: UUID(), order: order, block: .flex,
                    startTime: assemblyLunch.start, endTime: assemblyLunch.end, isLunch: true
                ))
                order += 1
            }
        }
        return BellSchedule(id: UUID(), name: "Assembly", dayType: .assembly, slots: slots)
    }()

    /// All bell schedules the engine should be seeded with.
    static let allBellSchedules: [BellSchedule] = [
        day1Schedule, day2Schedule, day3Schedule,
        day4Schedule, day5Schedule, day6Schedule,
        halfDaySchedule, delayedOpeningSchedule, assemblySchedule
    ]

    // MARK: - Full 2025-26 calendar (reference_2025_26)

    /// Generates school calendar dates from Sept 2, 2025 through June 12, 2026.
    /// Weekends are skipped. Holidays are marked .noSchool. All other days
    /// advance through the Day 1–6 rotation in sequence.
    private static func generateCalendarDates() -> [SchoolCalendarDate] {
        let cal = Calendar.current

        // Holidays and no-school dates (year, month, day).
        let holidays: Set<String> = [
            "2025-09-01", // Labor Day
            "2025-10-13", // Columbus/Indigenous Peoples Day
            "2025-11-11", // Veterans Day
            "2025-11-26", // Day before Thanksgiving (LHS off)
            "2025-11-27", // Thanksgiving Day
            "2025-11-28", // Day after Thanksgiving
            // Winter break: Dec 24 – Jan 2
            "2025-12-24", "2025-12-25", "2025-12-26", "2025-12-27", "2025-12-28",
            "2025-12-29", "2025-12-30", "2025-12-31",
            "2026-01-01", "2026-01-02",
            "2026-01-19", // MLK Day
            // February break: Feb 16–20
            "2026-02-16", "2026-02-17", "2026-02-18", "2026-02-19", "2026-02-20",
            // April break: Apr 20–24
            "2026-04-20", "2026-04-21", "2026-04-22", "2026-04-23", "2026-04-24",
            "2026-05-25"  // Memorial Day
        ]

        let rotationDays: [DayType] = [.day1, .day2, .day3, .day4, .day5, .day6]

        var results: [SchoolCalendarDate] = []
        var rotationIndex = 0

        // Start: September 2, 2025 (Day 1). End: June 12, 2026.
        guard
            let startDate = cal.date(from: DateComponents(year: 2025, month: 9, day: 2)),
            let endDate   = cal.date(from: DateComponents(year: 2026, month: 6, day: 12))
        else { return [] }

        var current = startDate
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        while current <= endDate {
            let weekday = cal.component(.weekday, from: current) // 1=Sun, 7=Sat
            let key = formatter.string(from: current)

            // Skip weekends entirely (no entry generated).
            if weekday == 1 || weekday == 7 {
                current = cal.date(byAdding: .day, value: 1, to: current) ?? current
                continue
            }

            let dayType: DayType
            let note: String?

            if holidays.contains(key) {
                dayType = .noSchool
                note = nil
            } else {
                dayType = rotationDays[rotationIndex % 6]
                rotationIndex += 1
                note = nil
            }

            results.append(SchoolCalendarDate(
                id: UUID(),
                date: current,
                dayType: dayType,
                bellScheduleOverride: nil,
                note: note,
                isVerified: true
            ))

            current = cal.date(byAdding: .day, value: 1, to: current) ?? current
        }

        return results
    }

    /// Full 2025-26 school year calendar: Sept 2, 2025 – June 12, 2026.
    static let calendarDates_2025_26: [SchoolCalendarDate] = generateCalendarDates()
}
