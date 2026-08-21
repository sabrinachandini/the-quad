import SwiftUI

struct AspenConnectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var aspenProvider = AspenGradeProvider.shared

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {

                        // MARK: - Header
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            HStack(spacing: DesignTokens.Spacing.md) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(DesignTokens.Colors.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Aspen Grades")
                                        .font(DesignTokens.Typography.quadTitle)
                                        .foregroundStyle(DesignTokens.Colors.primary)
                                    Text("Live grade sync")
                                        .font(DesignTokens.Typography.quadCaption)
                                        .foregroundStyle(DesignTokens.Colors.secondary)
                                }
                            }

                            stateStatusRow
                        }

                        // MARK: - Form
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            Text("Sign in with your Aspen ID")
                                .font(DesignTokens.Typography.quadHeadline.weight(.semibold))
                                .foregroundStyle(DesignTokens.Colors.primary)

                            // Username field
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                Text("Aspen ID")
                                    .font(DesignTokens.Typography.quadCaption.weight(.medium))
                                    .foregroundStyle(DesignTokens.Colors.secondary)
                                TextField("Student ID (e.g. s12345678)", text: $username)
                                    .textContentType(.username)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .padding(DesignTokens.Spacing.md)
                                    .background(DesignTokens.Colors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
                                    .disabled(isLoading)
                            }

                            // Password field
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                Text("Password")
                                    .font(DesignTokens.Typography.quadCaption.weight(.medium))
                                    .foregroundStyle(DesignTokens.Colors.secondary)
                                HStack {
                                    if showPassword {
                                        TextField("Password", text: $password)
                                            .textContentType(.password)
                                            .autocorrectionDisabled()
                                            .textInputAutocapitalization(.never)
                                    } else {
                                        SecureField("Password", text: $password)
                                            .textContentType(.password)
                                    }
                                    Button {
                                        showPassword.toggle()
                                    } label: {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .foregroundStyle(DesignTokens.Colors.secondary)
                                            .font(.system(size: 16))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(DesignTokens.Spacing.md)
                                .background(DesignTokens.Colors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
                                .disabled(isLoading)
                            }

                            // Connect button
                            Button {
                                connect()
                            } label: {
                                HStack {
                                    Spacer()
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                            .scaleEffect(0.9)
                                        Text("Connecting…")
                                            .font(DesignTokens.Typography.quadBody.weight(.semibold))
                                            .foregroundStyle(.white)
                                    } else {
                                        Text("Connect to Aspen")
                                            .font(DesignTokens.Typography.quadBody.weight(.semibold))
                                            .foregroundStyle(.white)
                                    }
                                    Spacer()
                                }
                                .padding(DesignTokens.Spacing.md)
                                .background(canConnect ? DesignTokens.Colors.accent : DesignTokens.Colors.accent.opacity(0.4))
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
                            }
                            .disabled(!canConnect)
                            .animation(.easeInOut(duration: 0.2), value: canConnect)

                            // Privacy disclosure
                            HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(DesignTokens.Colors.secondary)
                                    .padding(.top, 1)
                                Text("Your Aspen ID and password are encrypted and stored only on this iPhone. They are never sent to The Quad's servers.")
                                    .font(DesignTokens.Typography.quadCaption)
                                    .foregroundStyle(DesignTokens.Colors.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(DesignTokens.Spacing.md)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
                        }
                        .padding(DesignTokens.Spacing.lg)
                        .background(DesignTokens.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))

                        Spacer(minLength: DesignTokens.Spacing.xxxl)
                    }
                    .padding(DesignTokens.Spacing.lg)
                }
            }
            .navigationTitle("Connect Aspen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DesignTokens.Colors.accent)
                        .disabled(isLoading)
                }
            }
            .onChange(of: aspenProvider.connectionState) { _, newState in
                if case .connected = newState {
                    dismiss()
                }
            }
        }
    }

    // MARK: - State Subviews

    @ViewBuilder
    private var stateStatusRow: some View {
        switch aspenProvider.connectionState {
        case .connecting:
            HStack(spacing: DesignTokens.Spacing.sm) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Connecting to Aspen…")
                    .font(DesignTokens.Typography.quadCaption.weight(.medium))
                    .foregroundStyle(DesignTokens.Colors.secondary)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))

        case .failed(let message):
            HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                Text(message)
                    .font(DesignTokens.Typography.quadCaption.weight(.medium))
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(Color.red.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))

        case .sessionExpired:
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundStyle(.orange)
                Text("Session expired — please sign in again.")
                    .font(DesignTokens.Typography.quadCaption.weight(.medium))
                    .foregroundStyle(.orange)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(Color.orange.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))

        default:
            EmptyView()
        }
    }

    // MARK: - Helpers

    private var isLoading: Bool {
        aspenProvider.connectionState == .connecting
    }

    private var canConnect: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        !isLoading
    }

    private func connect() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsername.isEmpty, !password.isEmpty else { return }
        Task {
            await aspenProvider.connect(username: trimmedUsername, password: password)
        }
    }
}

#Preview {
    AspenConnectView()
        .preferredColorScheme(.dark)
}
