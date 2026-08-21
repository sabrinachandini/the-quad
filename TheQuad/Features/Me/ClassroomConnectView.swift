import SwiftUI

struct ClassroomConnectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var provider = ClassroomAuthProvider.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                content
                Spacer()
            }
            .padding()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onChange(of: provider.authState) { _, newState in
            if case .connected = newState { dismiss() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch provider.authState {
        case .notConfigured:
            notConfiguredView

        case .disconnected, .needsReauthorization:
            disconnectedView

        case .connecting:
            connectingView

        case .blockedBySchoolPolicy:
            blockedView

        case .connected:
            EmptyView()

        case .failed(let message):
            failedView(message: message)
        }
    }

    private var notConfiguredView: some View {
        VStack(spacing: 16) {
            Image(systemName: "gearshape.2")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Google Classroom")
                .font(.title2.bold())
            Text("Setup Required")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("The app needs to be registered with Google before connecting.\nSee Settings → Integrations → Classroom for setup instructions.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }

    private var disconnectedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "graduationcap.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(.blue)
            Text("Connect Google Classroom")
                .font(.title2.bold())
            Text("Sync assignments and due dates from your LHS courses automatically.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button {
                Task {
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let rootVC = windowScene.windows.first?.rootViewController else { return }
                    await provider.connect(from: rootVC)
                }
            } label: {
                HStack {
                    Image(systemName: "network")
                    Text("Connect with Google")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)

            Text("Your school email address is used to access your own coursework only.\nNot affiliated with Lexington Public Schools.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.tertiary)
        }
    }

    private var connectingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Connecting…")
                .foregroundStyle(.secondary)
        }
    }

    private var blockedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
            Text("Couldn't Connect to Classroom")
                .font(.title3.bold())
            VStack(alignment: .leading, spacing: 8) {
                Label("You cancelled sign-in", systemImage: "xmark.circle")
                    .foregroundStyle(.secondary)
                Label("Your school's Google Workspace blocks third-party apps", systemImage: "lock.shield")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .padding(.vertical, 4)

            Text("LPS has confirmed this restriction is a district policy.\nThe Quad can't override it.")
                .multilineTextAlignment(.center)
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            VStack(spacing: 6) {
                Text("You can still track all your work manually.")
                    .font(.subheadline.weight(.medium))
                Text("Use the + button in the Work tab to add assignments.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Try Again") {
                    Task {
                        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                              let rootVC = windowScene.windows.first?.rootViewController else { return }
                        await provider.connect(from: rootVC)
                    }
                }
                .buttonStyle(.bordered)

                Button("Got It") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.top, 4)
        }
    }

    private func failedView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.red)
            Text("Connection Failed")
                .font(.title3.bold())
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Retry") {
                Task {
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let rootVC = windowScene.windows.first?.rootViewController else { return }
                    await provider.connect(from: rootVC)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
