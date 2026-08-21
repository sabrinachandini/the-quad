import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct OnboardingView: View {
    @State private var model = OnboardingViewModel()

    var body: some View {
        ZStack {
            switch model.step {
            case 0:
                WelcomeStep(model: model)
                    .transition(.opacity)
            case 1:
                ImportStep(model: model)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            case 2:
                ManualEntryStep(model: model)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            default:
                DoneStep(model: model)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: model.step)
        // Image picker sheet
        .sheet(isPresented: $model.showImagePicker) {
            ImagePickerSheet { image in
                model.showImagePicker = false
                if let image { model.handleImageSelected(image) }
            }
        }
        // Document picker sheet
        .sheet(isPresented: $model.showDocumentPicker) {
            DocumentPickerSheet {
                model.showDocumentPicker = false
                model.handleDocumentSelected()
            }
        }
        // Analyzing overlay
        .overlay {
            if model.isAnalyzing {
                AnalyzingOverlay()
            }
        }
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

// MARK: - Step 1: Import your schedule

private struct ImportStep: View {
    var model: OnboardingViewModel

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {

                // Back
                Button {
                    withAnimation { model.step = 0 }
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(DesignTokens.Colors.accent)
                        .padding()
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {

                        // Header
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            Text("Import your schedule")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(DesignTokens.Colors.primary)
                            Text("Take a photo of your printed schedule, or send a screenshot or PDF from Aspen.")
                                .font(.body)
                                .foregroundStyle(DesignTokens.Colors.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, DesignTokens.Spacing.lg)

                        // Primary import options
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            ImportOptionButton(
                                icon: "camera.fill",
                                title: "Take a photo",
                                subtitle: "Point your camera at your printed schedule"
                            ) {
                                model.showImagePicker = true
                            }

                            ImportOptionButton(
                                icon: "photo.on.rectangle.angled",
                                title: "Choose a screenshot or PDF",
                                subtitle: "From your Photos or Files"
                            ) {
                                model.showDocumentPicker = true
                            }
                        }
                        .padding(.horizontal, DesignTokens.Spacing.lg)

                        // Manual entry fallback
                        VStack(spacing: DesignTokens.Spacing.xs) {
                            Divider()
                                .padding(.horizontal, DesignTokens.Spacing.lg)
                            Button {
                                withAnimation { model.step = 2 }
                            } label: {
                                Text("Enter manually instead")
                                    .font(.subheadline)
                                    .foregroundStyle(DesignTokens.Colors.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DesignTokens.Spacing.md)
                            }
                        }
                    }
                    .padding(.top, DesignTokens.Spacing.md)
                    .padding(.bottom, DesignTokens.Spacing.xxxl)
                }
            }
        }
    }
}

private struct ImportOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DesignTokens.Colors.accent)
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(DesignTokens.Colors.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(DesignTokens.Colors.secondary)
                    .font(.caption)
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 2: Manual entry (A–H)

private struct ManualEntryStep: View {
    var model: OnboardingViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if model.importFailed {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.orange)
                        Text("We couldn't read your schedule automatically. Fill in what you know — you can always edit later.")
                            .font(.caption)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(DesignTokens.Spacing.md)
                    .background(Color.orange.opacity(0.1))
                } else {
                    Text("Enter your courses for each block. Not all blocks meet every day.")
                        .font(.subheadline)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                }

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
                    withAnimation { model.step = 3 }
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
                        withAnimation {
                            model.importFailed = false
                            model.step = 1
                        }
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

// MARK: - Step 3: Done

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
                    Task {
                        await NotificationScheduler.shared.requestPermission()
                        NotificationScheduler.shared.scheduleAll()
                    }
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

// MARK: - Analyzing overlay

private struct AnalyzingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: DesignTokens.Spacing.md) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.4)
                Text("Reading your schedule…")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(DesignTokens.Spacing.xl)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

// MARK: - Image picker (UIImagePickerController wrapper)

private struct ImagePickerSheet: UIViewControllerRepresentable {
    let onImage: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImage: (UIImage?) -> Void
        init(onImage: @escaping (UIImage?) -> Void) { self.onImage = onImage }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            onImage(info[.originalImage] as? UIImage)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImage(nil)
        }
    }
}

// MARK: - Document picker (PDF / image files)

private struct DocumentPickerSheet: UIViewControllerRepresentable {
    let onPick: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.pdf, .image, .jpeg, .png, .heic]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: () -> Void
        init(onPick: @escaping () -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick()
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    }
}

#Preview("Welcome") {
    OnboardingView()
}
