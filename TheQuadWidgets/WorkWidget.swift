import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct WorkWidgetEntry: TimelineEntry {
    let date: Date
    let dueToday: Int
    let dayBadge: String
}

// MARK: - Timeline Provider

struct WorkWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WorkWidgetEntry {
        WorkWidgetEntry(date: Date(), dueToday: 2, dayBadge: "Day 3")
    }

    func getSnapshot(in context: Context, completion: @escaping (WorkWidgetEntry) -> Void) {
        let data = WidgetDataStore.read()
        completion(WorkWidgetEntry(
            date: Date(),
            dueToday: data?.assignmentsDueToday ?? 0,
            dayBadge: data?.dayBadge ?? "—"
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WorkWidgetEntry>) -> Void) {
        let data = WidgetDataStore.read()
        let entry = WorkWidgetEntry(
            date: Date(),
            dueToday: data?.assignmentsDueToday ?? 0,
            dayBadge: data?.dayBadge ?? "—"
        )
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Widget View

struct WorkWidgetView: View {
    let entry: WorkWidgetEntry

    var body: some View {
        ZStack {
            Color.black
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.dayBadge)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text("\(entry.dueToday)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.dueToday > 0 ? Color.indigo : Color.white.opacity(0.4))
                Text("due today")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .containerBackground(.black, for: .widget)
    }
}

// MARK: - Widget

struct WorkWidget: Widget {
    let kind = "WorkWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorkWidgetProvider()) { entry in
            WorkWidgetView(entry: entry)
        }
        .configurationDisplayName("Work Due Today")
        .description("See how many assignments are due today.")
        .supportedFamilies([.systemSmall])
    }
}
