import SwiftUI

// MARK: - Time formatting helpers (shared)

private func formatSlotTime(_ comps: DateComponents) -> String {
    var c = DateComponents()
    c.hour = comps.hour
    c.minute = comps.minute
    let date = Calendar.current.date(from: c) ?? Date()
    return date.formatted(.dateTime.hour().minute())
}

private func slotTimeRange(_ slot: MeetingSlot) -> String {
    "\(formatSlotTime(slot.startTime))–\(formatSlotTime(slot.endTime))"
}

private func slotStartTime(_ slot: MeetingSlot) -> String {
    formatSlotTime(slot.startTime)
}

// MARK: - Schedule Row (extracted to avoid @ViewBuilder imperative-let restriction)

private struct ScheduleRowView: View {
    let slot: MeetingSlot
    let model: TodayViewModel

    private var courseName: String {
        if slot.isLunch { return "Lunch" }
        if let course = model.course(for: slot) { return course.name }
        return "Free"
    }

    private var rowColor: Color {
        if slot.isLunch { return DesignTokens.Colors.secondary }
        if let course = model.course(for: slot) { return CourseColors.color(atIndex: course.colorIndex) }
        return DesignTokens.Colors.accent
    }

    private var isCurrent: Bool {
        guard !slot.isLunch, model.course(for: slot) != nil else { return false }
        return model.currentSession?.slot.id == slot.id
    }

    private var isPast: Bool {
        let minutesNow = Calendar.current.component(.hour, from: model.now) * 60
            + Calendar.current.component(.minute, from: model.now)
        let slotEnd = (slot.endTime.hour ?? 0) * 60 + (slot.endTime.minute ?? 0)
        if isCurrent { return false }
        return slotEnd <= minutesNow
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Colored dot
            Circle()
                .fill(isCurrent ? rowColor : (isPast ? rowColor.opacity(0.25) : rowColor.opacity(0.5)))
                .frame(width: 8, height: 8)

            // Block letter (dimmed)
            Text(slot.block.rawValue)
                .font(DesignTokens.Typography.quadCaption)
                .foregroundStyle(DesignTokens.Colors.secondary.opacity(0.45))
                .frame(width: 14, alignment: .leading)

            // Course / block name
            Text(courseName)
                .font(isCurrent
                    ? DesignTokens.Typography.quadBody.weight(.semibold)
                    : DesignTokens.Typography.quadBody)
                .foregroundStyle(
                    isCurrent ? rowColor
                    : isPast ? DesignTokens.Colors.primary.opacity(0.35)
                    : DesignTokens.Colors.primary
                )
                .lineLimit(1)

            Spacer()

            // Right-side status
            statusLabel
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, 11)
    }

    @ViewBuilder
    private var statusLabel: some View {
        let status = model.slotStatus(for: slot)
        switch status {
        case .current:
            HStack(spacing: 3) {
                Text("NOW")
                    .font(DesignTokens.Typography.quadCaption.weight(.bold))
                Text("·")
                Text("\(model.minutesRemainingInCurrent)m")
                    .font(DesignTokens.Typography.quadCaption)
            }
            .foregroundStyle(rowColor)
        case .past:
            Image(systemName: "checkmark")
                .font(DesignTokens.Typography.quadCaption)
                .foregroundStyle(DesignTokens.Colors.secondary.opacity(0.35))
        case .free:
            Text(slotTimeRange(slot))
                .font(DesignTokens.Typography.quadCaption)
                .foregroundStyle(DesignTokens.Colors.secondary.opacity(0.55))
        case .future:
            Text(slotStartTime(slot))
                .font(DesignTokens.Typography.quadCaption)
                .foregroundStyle(DesignTokens.Colors.secondary.opacity(0.55))
        case .lunch:
            if isPast {
                Image(systemName: "checkmark")
                    .font(DesignTokens.Typography.quadCaption)
                    .foregroundStyle(DesignTokens.Colors.secondary.opacity(0.35))
            } else {
                Text(slotStartTime(slot))
                    .font(DesignTokens.Typography.quadCaption)
                    .foregroundStyle(DesignTokens.Colors.secondary.opacity(0.55))
            }
        }
    }
}

// MARK: - TodayView

struct TodayView: View {
    @State private var model: TodayViewModel

    init(model: TodayViewModel = TodayViewModel()) {
        _model = State(initialValue: model)
    }

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                dayHeader
                thinRule
                heroSection
                thinRule
                scheduleStrip
                thinRule
                secondaryScroll
            }
        }
    }

    private var thinRule: some View {
        Rectangle()
            .fill(DesignTokens.Colors.secondary.opacity(0.15))
            .frame(height: 0.5)
    }

    // MARK: - Day Header

    private var dayHeader: some View {
        HStack(alignment: .center) {
            HStack(spacing: 6) {
                Text(model.weekdayUppercase)
                    .font(DesignTokens.Typography.quadLabel)
                    .foregroundStyle(DesignTokens.Colors.secondary)
                Text("·")
                    .font(DesignTokens.Typography.quadLabel)
                    .foregroundStyle(DesignTokens.Colors.secondary)
                Text(model.dayNumberLabel)
                    .font(DesignTokens.Typography.quadLabel)
                    .foregroundStyle(DesignTokens.Colors.primary)
            }
            Spacer()
            Text(model.shortDateLabel)
                .font(DesignTokens.Typography.quadLabel)
                .foregroundStyle(DesignTokens.Colors.secondary)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.md)
    }

    // MARK: - Hero Section

    @ViewBuilder
    private var heroSection: some View {
        switch model.todayState {
        case .duringClass:
            if let session = model.currentSession {
                DuringClassHeroView(session: session, model: model)
            } else {
                EmptyView()
            }
        case .freeBlock:
            FreeBlockHeroView(model: model)
        case .beforeSchool:
            BeforeSchoolHeroView(model: model)
        case .afterSchool:
            AfterOrNoSchoolHeroView(title: "AFTER SCHOOL", model: model)
        case .noSchool:
            AfterOrNoSchoolHeroView(title: "NO SCHOOL", model: model)
        }
    }

    // MARK: - Schedule Strip (no scroll)

    private var scheduleStrip: some View {
        VStack(spacing: 0) {
            ForEach(Array(model.allSlots.enumerated()), id: \.element.id) { index, slot in
                ScheduleRowView(slot: slot, model: model)
                if index < model.allSlots.count - 1 {
                    Rectangle()
                        .fill(DesignTokens.Colors.secondary.opacity(0.10))
                        .frame(height: 0.5)
                        .padding(.leading, DesignTokens.Spacing.lg)
                }
            }
        }
    }

    // MARK: - Secondary Content (scrollable)

    private var secondaryScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                tomorrowSection
                    .padding(.top, DesignTokens.Spacing.lg)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.bottom, DesignTokens.Spacing.xxxl)
            }
        }
    }

    // MARK: - Tomorrow Section

    private var tomorrowSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack(spacing: 6) {
                Text("TOMORROW")
                    .font(DesignTokens.Typography.quadLabel)
                    .foregroundStyle(DesignTokens.Colors.secondary)
                Text("·")
                    .font(DesignTokens.Typography.quadLabel)
                    .foregroundStyle(DesignTokens.Colors.secondary)
                Text(model.tomorrowLabel.uppercased())
                    .font(DesignTokens.Typography.quadLabel)
                    .foregroundStyle(DesignTokens.Colors.primary)
            }

            if model.tomorrowSessions.isEmpty {
                Text("No school tomorrow")
                    .font(DesignTokens.Typography.quadBody)
                    .foregroundStyle(DesignTokens.Colors.secondary)
                    .padding(.top, DesignTokens.Spacing.xs)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(model.tomorrowSessions.enumerated()), id: \.element.id) { idx, session in
                        tomorrowRow(session)
                        if idx < model.tomorrowSessions.count - 1 {
                            Rectangle()
                                .fill(DesignTokens.Colors.secondary.opacity(0.10))
                                .frame(height: 0.5)
                                .padding(.leading, 20)
                        }
                    }
                }
            }
        }
    }

    private func tomorrowRow(_ session: CourseSession) -> some View {
        let color = CourseColors.color(atIndex: session.course.colorIndex)
        return HStack(spacing: DesignTokens.Spacing.md) {
            Circle()
                .fill(color.opacity(0.4))
                .frame(width: 8, height: 8)
            Text(session.course.name)
                .font(DesignTokens.Typography.quadBody)
                .foregroundStyle(DesignTokens.Colors.primary.opacity(0.65))
                .lineLimit(1)
            Spacer()
            if let room = session.course.room {
                Text(room)
                    .font(DesignTokens.Typography.quadCaption)
                    .foregroundStyle(DesignTokens.Colors.secondary.opacity(0.55))
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Hero: During Class

private struct DuringClassHeroView: View {
    let session: CourseSession
    let model: TodayViewModel

    var body: some View {
        let color = CourseColors.color(atIndex: session.course.colorIndex)
        let progress = model.currentSessionProgress
        let mins = model.minutesRemainingInCurrent

        return ZStack(alignment: .bottomLeading) {
            color.opacity(0.08)
            VStack(alignment: .leading, spacing: 0) {
                // Course name — large, expressive, uppercase
                Text(session.course.name.uppercased())
                    .font(.system(size: 28, weight: .black, design: .default))
                    .foregroundStyle(color)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(.bottom, DesignTokens.Spacing.xs)

                // Metadata: room + time range
                HStack(spacing: 6) {
                    if let room = session.course.room {
                        Text("Room \(room)")
                    }
                    Text("·")
                    Text(slotTimeRange(session.slot))
                }
                .font(DesignTokens.Typography.quadCaption)
                .foregroundStyle(DesignTokens.Colors.secondary)
                .padding(.bottom, DesignTokens.Spacing.xl)

                // Countdown — large expressive number
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(mins)")
                        .font(.system(size: 72, weight: .black, design: .default))
                        .foregroundStyle(DesignTokens.Colors.primary)
                        .monospacedDigit()
                    Text("MIN")
                        .font(.system(size: 22, weight: .bold, design: .default))
                        .foregroundStyle(DesignTokens.Colors.secondary)
                        .padding(.bottom, 10)
                }
                .padding(.bottom, DesignTokens.Spacing.md)

                // Progress bar — 2pt rule, fills with remaining time
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(color.opacity(0.15))
                            .frame(height: 2)
                        Rectangle()
                            .fill(color)
                            .frame(width: geo.size.width * (1.0 - progress), height: 2)
                    }
                }
                .frame(height: 2)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.top, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.lg)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Hero: Free Block

private struct FreeBlockHeroView: View {
    let model: TodayViewModel

    var body: some View {
        let mins = model.freeBlockMinutesRemaining
        let friends = model.friendsFreeNow
        let tasks = model.upcomingAssignmentsForFree

        return ZStack(alignment: .topLeading) {
            DesignTokens.Colors.accent

            VStack(alignment: .leading, spacing: 0) {
                Text("FREE")
                    .font(.system(size: 42, weight: .black, design: .default))
                    .foregroundStyle(.white)

                Text("\(mins) MIN")
                    .font(.system(size: 22, weight: .bold, design: .default))
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.bottom, DesignTokens.Spacing.lg)

                HStack(alignment: .top, spacing: DesignTokens.Spacing.xl) {
                    // Friends column
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("ALSO FREE")
                            .font(DesignTokens.Typography.quadLabel)
                            .foregroundStyle(.white.opacity(0.6))
                        if friends.isEmpty {
                            Text("Invite friends to\nsee who's free")
                                .font(DesignTokens.Typography.quadCaption)
                                .foregroundStyle(.white.opacity(0.72))
                                .italic()
                        } else {
                            ForEach(friends.indices, id: \.self) { i in
                                Text(friends[i].friend.displayName)
                                    .font(DesignTokens.Typography.quadBody.weight(.medium))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Tasks column
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("FITS NOW")
                            .font(DesignTokens.Typography.quadLabel)
                            .foregroundStyle(.white.opacity(0.6))
                        if tasks.isEmpty {
                            Text("Nothing short enough")
                                .font(DesignTokens.Typography.quadCaption)
                                .foregroundStyle(.white.opacity(0.72))
                                .italic()
                        } else {
                            ForEach(tasks) { task in
                                HStack(spacing: 4) {
                                    Text(task.title)
                                        .lineLimit(1)
                                    if let est = task.estimatedMinutes {
                                        Text("· \(est)m")
                                            .opacity(0.7)
                                    }
                                }
                                .font(DesignTokens.Typography.quadCaption)
                                .foregroundStyle(.white)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Hero: Before School

private struct BeforeSchoolHeroView: View {
    let model: TodayViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("GOOD MORNING")
                .font(.system(size: 32, weight: .black, design: .default))
                .foregroundStyle(DesignTokens.Colors.primary)
            if let next = model.nextSession {
                let color = CourseColors.color(atIndex: next.course.colorIndex)
                HStack(spacing: 6) {
                    Circle().fill(color).frame(width: 8, height: 8)
                    Text("First up — \(next.course.name)")
                        .font(DesignTokens.Typography.quadBody)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.lg)
    }
}

// MARK: - Hero: After School / No School

private struct AfterOrNoSchoolHeroView: View {
    let title: String
    let model: TodayViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(title)
                .font(.system(size: 32, weight: .black, design: .default))
                .foregroundStyle(DesignTokens.Colors.primary)
            Text(model.nextSchoolDayLabel)
                .font(DesignTokens.Typography.quadLabel)
                .foregroundStyle(DesignTokens.Colors.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.lg)
    }
}

// MARK: - Preview

#Preview {
    TodayView(model: TodayViewModel(previewDate: Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 4, hour: 10, minute: 20))!))
        .preferredColorScheme(.dark)
}
