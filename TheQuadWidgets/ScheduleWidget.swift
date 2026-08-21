import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct ScheduleEntry: TimelineEntry {
    let date: Date
    let data: WidgetScheduleData?
}

// MARK: - Timeline Provider

struct ScheduleProvider: TimelineProvider {
    func placeholder(in context: Context) -> ScheduleEntry {
        ScheduleEntry(date: Date(), data: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
        completion(ScheduleEntry(date: Date(), data: WidgetDataStore.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ScheduleEntry>) -> Void) {
        let now = Date()
        let data = WidgetDataStore.read()
        let entry = ScheduleEntry(date: now, data: data)
        // Refresh every 5 minutes
        let next = Calendar.current.date(byAdding: .minute, value: 5, to: now) ?? now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Widget View

struct ScheduleWidgetView: View {
    let entry: ScheduleEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Color.black
            if let data = entry.data {
                filledView(data: data)
            } else {
                placeholderView
            }
        }
    }

    private func filledView(data: WidgetScheduleData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(data.dayBadge)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))
            if let name = data.currentCourseName {
                Text("NOW")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.indigo)
                Text(name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                if let room = data.currentCourseRoom {
                    Text(room)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                if let end = data.currentEndTime {
                    Text("Until \(end.formatted(.dateTime.hour().minute()))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            } else if let next = data.nextCourseName {
                Text("NEXT")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.5))
                Text(next)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                if let start = data.nextStartTime {
                    Text(start.formatted(.dateTime.hour().minute()))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            } else {
                Text("Free")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                Text("No more classes today")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var placeholderView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("The Quad")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.4))
            Text("Open app to load schedule")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Widget

struct ScheduleWidget: Widget {
    let kind = "ScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ScheduleProvider()) { entry in
            ScheduleWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Current Class")
        .description("See your current or next class at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
