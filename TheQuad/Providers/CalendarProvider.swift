import Foundation

/// Source of the school calendar: date→DayType mappings, bell schedules, and
/// admin overrides. The AdminCalendarSource concrete impl is authoritative.
protocol CalendarProvider {
    var provenance: DataProvenance { get }

    /// Calendar dates (date→DayType) for a school year.
    func loadCalendarDates(schoolYear: String) async throws -> [SchoolCalendarDate]

    /// The bell schedule templates (one per day type / special day).
    func loadBellSchedules(schoolYear: String) async throws -> [BellSchedule]

    /// Admin overrides that trump the generated rotation.
    func loadOverrides(schoolYear: String) async throws -> [ScheduleOverride]
}
