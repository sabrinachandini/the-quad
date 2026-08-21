import SwiftUI

struct TodayView: View {
    @State private var model = TodayViewModel()

    private func timeString(_ comps: DateComponents) -> String {
        var c = DateComponents()
        c.hour = comps.hour; c.minute = comps.minute
        let date = Calendar.current.date(from: c) ?? Date()
        return date.formatted(.dateTime.hour().minute())
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
                .background(DesignTokens.Colors.accent)
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
    private var fullDay: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Full Day")
                .font(DesignTokens.Typography.quadHeadline)
                .foregroundStyle(DesignTokens.Colors.primary)
            ForEach(model.allSlots) { slot in
                slotRow(slot)
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
            // free block — airy, no card background
            HStack {
                Text(time)
                    .font(DesignTokens.Typography.quadCaption)
                    .foregroundStyle(DesignTokens.Colors.secondary)
                    .frame(width: 110, alignment: .leading)
                Text("Free")
                    .font(DesignTokens.Typography.quadBody.weight(.medium))
                    .foregroundStyle(DesignTokens.Colors.secondary)
                Spacer()
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
}

#Preview {
    TodayView().preferredColorScheme(.dark)
}
