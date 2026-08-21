import Foundation
import WidgetKit

/// Data written by the main app and read by the widget extension.
/// Uses a local file in the app's documents directory as a bridge.
/// When an AppGroup is configured, update `fileURL` to use the shared container.
struct WidgetScheduleData: Codable {
    var currentCourseName: String?
    var currentCourseRoom: String?
    var currentEndTime: Date?
    var nextCourseName: String?
    var nextCourseRoom: String?
    var nextStartTime: Date?
    var dayBadge: String         // e.g. "Day 3" or "No School"
    var todayDateLabel: String   // e.g. "Thursday"
    var assignmentsDueToday: Int
    var updatedAt: Date
}

struct WidgetDataStore {
    static let filename = "widget_data.json"

    static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
    }

    static func write(_ data: WidgetScheduleData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        try? encoded.write(to: fileURL)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func read() -> WidgetScheduleData? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(WidgetScheduleData.self, from: data)
    }
}
