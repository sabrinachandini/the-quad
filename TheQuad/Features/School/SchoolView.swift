import SwiftUI

struct SchoolView: View {
    @State private var model = SchoolViewModel()

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                    Text("School")
                        .font(DesignTokens.Typography.quadTitle)
                        .foregroundStyle(DesignTokens.Colors.primary)

                    section(icon: "person.2.fill", title: "Directory",
                            detail: "Find classmates across LHS.")
                    section(icon: "book.closed.fill", title: "Classmates",
                            detail: "See who shares your blocks.")
                    section(icon: "heart.fill", title: "Friends",
                            detail: "Mutual approval required. No feed, no DMs, no location.")

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Free-block overlap")
                            .font(DesignTokens.Typography.quadHeadline)
                            .foregroundStyle(DesignTokens.Colors.primary)
                        Text("When you're free, see which friends are free too — availability only, never location. Opt-in.")
                            .font(DesignTokens.Typography.quadBody)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignTokens.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))

                    Label("Coming in Phase 7.", systemImage: "clock.badge")
                        .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                        .foregroundStyle(DesignTokens.Colors.accent)
                }
                .padding(DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.xxxl)
            }
        }
    }

    private func section(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(DesignTokens.Colors.accent)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignTokens.Typography.quadBody.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.primary)
                Text(detail)
                    .font(DesignTokens.Typography.quadCaption)
                    .foregroundStyle(DesignTokens.Colors.secondary)
            }
            Spacer()
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
    }
}

#Preview {
    SchoolView().preferredColorScheme(.dark)
}
