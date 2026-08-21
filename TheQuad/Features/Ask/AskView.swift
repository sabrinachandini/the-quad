import SwiftUI

struct AskView: View {
    @State private var viewModel = AskViewModel()
    @FocusState private var inputFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag handle
                dragHandle

                if viewModel.exchanges.isEmpty && !viewModel.isThinking {
                    // Empty state
                    emptyState
                } else {
                    // Conversation history
                    conversationScrollView
                }

                // Suggestion chips
                if viewModel.exchanges.isEmpty && !viewModel.isThinking {
                    suggestionChips
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            inputBar
        }
        .presentationDragIndicator(.hidden)
        .presentationDetents([.large])
        .presentationBackground(DesignTokens.Colors.background)
    }

    // MARK: - Drag Handle

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(DesignTokens.Colors.secondary.opacity(0.35))
            .frame(width: 36, height: 5)
            .padding(.top, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.sm)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()
            // "Q" logo
            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.accent)
                    .frame(width: 72, height: 72)
                Text("Q")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("Ask anything")
                    .font(DesignTokens.Typography.quadTitle)
                    .foregroundStyle(DesignTokens.Colors.primary)
                Text("About your schedule, grades, and work")
                    .font(DesignTokens.Typography.quadCaption)
                    .foregroundStyle(DesignTokens.Colors.secondary)
            }
            Spacer()
            suggestionChips
                .padding(.bottom, DesignTokens.Spacing.md)
        }
    }

    // MARK: - Suggestion Chips

    private var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(AskSuggestions.all, id: \.self) { suggestion in
                    Button {
                        viewModel.submitSuggestion(suggestion)
                        inputFocused = false
                    } label: {
                        Text(suggestion)
                            .font(DesignTokens.Typography.quadCaption.weight(.medium))
                            .foregroundStyle(DesignTokens.Colors.secondary)
                            .padding(.horizontal, DesignTokens.Spacing.md)
                            .padding(.vertical, DesignTokens.Spacing.sm)
                            .background(DesignTokens.Colors.surface)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
    }

    // MARK: - Conversation Scroll View

    private var conversationScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.lg) {
                    ForEach(viewModel.exchanges) { exchange in
                        exchangeView(exchange)
                            .id(exchange.id)
                    }
                    if viewModel.isThinking {
                        thinkingIndicator
                            .id("thinking")
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.vertical, DesignTokens.Spacing.md)
            }
            .onChange(of: viewModel.exchanges.count) {
                if let last = viewModel.exchanges.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isThinking) {
                if viewModel.isThinking {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("thinking", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Exchange View

    @ViewBuilder
    private func exchangeView(_ exchange: AskViewModel.Exchange) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Question — right aligned
            HStack {
                Spacer(minLength: 48)
                Text(exchange.question)
                    .font(DesignTokens.Typography.quadBody)
                    .foregroundStyle(.white)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(DesignTokens.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
            }

            // Answer — left aligned
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(exchange.response.answer)
                        .font(DesignTokens.Typography.quadBody)
                        .foregroundStyle(DesignTokens.Colors.primary)

                    if let detail = exchange.response.detail {
                        Text(detail)
                            .font(DesignTokens.Typography.quadCaption)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(DesignTokens.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
                Spacer(minLength: 48)
            }
        }
    }

    // MARK: - Thinking Indicator

    private var thinkingIndicator: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(DesignTokens.Colors.secondary.opacity(0.6))
                        .frame(width: 6, height: 6)
                        .scaleEffect(viewModel.isThinking ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.15),
                            value: viewModel.isThinking
                        )
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
            Spacer()
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(DesignTokens.Colors.secondary.opacity(0.15))

            HStack(spacing: DesignTokens.Spacing.sm) {
                TextField(
                    "Ask anything about your schedule, grades, or work...",
                    text: $viewModel.inputText,
                    axis: .vertical
                )
                .font(DesignTokens.Typography.quadBody)
                .foregroundStyle(DesignTokens.Colors.primary)
                .focused($inputFocused)
                .lineLimit(1...4)
                .onSubmit {
                    viewModel.submit()
                }

                Button {
                    viewModel.submit()
                    inputFocused = false
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? DesignTokens.Colors.secondary.opacity(0.3)
                                : DesignTokens.Colors.accent
                        )
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.md)
        }
        .background(DesignTokens.Colors.background)
    }
}

#Preview {
    AskView()
        .preferredColorScheme(.dark)
}
