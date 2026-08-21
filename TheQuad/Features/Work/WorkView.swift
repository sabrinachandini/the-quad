import SwiftUI

struct WorkView: View {
    @State private var model = WorkViewModel()
    @State private var showAddSheet = false

    private func courseColor(_ id: UUID?) -> Color {
        guard let id, let c = AppState.shared.courses.first(where: { $0.id == id }) else {
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
            VStack(spacing: 0) {
                // Header row with title and add button
                HStack {
                    Text("Work")
                        .font(DesignTokens.Typography.quadTitle)
                        .foregroundStyle(DesignTokens.Colors.primary)
                    Spacer()
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(DesignTokens.Colors.accent)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.top, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.md)

                // Filter picker
                Picker("Filter", selection: $model.filter) {
                    ForEach(WorkFilter.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.sm)

                if model.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
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
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        .padding(.top, DesignTokens.Spacing.md)
                        .padding(.bottom, DesignTokens.Spacing.xxxl)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddWorkSheet(model: model)
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
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                model.deleteAssignment(assignment)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
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
