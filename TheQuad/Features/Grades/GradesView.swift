import SwiftUI

// MARK: - Main Grades View

struct GradesView: View {
    @State private var model = GradesViewModel()

    var body: some View {
        NavigationStack {
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
                                NavigationLink(value: grade.id) {
                                    GradeCard(grade: grade, model: model)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(DesignTokens.Spacing.lg)
                        .padding(.bottom, DesignTokens.Spacing.xxxl)
                    }
                }
            }
            .navigationDestination(for: UUID.self) { gradeId in
                if let grade = model.grades.first(where: { $0.id == gradeId }) {
                    CourseGradeDetailView(grade: grade, model: model)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 48))
                .foregroundStyle(DesignTokens.Colors.accent)
            Text("Connect Aspen in the Me tab to sync your grades automatically.")
                .font(DesignTokens.Typography.quadHeadline)
                .foregroundStyle(DesignTokens.Colors.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.Spacing.xl)
            Text("Aspen is Lexington Public Schools' grade portal. Tap Me → Aspen Grades to connect.")
                .font(DesignTokens.Typography.quadCaption)
                .foregroundStyle(DesignTokens.Colors.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Grade Card

private struct GradeCard: View {
    let grade: CourseGrade
    let model: GradesViewModel

    var body: some View {
        let course = model.course(for: grade)
        let color = course.map { CourseColors.color(atIndex: $0.colorIndex) } ?? DesignTokens.Colors.accent
        let pct = model.overallPercentage(for: grade)
        let letter = model.letterGrade(for: grade)

        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(course?.name ?? grade.name)
                        .font(DesignTokens.Typography.quadHeadline)
                        .foregroundStyle(DesignTokens.Colors.primary)
                    if let pct {
                        Text(String(format: "%.1f%%", pct))
                            .font(DesignTokens.Typography.quadCaption)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                    }
                }
                Spacer()
                Text(letter)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(color)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.18))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat((pct ?? 0) / 100.0), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
    }
}

// MARK: - Course Grade Detail View

struct CourseGradeDetailView: View {
    let grade: CourseGrade
    @Bindable var model: GradesViewModel

    @FocusState private var focusedField: DetailField?

    enum DetailField: Hashable {
        case score, possible
    }

    private var course: Course? { model.course(for: grade) }
    private var color: Color {
        course.map { CourseColors.color(atIndex: $0.colorIndex) } ?? DesignTokens.Colors.accent
    }
    private var pct: Double? { model.overallPercentage(for: grade) }
    private var letter: String { model.letterGrade(for: grade) }

    // Live grade: use updated grade from AppState so what-if changes reflect
    private var liveGrade: CourseGrade {
        model.grades.first { $0.id == grade.id } ?? grade
    }

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                    gradeHeader
                    ForEach(liveGrade.categories) { category in
                        CategorySection(category: category, courseColor: color)
                    }
                    whatIfCard
                    finalExamCard
                }
                .padding(DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.xxxl)
            }
            .simultaneousGesture(TapGesture().onEnded { focusedField = nil })
        }
        .navigationTitle(course?.name ?? grade.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            model.selectedCourseGradeId = grade.id
            if model.hypotheticalCategoryId == nil {
                model.hypotheticalCategoryId = grade.categories.first?.id
            }
        }
        .onDisappear {
            model.selectedCourseGradeId = nil
            model.clearWhatIf()
        }
    }

    // MARK: - Header

    private var gradeHeader: some View {
        let livePct = model.overallPercentage(for: liveGrade)
        let liveLetter = model.letterGrade(for: liveGrade)
        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(course?.name ?? grade.name)
                .font(DesignTokens.Typography.quadTitle)
                .foregroundStyle(DesignTokens.Colors.primary)
            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.sm) {
                Text(liveLetter)
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(color)
                if let livePct {
                    Text(String(format: "%.1f%%", livePct))
                        .font(DesignTokens.Typography.quadHeadline)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
    }

    // MARK: - What-If Card

    private var whatIfCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Image(systemName: "wand.and.sparkles")
                    .foregroundStyle(color)
                Text("What If?")
                    .font(DesignTokens.Typography.quadHeadline)
                    .foregroundStyle(DesignTokens.Colors.primary)
            }

            // Category picker
            Picker("Category", selection: Binding(
                get: { model.hypotheticalCategoryId ?? liveGrade.categories.first?.id },
                set: { model.hypotheticalCategoryId = $0 }
            )) {
                ForEach(liveGrade.categories) { cat in
                    Text(cat.name).tag(Optional(cat.id))
                }
            }
            .pickerStyle(.segmented)

            // Score inputs
            HStack(spacing: DesignTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Score")
                        .font(DesignTokens.Typography.quadCaption)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                    TextField("0", text: $model.hypotheticalScore)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .score)
                        .padding(DesignTokens.Spacing.sm)
                        .background(DesignTokens.Colors.background)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                        .font(DesignTokens.Typography.quadBody)
                        .foregroundStyle(DesignTokens.Colors.primary)
                }
                Text("/")
                    .font(DesignTokens.Typography.quadHeadline)
                    .foregroundStyle(DesignTokens.Colors.secondary)
                    .padding(.top, DesignTokens.Spacing.xl)
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Out of")
                        .font(DesignTokens.Typography.quadCaption)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                    TextField("100", text: $model.hypotheticalPossible)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .possible)
                        .padding(DesignTokens.Spacing.sm)
                        .background(DesignTokens.Colors.background)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                        .font(DesignTokens.Typography.quadBody)
                        .foregroundStyle(DesignTokens.Colors.primary)
                }
            }

            // Live preview
            if let whatIf = model.whatIfGrade {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(color)
                    Text("Grade would be ")
                        .font(DesignTokens.Typography.quadBody)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                    + Text(String(format: "%.1f%%", whatIf))
                        .font(DesignTokens.Typography.quadBody.weight(.semibold))
                        .foregroundStyle(color)
                    + Text(" (\(GradeEngine.letterGrade(from: whatIf)))")
                        .font(DesignTokens.Typography.quadBody.weight(.semibold))
                        .foregroundStyle(color)
                }
                .padding(DesignTokens.Spacing.sm)
                .background(color.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
    }

    // MARK: - Final Exam Calculator

    private var finalExamCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Image(systemName: "calendar.badge.checkmark")
                    .foregroundStyle(color)
                Text("Need on Final")
                    .font(DesignTokens.Typography.quadHeadline)
                    .foregroundStyle(DesignTokens.Colors.primary)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                HStack {
                    Text("Target grade")
                        .font(DesignTokens.Typography.quadBody)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", model.targetGradePercent))
                        .font(DesignTokens.Typography.quadBody.weight(.semibold))
                        .foregroundStyle(color)
                }
                Slider(value: $model.targetGradePercent, in: 70...100, step: 1)
                    .tint(color)
            }

            if let result = GradeEngine.scoreNeededOnFinal(
                currentGrade: liveGrade,
                finalWeight: 0.20,
                targetPercentage: model.targetGradePercent
            ) {
                let scoreText = String(format: "%.1f%%", result.score)
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: result.isAchievable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(result.isAchievable ? color : DesignTokens.Colors.destructive)
                    if result.score <= 0 {
                        Text("You've already reached \(String(format: "%.0f%%", model.targetGradePercent))!")
                            .font(DesignTokens.Typography.quadBody)
                            .foregroundStyle(color)
                    } else if result.isAchievable {
                        Text("You need \(scoreText) on a 20% final to reach \(String(format: "%.0f%%", model.targetGradePercent)).")
                            .font(DesignTokens.Typography.quadBody)
                            .foregroundStyle(DesignTokens.Colors.primary)
                    } else {
                        Text("You'd need \(scoreText) — not achievable. Consider a lower target.")
                            .font(DesignTokens.Typography.quadBody)
                            .foregroundStyle(DesignTokens.Colors.destructive)
                    }
                }
                .padding(DesignTokens.Spacing.sm)
                .background((result.isAchievable ? color : DesignTokens.Colors.destructive).opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
            } else {
                Text("Not enough grade data to calculate.")
                    .font(DesignTokens.Typography.quadBody)
                    .foregroundStyle(DesignTokens.Colors.secondary)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
    }
}

// MARK: - Category Section

private struct CategorySection: View {
    let category: GradeCategory
    let courseColor: Color

    private var avg: Double? {
        GradeEngine.categoryAverage(category)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("\(category.name) · \(Int(category.weight * 100))%")
                    .font(DesignTokens.Typography.quadHeadline)
                    .foregroundStyle(DesignTokens.Colors.primary)
                Spacer()
                if let avg {
                    Text(String(format: "%.1f%%", avg))
                        .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                        .foregroundStyle(courseColor)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                        .background(courseColor.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                }
            }

            VStack(spacing: 1) {
                ForEach(category.entries) { entry in
                    EntryRow(entry: entry, courseColor: courseColor)
                }
            }
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
        }
    }
}

// MARK: - Entry Row

private struct EntryRow: View {
    let entry: GradeEntry
    let courseColor: Color

    private var pct: Double? {
        guard let earned = entry.pointsEarned, entry.pointsPossible > 0 else { return nil }
        return (earned / entry.pointsPossible) * 100.0
    }

    var body: some View {
        HStack {
            Text(entry.title)
                .font(DesignTokens.Typography.quadBody)
                .foregroundStyle(entry.isDropped ? DesignTokens.Colors.secondary : DesignTokens.Colors.primary)
                .strikethrough(entry.isDropped)

            Spacer()

            if let earned = entry.pointsEarned, let pct {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Text(String(format: "%.0f/%.0f", earned, entry.pointsPossible))
                        .font(DesignTokens.Typography.quadCaption)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                        .strikethrough(entry.isDropped)
                    Text("·")
                        .foregroundStyle(DesignTokens.Colors.secondary)
                    Text(String(format: "%.0f%%", pct))
                        .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                        .foregroundStyle(entry.isDropped ? DesignTokens.Colors.secondary : courseColor)
                        .strikethrough(entry.isDropped)
                }
            } else {
                Text("—")
                    .font(DesignTokens.Typography.quadCaption)
                    .foregroundStyle(DesignTokens.Colors.secondary)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.md)
    }
}

#Preview {
    GradesView().preferredColorScheme(.dark)
}
