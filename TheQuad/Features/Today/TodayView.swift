import SwiftUI

struct TodayView: View {
    @State private var model: TodayViewModel

    init(model: TodayViewModel = TodayViewModel()) {
        _model = State(initialValue: model)
    }

    private func timeString(_ comps: DateComponents) -> String {
        var c = DateComponents()
        c.hour = comps.hour; c.minute = comps.minute
        let date = Calendar.current.date(from: c) ?? Date()
        return date.formatted(.dateTime.hour().minute())
    }

    private func durationBetween(_ start: DateComponents, _ end: DateComponents) -> Int {
        let startMins = (start.hour ?? 0) * 60 + (start.minute ?? 0)
        let endMins = (end.hour ?? 0) * 60 + (end.minute ?? 0)
        return max(0, endMins - startMins)
    }

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                    header
                    if let current = model.currentSession {
                        currentCard(current)
                    }
                    if let next = model.nextSession {
                        nextCard(next)
                    }
                    fullDay
                    tomorrowSection
                }
                .padding(DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.xxxl)
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Today")
                    .font(DesignTokens.Typography.quadTitle)
                    .foregroundStyle(DesignTokens.Colors.primary)
                Text(model.todayLabel)
                    .font(DesignTokens.Typography.quadBody)
                    .foregroundStyle(DesignTokens.Colors.secondary)
            }
            Spacer()
            Text(model.dayBadge)
                .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(model.isSchoolDay ? DesignTokens.Colors.accent : DesignTokens.Colors.secondary)
                .clipShape(Capsule())
        }
    }

    // MARK: - Current class (prominent)
    private func currentCard(_ session: CourseSession) -> some View {
        let color = CourseColors.color(atIndex: session.course.colorIndex)
        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("NOW")
                .font(DesignTokens.Typography.quadCaption.weight(.bold))
                .foregroundStyle(color)
            Text(session.course.name)
                .font(DesignTokens.Typography.quadTitle)
                .foregroundStyle(DesignTokens.Colors.primary)
            HStack(spacing: DesignTokens.Spacing.md) {
                Label(session.course.room ?? "—", systemImage: "mappin.and.ellipse")
                if let t = session.course.teacher {
                    Label(t, systemImage: "person")
                }
            }
            .font(DesignTokens.Typography.quadBody)
            .foregroundStyle(DesignTokens.Colors.secondary)
            if let remaining = model.timeRemainingInCurrentSession {
                Text(remaining)
                    .font(DesignTokens.Typography.quadHeadline.weight(.semibold))
                    .foregroundStyle(color)
                    .padding(.top, DesignTokens.Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.xl)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.extraLarge))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.extraLarge)
                .stroke(color, lineWidth: 2)
        )
        .shadow(color: color.opacity(0.35), radius: 12)
    }

    // MARK: - Next class (smaller)
    private func nextCard(_ session: CourseSession) -> some View {
        let color = CourseColors.color(atIndex: session.course.colorIndex)
        return HStack(spacing: DesignTokens.Spacing.md) {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                .fill(color)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("NEXT")
                    .font(DesignTokens.Typography.quadCaption.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.secondary)
                Text(session.course.name)
                    .font(DesignTokens.Typography.quadHeadline)
                    .foregroundStyle(DesignTokens.Colors.primary)
                Text("\(timeString(session.slot.startTime)) · \(session.course.room ?? "—")")
                    .font(DesignTokens.Typography.quadCaption)
                    .foregroundStyle(DesignTokens.Colors.secondary)
            }
            Spacer()
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
    }

    // MARK: - Full day list
    @ViewBuilder
    private var fullDay: some View {
        if model.allSlots.isEmpty {
            VStack(alignment: .center, spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "sun.max")
                    .font(.system(size: 32))
                    .foregroundStyle(DesignTokens.Colors.secondary)
                if let next = model.nextSession {
                    Text("Next up: \(next.course.name)")
                        .font(DesignTokens.Typography.quadBody.weight(.medium))
                        .foregroundStyle(DesignTokens.Colors.primary)
                    Text(next.startDateTime.formatted(.dateTime.weekday(.wide).month().day().hour().minute()))
                        .font(DesignTokens.Typography.quadCaption)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                } else if let schoolDay = model.nextCalendarSchoolDay {
                    Text("School starts \(schoolDay.date.formatted(.dateTime.weekday(.wide).month().day()))")
                        .font(DesignTokens.Typography.quadBody.weight(.medium))
                        .foregroundStyle(DesignTokens.Colors.primary)
                    if schoolDay.isVerified == false {
                        Text("Provisional — check lps.org for updates")
                            .font(DesignTokens.Typography.quadCaption)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                    }
                } else {
                    Text("No upcoming classes")
                        .font(DesignTokens.Typography.quadBody)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(DesignTokens.Spacing.xl)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
        } else {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Full Day")
                    .font(DesignTokens.Typography.quadHeadline)
                    .foregroundStyle(DesignTokens.Colors.primary)
                ForEach(model.allSlots) { slot in
                    slotRow(slot)
                }
            }
        }
    }

    @ViewBuilder
    private func slotRow(_ slot: MeetingSlot) -> some View {
        let time = "\(timeString(slot.startTime))–\(timeString(slot.endTime))"
        if slot.isLunch {
            row(time: time, title: "Lunch", subtitle: nil, color: DesignTokens.Colors.secondary, isFree: false)
        } else if let course = model.course(for: slot) {
            let color = CourseColors.color(atIndex: course.colorIndex)
            row(time: time, title: course.name, subtitle: course.room, color: color, isFree: false)
        } else {
            // Free block — only show friend overlap for the NEXT upcoming free block.
            let freeSoon = model.friendsFreeSoon(forSlot: slot)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(time)
                        .font(DesignTokens.Typography.quadCaption)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                        .frame(width: 110, alignment: .leading)
                    Text("FREE")
                        .font(DesignTokens.Typography.quadBody.weight(.semibold))
                        .foregroundStyle(DesignTokens.Colors.accent)
                    Spacer()
                    let mins = durationBetween(slot.startTime, slot.endTime)
                    if mins > 0 {
                        Text("· \(mins) min")
                            .font(DesignTokens.Typography.quadCaption)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                    }
                }
                if !freeSoon.isEmpty {
                    let names = freeSoon.map { $0.friend.displayName }.formatted(.list(type: .and))
                    HStack {
                        Spacer().frame(width: 110)
                        Text("\(names) also free")
                            .font(DesignTokens.Typography.quadCaption)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                        Spacer()
                    }
                }
            }
            .padding(.vertical, DesignTokens.Spacing.md)
        }
    }

    private func row(time: String, title: String, subtitle: String?, color: Color, isFree: Bool) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Text(time)
                .font(DesignTokens.Typography.quadCaption)
                .foregroundStyle(DesignTokens.Colors.secondary)
                .frame(width: 110, alignment: .leading)
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 4, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignTokens.Typography.quadBody.weight(.medium))
                    .foregroundStyle(DesignTokens.Colors.primary)
                if let subtitle { Text(subtitle).font(DesignTokens.Typography.quadCaption).foregroundStyle(DesignTokens.Colors.secondary) }
            }
            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
    }

    // MARK: - Tomorrow section

    private var tomorrowSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Tomorrow · \(model.tomorrowLabel)")
                .font(DesignTokens.Typography.quadHeadline.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.primary)
            if model.tomorrowSessions.isEmpty {
                Text("No school tomorrow")
                    .font(DesignTokens.Typography.quadBody)
                    .foregroundStyle(DesignTokens.Colors.secondary)
                    .opacity(0.8)
            } else {
                ForEach(model.tomorrowSessions) { session in
                    tomorrowRow(session)
                }
            }
        }
    }

    private func tomorrowRow(_ session: CourseSession) -> some View {
        let color = CourseColors.color(atIndex: session.course.colorIndex)
        return HStack(spacing: DesignTokens.Spacing.md) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 3, height: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.course.name)
                    .font(DesignTokens.Typography.quadBody.weight(.medium))
                    .foregroundStyle(DesignTokens.Colors.primary)
                if let room = session.course.room {
                    Text(room)
                        .font(DesignTokens.Typography.quadCaption)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                }
            }
            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
        .opacity(0.8)
    }
}

#Preview {
    TodayView(model: TodayViewModel(previewDate: Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 4, hour: 10, minute: 20))!))
        .preferredColorScheme(.dark)
}
