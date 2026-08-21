import SwiftUI

struct GradesView: View {
    @State private var model = GradesViewModel()

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()
            if model.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                        Text("Grades")
                            .font(DesignTokens.Typography.quadTitle)
                            .foregroundStyle(DesignTokens.Colors.primary)
                        ForEach(model.grades) { grade in
                            card(grade)
                        }
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .padding(.bottom, DesignTokens.Spacing.xxxl)
                }
            }
        }
    }

    private func card(_ grade: CourseGrade) -> some View {
        let course = model.course(for: grade)
        let color = course.map { CourseColors.color(atIndex: $0.colorIndex) } ?? DesignTokens.Colors.accent
        return HStack(spacing: DesignTokens.Spacing.lg) {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                .fill(color)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(course?.name ?? "Course")
                    .font(DesignTokens.Typography.quadHeadline)
                    .foregroundStyle(DesignTokens.Colors.primary)
                if let t = course?.teacher {
                    Text(t)
                        .font(DesignTokens.Typography.quadCaption)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xs) {
                Text(grade.letterGrade ?? "—")
                    .font(DesignTokens.Typography.quadTitle)
                    .foregroundStyle(color)
                if let pct = grade.currentGrade {
                    Text(String(format: "%.1f%%", pct))
                        .font(DesignTokens.Typography.quadCaption)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 44))
                .foregroundStyle(DesignTokens.Colors.accent)
            Text("Connect Aspen to see grades.")
                .font(DesignTokens.Typography.quadHeadline)
                .foregroundStyle(DesignTokens.Colors.primary)
        }
    }
}

#Preview {
    GradesView().preferredColorScheme(.dark)
}
