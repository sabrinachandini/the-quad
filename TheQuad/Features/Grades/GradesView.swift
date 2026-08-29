import SwiftUI
import UIKit

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
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Grades")
                                .font(DesignTokens.Typography.quadTitle)
                                .foregroundStyle(DesignTokens.Colors.primary)
                                .padding(.horizontal, DesignTokens.Spacing.lg)
                                .padding(.top, DesignTokens.Spacing.lg)
                                .padding(.bottom, DesignTokens.Spacing.xl)

                            VStack(spacing: 0) {
                                ForEach(Array(model.grades.enumerated()), id: \.element.id) { index, grade in
                                    NavigationLink(value: grade.id) {
                                        GradeRow(grade: grade, model: model)
                                    }
                                    .buttonStyle(.plain)

                                    if index < model.grades.count - 1 {
                                        Divider()
                                            .padding(.leading, DesignTokens.Spacing.lg)
                                    }
                                }
                            }
                        }
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
            Text("Connect Aspen to import grades — or add manually.")
                .font(DesignTokens.Typography.quadHeadline)
                .foregroundStyle(DesignTokens.Colors.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.Spacing.xl)
            Button {
                // TODO: navigate to manual grade entry
            } label: {
                Text("Add Grade")
                    .font(DesignTokens.Typography.quadBody.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                    .padding(.vertical, DesignTokens.Spacing.md)
                    .background(DesignTokens.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Grade Row (editorial, accent-band style)

private struct GradeRow: View {
    let grade: CourseGrade
    let model: GradesViewModel

    var body: some View {
        let course = model.course(for: grade)
        let color = course.map { CourseColors.color(atIndex: $0.colorIndex) } ?? DesignTokens.Colors.accent
        let pct = model.overallPercentage(for: grade)
        let letter = model.letterGrade(for: grade)

        // Build category summary string: "Tests 50% · HW 30%"
        let categorySummary: String? = {
            let cats = grade.categories
            guard !cats.isEmpty else { return nil }
            return cats.map { "\($0.name) \(Int($0.weight * 100))%" }.joined(separator: " · ")
        }()

        HStack(spacing: 0) {
            // Left accent band
            Rectangle()
                .fill(color)
                .frame(width: 4)

            // Content
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(course?.name ?? "Course")
                        .font(DesignTokens.Typography.quadBody)
                        .foregroundStyle(DesignTokens.Colors.primary)
                    if let summary = categorySummary {
                        Text(summary)
                            .font(DesignTokens.Typography.quadCaption)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.leading, DesignTokens.Spacing.md)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(letter)
                        .font(DesignTokens.Typography.quadTitle.weight(.bold))
                        .foregroundStyle(color)
                    if let pct {
                        Text(String(format: "%.1f%%", pct))
                            .font(DesignTokens.Typography.quadCaption)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                    }
                }
                .padding(.trailing, DesignTokens.Spacing.lg)
            }
            .padding(.vertical, DesignTokens.Spacing.lg)
        }
        .frame(maxWidth: .infinity)
        .background(DesignTokens.Colors.background)
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

    private var liveGrade: CourseGrade {
        model.grades.first { $0.id == grade.id } ?? grade
    }

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                    gradeHeader
                    categoriesSection
                    whatIfSection
                    finalExamSection
                }
                .padding(.bottom, DesignTokens.Spacing.xxxl)
            }
            .onTapGesture { focusedField = nil }
        }
        .navigationTitle(course?.name ?? "Grade Detail")
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: model.whatIfGrade) { old, new in
            guard let new else { return }
            if old == nil {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else if let old, GradeEngine.letterGrade(from: old) != GradeEngine.letterGrade(from: new) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
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
            Text(liveLetter)
                .font(.system(size: 72, weight: .bold, design: .default))
                .foregroundStyle(color)
                .tracking(-1)
            if let livePct {
                Text(String(format: "%.1f%%", livePct))
                    .font(DesignTokens.Typography.quadHeadline)
                    .foregroundStyle(color.opacity(0.75))
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.top, DesignTokens.Spacing.sm)
    }

    // MARK: - Categories

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
            ForEach(liveGrade.categories) { category in
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    // Section header — uppercase tracked label
                    HStack {
                        Text("\(category.name.uppercased()) · \(Int(category.weight * 100))%")
                            .font(DesignTokens.Typography.quadLabel)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                        Spacer()
                        if let avg = GradeEngine.categoryAverage(category) {
                            Text(String(format: "%.1f%%", avg))
                                .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                                .foregroundStyle(color)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)

                    // Entry rows with dividers
                    VStack(spacing: 0) {
                        ForEach(Array(category.entries.enumerated()), id: \.element.id) { idx, entry in
                            DetailEntryRow(entry: entry, courseColor: color)
                            if idx < category.entries.count - 1 {
                                Divider()
                                    .padding(.leading, DesignTokens.Spacing.lg)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - What-If (inline bordered region)

    private var whatIfSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thin rule on top
            Rectangle()
                .fill(DesignTokens.Colors.secondary.opacity(0.25))
                .frame(height: 1)
                .padding(.horizontal, DesignTokens.Spacing.lg)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("WHAT IF?")
                    .font(DesignTokens.Typography.quadLabel)
                    .foregroundStyle(DesignTokens.Colors.secondary)

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
                            .background(DesignTokens.Colors.surface)
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
                            .background(DesignTokens.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                            .font(DesignTokens.Typography.quadBody)
                            .foregroundStyle(DesignTokens.Colors.primary)
                    }
                }

                if let whatIf = model.whatIfGrade {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Text("Grade would be")
                            .font(DesignTokens.Typography.quadBody)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                        Text(String(format: "%.1f%%", whatIf))
                            .font(DesignTokens.Typography.quadBody.weight(.semibold))
                            .foregroundStyle(color)
                        Text("(\(GradeEngine.letterGrade(from: whatIf)))")
                            .font(DesignTokens.Typography.quadBody.weight(.semibold))
                            .foregroundStyle(color)
                    }
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
    }

    // MARK: - Final Exam (compact)

    private var finalExamSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(DesignTokens.Colors.secondary.opacity(0.25))
                .frame(height: 1)
                .padding(.horizontal, DesignTokens.Spacing.lg)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("NEED ON FINAL")
                    .font(DesignTokens.Typography.quadLabel)
                    .foregroundStyle(DesignTokens.Colors.secondary)

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
                } else {
                    Text("Not enough grade data to calculate.")
                        .font(DesignTokens.Typography.quadBody)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
    }
}

// MARK: - Detail Entry Row

private struct DetailEntryRow: View {
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
                Text(String(format: "%.0f/%.0f · %.0f%%", earned, entry.pointsPossible, pct))
                    .font(DesignTokens.Typography.quadCaption)
                    .foregroundStyle(entry.isDropped ? DesignTokens.Colors.secondary : courseColor)
                    .strikethrough(entry.isDropped)
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
