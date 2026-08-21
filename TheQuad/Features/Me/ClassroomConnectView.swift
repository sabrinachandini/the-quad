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
            Text("School Account Restriction")
                .font(.title3.bold())
            Text("Your LHS Google account doesn't allow third-party app connections.")
                .multilineTextAlignment(.center)
            Text("This is a Lexington Public Schools policy — not a bug in The Quad.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Divider()
            Text("You can still use The Quad without Classroom sync.\nAdd assignments manually using the + button in Work.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
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
