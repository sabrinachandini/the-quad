import SwiftUI
import PhotosUI

// Convenience aliases to keep call sites readable
private let QFont = DesignTokens.Typography.self
private let QColor = DesignTokens.Colors.self
private let QSpace = DesignTokens.Spacing.self
private let QRadius = DesignTokens.CornerRadius.self

struct OnboardingView: View {
    @State private var model = OnboardingViewModel()

    var body: some View {
        ZStack {
            switch model.currentStep {
            case 0:
                LaunchStep(model: model)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 1:
                LHSStep(model: model)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 2:
                ProfileStep(model: model)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 3:
                ScheduleImportStep(model: model)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 4:
                ParsingStep(model: model)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            default:
                DoneStep(model: model)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: model.currentStep)
    }
}

// MARK: - Shared button

private struct PrimaryButton: View {
    let label: String
    let action: () -> Void
    var enabled: Bool = true

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(QFont.quadHeadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(enabled ? QColor.accent : QColor.accent.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: QRadius.large))
                .padding(.horizontal, QSpace.xl)
        }
        .disabled(!enabled)
    }
}

// MARK: - Step 0: Launch

private struct LaunchStep: View {
    var model: OnboardingViewModel

    var body: some View {
        ZStack {
            QColor.background.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                VStack(alignment: .leading, spacing: QSpace.lg) {
                    Image("QuadLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                    VStack(alignment: .leading, spacing: QSpace.xs) {
                        Text("THE QUAD")
                            .font(.system(size: 52, weight: .black))
                            .tracking(2)
                            .foregroundStyle(QColor.primary)
                        Text("Everything LHS.")
                            .font(QFont.quadBody)
                            .foregroundStyle(QColor.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, QSpace.xl)
                Spacer()
                PrimaryButton(label: "Get started") {
                    withAnimation(.easeInOut(duration: 0.3)) { model.currentStep = 1 }
                }
                Spacer().frame(height: QSpace.xxl)
            }
        }
    }
}

// MARK: - Step 1: LHS

private struct LHSStep: View {
    var model: OnboardingViewModel

    var body: some View {
        ZStack {
            QColor.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                VStack(alignment: .leading, spacing: QSpace.lg) {
                    Text("Built for\nLexington.")
                        .font(QFont.quadTitle)
                        .foregroundStyle(QColor.primary)
                        .lineSpacing(4)
                    Text("The Quad brings together your rotating schedule, coursework, grades, and free time — built exactly for how LHS works.")
                        .font(QFont.quadBody)
                        .foregroundStyle(QColor.secondary)
                        .lineSpacing(3)
                }
                .padding(.horizontal, QSpace.xl)
                Spacer()
                VStack(spacing: QSpace.md) {
                    PrimaryButton(label: "I'm an LHS student →") {
                        withAnimation(.easeInOut(duration: 0.3)) { model.currentStep = 2 }
                    }
                    Text("Not affiliated with Lexington Public Schools.")
                        .font(QFont.quadCaption)
                        .foregroundStyle(QColor.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, QSpace.xl)
                }
                Spacer().frame(height: QSpace.xxl)
            }
        }
    }
}

// MARK: - Step 2: Profile

private struct ProfileStep: View {
    var model: OnboardingViewModel
    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var firstNameText: String = ""
    @State private var lastNameText: String = ""

    private let gradYears = [2026, 2027, 2028, 2029]

    private var profileComplete: Bool {
        !firstNameText.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastNameText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            QColor.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: QSpace.xs) {
                    Text("Let's make this yours.")
                        .font(QFont.quadTitle)
                        .foregroundStyle(QColor.primary)
                    Text("Your name and class.")
                        .font(QFont.quadCaption)
                        .foregroundStyle(QColor.secondary)
                }
                .padding(.horizontal, QSpace.xl)
                .padding(.top, QSpace.xxxl)

                Spacer().frame(height: QSpace.xxl)

                // Photo picker
                HStack {
                    Spacer()
                    VStack(spacing: QSpace.sm) {
                        PhotosPicker(selection: $photoPickerItem, matching: .images) {
                            ZStack {
                                Circle()
                                    .fill(QColor.accent.opacity(0.15))
                                    .frame(width: 72, height: 72)
                                if let img = model.profilePhoto {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 72, height: 72)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.crop.circle")
                                        .font(.system(size: 36))
                                        .foregroundStyle(QColor.accent)
                                }
                            }
                        }
                        Text("Add photo")
                            .font(QFont.quadCaption)
                            .foregroundStyle(QColor.accent)
                    }
                    Spacer()
                }
                .onChange(of: photoPickerItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let img = UIImage(data: data) {
                            model.profilePhoto = img
                        }
                    }
                }

                Spacer().frame(height: QSpace.xl)

                // Name fields
                VStack(spacing: 0) {
                    TextField("First name", text: $firstNameText)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(QColor.primary)
                        .padding(.vertical, QSpace.md)
                        .tint(QColor.accent)
                    Rectangle().fill(QColor.surface).frame(height: 1)
                    TextField("Last name", text: $lastNameText)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(QColor.primary)
                        .padding(.vertical, QSpace.md)
                        .tint(QColor.accent)
                    Rectangle().fill(QColor.surface).frame(height: 1)
                }
                .padding(.horizontal, QSpace.xl)

                Spacer().frame(height: QSpace.xl)

                // Graduation year
                VStack(alignment: .leading, spacing: QSpace.sm) {
                    Text("CLASS OF")
                        .font(QFont.quadCaption)
                        .tracking(1.5)
                        .foregroundStyle(QColor.secondary)
                        .padding(.horizontal, QSpace.xl)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: QSpace.sm) {
                            ForEach(gradYears, id: \.self) { year in
                                Button {
                                    model.graduationYear = year
                                } label: {
                                    Text("'\(String(year).suffix(2))")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(model.graduationYear == year ? .white : QColor.primary)
                                        .frame(width: 64, height: 44)
                                        .background(model.graduationYear == year ? QColor.accent : QColor.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: QRadius.small))
                                }
                            }
                        }
                        .padding(.horizontal, QSpace.xl)
                    }
                }

                Spacer()

                PrimaryButton(label: "Continue →", enabled: profileComplete) {
                    model.firstName = firstNameText
                    model.lastName = lastNameText
                    withAnimation(.easeInOut(duration: 0.3)) { model.currentStep = 3 }
                }
                Spacer().frame(height: QSpace.xxl)
            }
        }
    }
}

// MARK: - Step 3: Schedule Import

private struct ScheduleImportStep: View {
    var model: OnboardingViewModel
    @State private var showManualEntry = false

    var body: some View {
        ZStack {
            QColor.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: QSpace.xs) {
                    Text("What's your\nschedule?")
                        .font(QFont.quadTitle)
                        .foregroundStyle(QColor.primary)
                        .lineSpacing(4)
                    Text("Enter your 6 blocks — takes about 30 seconds.")
                        .font(QFont.quadCaption)
                        .foregroundStyle(QColor.secondary)
                }
                .padding(.horizontal, QSpace.xl)
                .padding(.top, QSpace.xxxl)

                Spacer()

                PrimaryButton(label: "Enter my schedule →", enabled: true) {
                    showManualEntry = true
                }

                Spacer().frame(height: QSpace.xxl)
            }
        }
        .sheet(isPresented: $showManualEntry) {
            ManualScheduleSheet(model: model)
        }
    }
}

// MARK: - Manual Schedule Sheet

private struct ManualScheduleSheet: View {
    var model: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("Enter your courses for each block.")
                    .font(.subheadline)
                    .foregroundStyle(QColor.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, QSpace.md)
                    .padding(.vertical, QSpace.sm)

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(OnboardingViewModel.scheduleBlocks, id: \.self) { block in
                            BlockRow(block: block, model: model)
                            Divider()
                        }
                    }
                    .padding(.horizontal, QSpace.md)
                }

                Divider()
                Button {
                    dismiss()
                    withAnimation(.easeInOut(duration: 0.3)) { model.currentStep = 5 }
                } label: {
                    Text("Save Schedule")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(model.hasAtLeastOneCourse ? QColor.accent : QColor.accent.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: QRadius.large))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .disabled(!model.hasAtLeastOneCourse)
            }
            .navigationTitle("Your Schedule")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Text("Cancel").foregroundStyle(QColor.accent)
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
        HStack(alignment: .top, spacing: QSpace.md) {
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

                HStack(spacing: QSpace.sm) {
                    TextField("Teacher (optional)", text: Binding(
                        get: { model.teachers[block, default: ""] },
                        set: { model.teachers[block] = $0 }
                    ))
                    .font(.caption)
                    .foregroundStyle(QColor.secondary)

                    TextField("Room (optional)", text: Binding(
                        get: { model.rooms[block, default: ""] },
                        set: { model.rooms[block] = $0 }
                    ))
                    .font(.caption)
                    .foregroundStyle(QColor.secondary)
                }
            }
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Step 4: Parsing

private struct ParsingStep: View {
    var model: OnboardingViewModel

    @State private var parsingStep: Int = 0
    @State private var pulsing: Bool = false
    @State private var timer: Timer? = nil

    private let messages = [
        "Reading your schedule…",
        "Finding your classes",
        "Matching your blocks",
        "Building your six-day rotation"
    ]

    var body: some View {
        ZStack {
            QColor.accent.ignoresSafeArea()
            VStack(spacing: QSpace.xxl) {
                Spacer()
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulsing ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulsing)
                    Circle()
                        .fill(.white.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulsing ? 0.9 : 1.05)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true).delay(0.15), value: pulsing)
                    Circle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 44, height: 44)
                }

                Text(messages[min(parsingStep, messages.count - 1)])
                    .font(QFont.quadTitle)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .id(parsingStep)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.4), value: parsingStep)
                    .padding(.horizontal, QSpace.xxl)

                Spacer()
            }
        }
        .onAppear {
            pulsing = true
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func startTimer() {
        var count = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { t in
            count += 1
            withAnimation(.easeInOut(duration: 0.4)) {
                parsingStep = min(count, messages.count - 1)
            }
            if count >= messages.count {
                t.invalidate()
                timer = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        model.currentStep = 5
                    }
                }
            }
        }
    }
}

// MARK: - Step 5: Done

private struct DoneStep: View {
    var model: OnboardingViewModel

    private var schedulePreview: [(String, String)] {
        Array(OnboardingViewModel.scheduleBlocks.compactMap { block -> (String, String)? in
            let name = model.courseNames[block, default: ""].trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { return nil }
            return (block.rawValue, name)
        }.prefix(3))
    }

    private var displayFirstName: String {
        let f = model.firstName.trimmingCharacters(in: .whitespaces)
        return f.isEmpty ? "Student" : f
    }

    var body: some View {
        ZStack {
            QColor.background.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: QSpace.lg) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(QColor.accent)

                    VStack(spacing: QSpace.xs) {
                        Text("Your Quad is ready.")
                            .font(QFont.quadTitle)
                            .foregroundStyle(QColor.primary)
                            .multilineTextAlignment(.center)
                        Text("Welcome, \(displayFirstName).")
                            .font(QFont.quadBody)
                            .foregroundStyle(QColor.secondary)
                    }

                    if !schedulePreview.isEmpty {
                        VStack(spacing: QSpace.xs) {
                            ForEach(schedulePreview, id: \.0) { block, name in
                                HStack(spacing: QSpace.sm) {
                                    Text("Block \(block)")
                                        .font(QFont.quadCaption)
                                        .tracking(1)
                                        .foregroundStyle(QColor.secondary)
                                        .frame(width: 60, alignment: .leading)
                                    Text(name)
                                        .font(QFont.quadBody)
                                        .foregroundStyle(QColor.primary)
                                        .lineLimit(1)
                                    Spacer()
                                }
                            }
                        }
                        .padding(QSpace.lg)
                        .background(QColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: QRadius.medium))
                        .padding(.horizontal, QSpace.xl)
                    }
                }
                Spacer()
                PrimaryButton(label: "Open The Quad →") {
                    Task {
                        await NotificationScheduler.shared.requestPermission()
                        NotificationScheduler.shared.scheduleAll()
                    }
                    model.complete()
                }
                Spacer().frame(height: QSpace.xxl)
            }
        }
    }
}

#Preview("Launch") {
    OnboardingView()
}

#Preview("Parsing") {
    let model = OnboardingViewModel()
    return ParsingStep(model: model)
}

#Preview("Done") {
    let model = OnboardingViewModel()
    model.firstName = "Sabrina"
    model.lastName = "Chandini"
    model.courseNames[.a] = "AP Biology"
    model.courseNames[.b] = "AP Calculus BC"
    model.courseNames[.c] = "English 11"
    return DoneStep(model: model)
}
