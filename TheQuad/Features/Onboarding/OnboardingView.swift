import SwiftUI

struct OnboardingView: View {
    @State private var model = OnboardingViewModel()

    var body: some View {
        ZStack {
            switch model.step {
            case 0:
                WelcomeStep(model: model)
                    .transition(.opacity)
            case 1:
                ScheduleStep(model: model)
                    .transition(.opacity)
            default:
                DoneStep(model: model)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: model.step)
    }
}

// MARK: - Step 0: Welcome

private struct WelcomeStep: View {
    var model: OnboardingViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                Text("The Quad")
                    .font(.system(size: 48, weight: .black))
                    .foregroundStyle(.white)
                Text("Everything LHS.")
                    .font(.title3)
                    .foregroundStyle(.gray)
                    .padding(.top, 4)
                Spacer()
                Button {
                    withAnimation { model.step = 1 }
                } label: {
                    Text("Get started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(DesignTokens.Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 24)
                }
                Spacer().frame(height: 40)
            }
        }
    }
}

// MARK: - Step 1: Schedule Entry

private struct ScheduleStep: View {
    var model: OnboardingViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("Enter your courses for each block.")
                    .font(.subheadline)
                    .foregroundStyle(DesignTokens.Colors.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(OnboardingViewModel.scheduleBlocks, id: \.self) { block in
                            BlockRow(block: block, model: model)
                            Divider()
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                }

                Divider()
                Button {
                    withAnimation { model.step = 2 }
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(model.hasAtLeastOneCourse
                            ? DesignTokens.Colors.accent
                            : DesignTokens.Colors.accent.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .disabled(!model.hasAtLeastOneCourse)
            }
            .navigationTitle("Your Schedule")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation { model.step = 0 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(DesignTokens.Colors.accent)
                    }
                }
            }
        }
    }
}

private struct BlockRow: View {
    let block: AcademicBlock
    var model: OnboardingViewModel

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            ZStack {
                Circle()
                    .fill(CourseColors.color(for: block))
                    .frame(width: 32, height: 32)
                Text(block.rawValue)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.top, 14)

            VStack(alignment: .leading, spacing: 4) {
                TextField("Course name", text: Binding(
                    get: { model.courseNames[block, default: ""] },
                    set: { model.courseNames[block] = $0 }
                ))
                .font(.body)

                HStack(spacing: DesignTokens.Spacing.sm) {
                    TextField("Teacher (optional)", text: Binding(
                        get: { model.teachers[block, default: ""] },
                        set: { model.teachers[block] = $0 }
                    ))
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Colors.secondary)

                    TextField("Room (optional)", text: Binding(
                        get: { model.rooms[block, default: ""] },
                        set: { model.rooms[block] = $0 }
                    ))
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Colors.secondary)
                }
            }
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Step 2: Done

private struct DoneStep: View {
    var model: OnboardingViewModel

    private var doneSubtitle: String {
        let engine = AppState.shared.scheduleEngine
        if engine.dayType(for: Date()) != nil {
            return "Your schedule is ready."
        } else {
            return "See you on the next school day."
        }
    }

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(DesignTokens.Colors.accent)
                Text("You're all set.")
                    .font(.system(size: 36, weight: .bold))
                    .padding(.top, 16)
                Text(doneSubtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal, 32)
                Spacer()
                Button {
                    model.complete()
                } label: {
                    Text("Open The Quad")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(DesignTokens.Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 24)
                }
                Spacer().frame(height: 40)
            }
        }
    }
}

#Preview("Welcome") {
    OnboardingView()
}
