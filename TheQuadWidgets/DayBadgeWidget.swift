import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct DayBadgeEntry: TimelineEntry {
    let date: Date
    let dayBadge: String
    let dateLabel: String
}

// MARK: - Timeline Provider

struct DayBadgeProvider: TimelineProvider {
    func placeholder(in context: Context) -> DayBadgeEntry {
        DayBadgeEntry(date: Date(), dayBadge: "Day 3", dateLabel: "Thursday")
    }

    func getSnapshot(in context: Context, completion: @escaping (DayBadgeEntry) -> Void) {
        let data = WidgetDataStore.read()
        completion(DayBadgeEntry(
            date: Date(),
            dayBadge: data?.dayBadge ?? "—",
            dateLabel: data?.todayDateLabel ?? Date().formatted(.dateTime.weekday(.wide))
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DayBadgeEntry>) -> Void) {
        let data = WidgetDataStore.read()
        let entry = DayBadgeEntry(
            date: Date(),
            dayBadge: data?.dayBadge ?? "—",
            dateLabel: data?.todayDateLabel ?? Date().formatted(.dateTime.weekday(.wide))
        )
        // Refresh at start of next day
        let cal = Calendar.current
        let tomorrow = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        completion(Timeline(entries: [entry], policy: .after(tomorrow)))
    }
}

// MARK: - Widget View

struct DayBadgeWidgetView: View {
    let entry: DayBadgeEntry

    var body: some View {
        ZStack {
            Color.black
            VStack(spacing: 2) {
                Text(entry.dayBadge)
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                Text(entry.dateLabel)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .containerBackground(.black, for: .widget)
    }
}

// MARK: - Widget

struct DayBadgeWidget: Widget {
    let kind = "DayBadgeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DayBadgeProvider()) { entry in
            DayBadgeWidgetView(entry: entry)
        }
        .configurationDisplayName("Day Badge")
        .description("Shows your current rotation day at a glance.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}
