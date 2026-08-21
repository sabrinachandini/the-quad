import SwiftUI

struct WorkView: View {
    @State private var model = WorkViewModel()

    private func courseColor(_ id: UUID?) -> Color {
        guard let id, let c = MockStudentSchedule.courses.first(where: { $0.id == id }) else {
            return DesignTokens.Colors.secondary
        }
        return CourseColors.color(atIndex: c.colorIndex)
    }

    private func dueLabel(_ date: Date?) -> String {
        guard let date else { return "No due date" }
        return date.formatted(.dateTime.weekday(.wide).month().day())
    }

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()
            if model.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                        Text("Work")
                            .font(DesignTokens.Typography.quadTitle)
                            .foregroundStyle(DesignTokens.Colors.primary)
                        ForEach(model.groupedByDueDate, id: \.date) { group in
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                                Text(dueLabel(group.date))
                                    .font(DesignTokens.Typography.quadHeadline)
                                    .foregroundStyle(DesignTokens.Colors.primary)
                                ForEach(group.items) { assignment in
                                    row(assignment)
                                }
                            }
                        }
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .padding(.bottom, DesignTokens.Spacing.xxxl)
                }
            }
        }
    }

    private func row(_ assignment: Assignment) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Button {
                model.toggleComplete(assignment)
            } label: {
                Image(systemName: assignment.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(courseColor(assignment.courseId))
                    .font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.title)
                    .font(DesignTokens.Typography.quadBody.weight(.medium))
                    .foregroundStyle(DesignTokens.Colors.primary)
                if let mins = assignment.estimatedMinutes {
                    Text("~\(mins) min")
                        .font(DesignTokens.Typography.quadCaption)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                }
            }
            Spacer()
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(DesignTokens.Colors.accent)
            Text("Nothing due — nice.")
                .font(DesignTokens.Typography.quadHeadline)
                .foregroundStyle(DesignTokens.Colors.primary)
        }
    }
}

#Preview {
    WorkView().preferredColorScheme(.dark)
}
