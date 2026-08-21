import Foundation

enum DayType: String, Codable {
    case day1, day2, day3, day4, day5, day6
    case noSchool, halfDay, delayedOpening, assembly, examSchedule, special

    var isSchoolDay: Bool {
        switch self {
        case .day1, .day2, .day3, .day4, .day5, .day6,
             .halfDay, .delayedOpening, .assembly, .examSchedule, .special:
            return true
        case .noSchool:
            return false
        }
    }

    var rotationIndex: Int? {
        switch self {
        case .day1: return 0
        case .day2: return 1
        case .day3: return 2
        case .day4: return 3
        case .day5: return 4
        case .day6: return 5
        default: return nil
        }
    }
}

enum AcademicBlock: String, Codable, CaseIterable {
    case a = "A", b = "B", c = "C", d = "D", e = "E"
    case f = "F", g = "G", h = "H", i = "I"
    case homeroom = "Homeroom", flex = "Flex"
}

struct MeetingSlot: Identifiable, Codable {
    let id: UUID
    let order: Int
    let block: AcademicBlock
    let startTime: DateComponents  // hour + minute only
    let endTime: DateComponents
    var isLunch: Bool = false
}

struct BellSchedule: Identifiable, Codable {
    let id: UUID
    let name: String
    let dayType: DayType
    let slots: [MeetingSlot]  // ordered by slot.order
}

struct SchoolCalendarDate: Identifiable, Codable {
    let id: UUID
    let date: Date
    var dayType: DayType
    var bellScheduleOverride: BellSchedule?
    var note: String?
    var isVerified: Bool  // false = needs_verification (e.g. 2026-27 placeholders)
}

struct ScheduleOverride: Identifiable, Codable {
    let id: UUID
    let date: Date
    let overrideDayType: DayType
    let overrideBellSchedule: BellSchedule?
    let reason: String
    let setBy: String
    let setAt: Date
}
