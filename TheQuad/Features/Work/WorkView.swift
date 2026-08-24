import SwiftUI

struct WorkView: View {
    @State private var model = WorkViewModel()
    @State private var showAddSheet = false
    @State private var showCompleted = false

    // MARK: - Helpers

    private func courseColor(_ id: UUID?) -> Color {
        guard let id, let c = AppState.shared.courses.first(where: { $0.id == id }) else {
            return DesignTokens.Colors.secondary
        }
        return CourseColors.color(atIndex: c.colorIndex)
    }

    private func courseName(_ id: UUID?) -> String {
        guard let id, let c = AppState.shared.courses.first(where: { $0.id == id }) else {
            return ""
        }
        return c.name
    }

    private func dueLabel(_ date: Date?) -> String {
        guard let date else { return "" }
        let cal = Calendar.current
        let today = Date()
        if cal.isDate(date, inSameDayAs: today) { return "Today" }
        if cal.isDate(date, inSameDayAs: cal.date(byAdding: .day, value: 1, to: today) ?? today) { return "Tomorrow" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func sectionLabel(for date: Date?) -> String {
        guard let date else { return "LATER" }
        let cal = Calendar.current
        let today = Date()
        if cal.isDate(date, inSameDayAs: today) { return "TODAY" }
        if cal.isDate(date, inSameDayAs: cal.date(byAdding: .day, value: 1, to: today) ?? today) { return "TOMORROW" }
        return "LATER"
    }

    private var completedAssignments: [Assignment] {
        AppState.shared.assignments.filter { $0.isCompleted }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                headerRow
                filterTabs
                    .padding(.top, DesignTokens.Spacing.sm)

                if model.isEmpty && completedAssignments.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    assignmentList
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddWorkSheet(model: model)
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text("WORK")
                .font(DesignTokens.Typography.quadTitle)
                .foregroundStyle(DesignTokens.Colors.primary)
            Spacer()
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(DesignTokens.Colors.accent)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.top, DesignTokens.Spacing.lg)
        .padding(.bottom, DesignTokens.Spacing.md)
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            ForEach(WorkFilter.allCases, id: \.self) { f in
                filterTab(f)
            }
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }

    private func filterTab(_ f: WorkFilter) -> some View {
        let isSelected = model.filter == f
        return VStack(spacing: DesignTokens.Spacing.xs) {
            Text(filterLabel(f))
                .font(
                    isSelected
                        ? DesignTokens.Typography.quadCaption.weight(.bold)
                        : DesignTokens.Typography.quadCaption
                )
                .foregroundStyle(
                    isSelected
                        ? DesignTokens.Colors.primary
                        : DesignTokens.Colors.secondary
                )
            Rectangle()
                .fill(isSelected ? DesignTokens.Colors.accent : Color.clear)
                .frame(height: 2)
        }
        .onTapGesture {
            model.filter = f
        }
        .animation(DesignTokens.Animations.standard, value: model.filter)
    }

    private func filterLabel(_ f: WorkFilter) -> String {
        switch f {
        case .today: return "TODAY"
        case .thisWeek: return "THIS WEEK"
        case .all: return "ALL"
        }
    }

    // MARK: - Assignment List

    private var assignmentList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(model.groupedByDueDate.enumerated()), id: \.element.date) { index, group in
                    // Section header
                    Text(sectionLabel(for: group.date))
                        .font(DesignTokens.Typography.quadLabel)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                        .padding(.top, index == 0 ? DesignTokens.Spacing.lg : DesignTokens.Spacing.xl)
                        .padding(.bottom, DesignTokens.Spacing.sm)
                        .padding(.horizontal, DesignTokens.Spacing.lg)

                    // Rows for this group
                    ForEach(Array(group.items.enumerated()), id: \.element.id) { rowIndex, assignment in
                        assignmentRow(assignment)
                        if rowIndex < group.items.count - 1 {
                            Divider()
                                .overlay(DesignTokens.Colors.secondary.opacity(0.3))
                                .padding(.leading, DesignTokens.Spacing.lg + 8 + DesignTokens.Spacing.md) // align past dot
                        }
                    }
                }

                // Done collapse row
                if !completedAssignments.isEmpty {
                    doneCollapseRow
                        .padding(.top, DesignTokens.Spacing.xl)

                    if showCompleted {
                        ForEach(Array(completedAssignments.enumerated()), id: \.element.id) { idx, assignment in
                            completedRow(assignment)
                            if idx < completedAssignments.count - 1 {
                                Divider()
                                    .overlay(DesignTokens.Colors.secondary.opacity(0.2))
                                    .padding(.leading, DesignTokens.Spacing.lg)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, DesignTokens.Spacing.xxxl)
        }
    }

    // MARK: - Active Assignment Row

    private func assignmentRow(_ assignment: Assignment) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Course color dot — tap to complete
            Button {
                model.toggleComplete(assignment)
            } label: {
                Circle()
                    .fill(courseColor(assignment.courseId))
                    .frame(width: 8, height: 8)
            }

            VStack(alignment: .leading, spacing: 2) {
                let name = courseName(assignment.courseId)
                if !name.isEmpty {
                    Text(name.uppercased())
                        .font(DesignTokens.Typography.quadCaption)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                }
                Text(assignment.title)
                    .font(DesignTokens.Typography.quadBody)
                    .foregroundStyle(DesignTokens.Colors.primary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(dueLabel(assignment.dueDate))
                    .font(DesignTokens.Typography.quadCaption)
                    .foregroundStyle(DesignTokens.Colors.secondary)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.md)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                model.deleteAssignment(assignment)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                model.toggleComplete(assignment)
            } label: {
                Label("Done", systemImage: "checkmark")
            }
            .tint(DesignTokens.Colors.accent)
        }
    }

    // MARK: - Done Collapse

    private var doneCollapseRow: some View {
        HStack {
            Text("DONE")
                .font(DesignTokens.Typography.quadLabel)
                .foregroundStyle(DesignTokens.Colors.secondary)
            Text("·")
                .font(DesignTokens.Typography.quadLabel)
                .foregroundStyle(DesignTokens.Colors.secondary)
            Text("\(completedAssignments.count)")
                .font(DesignTokens.Typography.quadLabel)
                .foregroundStyle(DesignTokens.Colors.secondary)
            Spacer()
            Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(DesignTokens.Colors.secondary)
        }
        .padding(.vertical, DesignTokens.Spacing.md)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(DesignTokens.Animations.standard) {
                showCompleted.toggle()
            }
        }
    }

    // MARK: - Completed Row

    private func completedRow(_ assignment: Assignment) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Button {
                model.toggleComplete(assignment)
            } label: {
                Circle()
                    .fill(DesignTokens.Colors.secondary.opacity(0.4))
                    .frame(width: 8, height: 8)
            }

            Text(assignment.title)
                .font(DesignTokens.Typography.quadBody)
                .foregroundStyle(DesignTokens.Colors.secondary)
                .strikethrough(true, color: DesignTokens.Colors.secondary)

            Spacer()
        }
        .padding(.vertical, DesignTokens.Spacing.md)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                model.deleteAssignment(assignment)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("ALL CLEAR")
                .font(DesignTokens.Typography.quadHeadline)
                .foregroundStyle(DesignTokens.Colors.primary)
            Text("Nothing due.")
                .font(DesignTokens.Typography.quadBody)
                .foregroundStyle(DesignTokens.Colors.secondary)
        }
    }
}

#Preview {
    WorkView().preferredColorScheme(.dark)
}
