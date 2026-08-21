import Foundation

/// reference_2025_26
///
/// Reference LHS bell schedules and sample calendar dates for the 2025-26 year.
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

    /// All bell schedules the engine should be seeded with.
    static let allBellSchedules: [BellSchedule] = [
        day1Schedule, day2Schedule, day3Schedule,
        day4Schedule, day5Schedule, day6Schedule,
        halfDaySchedule
    ]

    // MARK: - Sample calendar dates (reference_2025_26, September 2025)

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    /// A small sample of September 2025 calendar entries mapping dates to day types.
    /// reference_2025_26 — verified against the reference calendar for dev use.
    static let sampleCalendarDates: [SchoolCalendarDate] = [
        SchoolCalendarDate(id: UUID(), date: date(2025, 9, 2), dayType: .day1, bellScheduleOverride: nil, note: "First day", isVerified: true),
        SchoolCalendarDate(id: UUID(), date: date(2025, 9, 3), dayType: .day2, bellScheduleOverride: nil, note: nil, isVerified: true),
        SchoolCalendarDate(id: UUID(), date: date(2025, 9, 4), dayType: .day3, bellScheduleOverride: nil, note: nil, isVerified: true),
        SchoolCalendarDate(id: UUID(), date: date(2025, 9, 5), dayType: .day4, bellScheduleOverride: nil, note: nil, isVerified: true),
        SchoolCalendarDate(id: UUID(), date: date(2025, 9, 8), dayType: .day5, bellScheduleOverride: nil, note: nil, isVerified: true),
        SchoolCalendarDate(id: UUID(), date: date(2025, 9, 9), dayType: .day6, bellScheduleOverride: nil, note: nil, isVerified: true),
        SchoolCalendarDate(id: UUID(), date: date(2025, 9, 10), dayType: .day1, bellScheduleOverride: nil, note: "Rotation wraps", isVerified: true),
        SchoolCalendarDate(id: UUID(), date: date(2025, 9, 11), dayType: .day2, bellScheduleOverride: nil, note: nil, isVerified: true),
        SchoolCalendarDate(id: UUID(), date: date(2025, 9, 12), dayType: .halfDay, bellScheduleOverride: nil, note: "Half day", isVerified: true)
    ]
}
