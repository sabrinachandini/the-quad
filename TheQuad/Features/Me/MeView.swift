import SwiftUI

struct MeView: View {
    @State private var model = MeViewModel()

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                    profile

                    group(title: "Integrations") {
                        ForEach(model.integrations) { conn in
                            integrationRow(conn)
                        }
                    }

                    group(title: "Notifications") {
                        Toggle(isOn: $model.notifications.classChangeRemindersEnabled) {
                            Text("Class change reminders")
                                .font(DesignTokens.Typography.quadBody)
                                .foregroundStyle(DesignTokens.Colors.primary)
                        }
                        Toggle(isOn: $model.notifications.assignmentDueRemindersEnabled) {
                            Text("Assignment due reminders")
                                .font(DesignTokens.Typography.quadBody)
                                .foregroundStyle(DesignTokens.Colors.primary)
                        }
                    }
                    .tint(DesignTokens.Colors.accent)

                    group(title: "School Year") {
                        HStack {
                            Text("Current year")
                                .font(DesignTokens.Typography.quadBody)
                                .foregroundStyle(DesignTokens.Colors.primary)
                            Spacer()
                            Text(model.schoolYear)
                                .font(DesignTokens.Typography.quadBody.weight(.semibold))
                                .foregroundStyle(DesignTokens.Colors.accent)
                        }
                    }
                }
                .padding(DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.xxxl)
            }
        }
    }

    private var profile: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("Me")
                .font(DesignTokens.Typography.quadTitle)
                .foregroundStyle(DesignTokens.Colors.primary)
            Text(model.displayName)
                .font(DesignTokens.Typography.quadHeadline)
                .foregroundStyle(DesignTokens.Colors.primary)
            Text("Grade \(model.gradeLevel) · LHS")
                .font(DesignTokens.Typography.quadBody)
                .foregroundStyle(DesignTokens.Colors.secondary)
        }
    }

    private func integrationRow(_ conn: IntegrationConnection) -> some View {
        HStack {
            Text(model.label(for: conn.provider))
                .font(DesignTokens.Typography.quadBody)
                .foregroundStyle(DesignTokens.Colors.primary)
            Spacer()
            Text(conn.isConnected ? "Connected" : "Not Connected")
                .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                .foregroundStyle(conn.isConnected ? DesignTokens.Colors.accent : DesignTokens.Colors.secondary)
        }
    }

    @ViewBuilder
    private func group<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(title)
                .font(DesignTokens.Typography.quadHeadline)
                .foregroundStyle(DesignTokens.Colors.primary)
            VStack(spacing: DesignTokens.Spacing.md) {
                content()
            }
            .padding(DesignTokens.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
        }
    }
}

#Preview {
    MeView().preferredColorScheme(.dark)
}
