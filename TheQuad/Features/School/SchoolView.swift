import SwiftUI

// MARK: - Avatar helper

/// Circular initials avatar colored deterministically from the person's name.
struct InitialsAvatar: View {
    let name: String
    var size: CGFloat = 44

    private var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first.map { String($0.prefix(1)) } ?? ""
        let last = parts.dropFirst().first.map { String($0.prefix(1)) } ?? ""
        return (first + last).uppercased()
    }

    private var color: Color {
        let idx = abs(name.hashValue) % 8
        return CourseColors.color(atIndex: idx)
    }

    var body: some View {
        ZStack {
            Circle().fill(color).frame(width: size, height: size)
            Text(initials)
                .font(.system(size: size * 0.36, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - SchoolView

struct SchoolView: View {
    @State private var model = SchoolViewModel()
    @State private var showAddAlert = false
    @State private var addedName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.Colors.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                        // Pending requests
                        if !model.pendingRequests.isEmpty {
                            pendingSection
                        }

                        // Friends
                        friendsSection

                        // Classmates
                        classmatesSection

                        // Directory
                        directorySection
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .padding(.bottom, DesignTokens.Spacing.xxxl)
                }
            }
            .navigationTitle("School")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $model.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search directory")
            .alert("Friend request sent!", isPresented: $showAddAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("\(addedName) will be notified. You'll be friends once they accept.")
            }
        }
    }

    // MARK: - Pending requests

    private var pendingSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            sectionHeader(title: "Pending Requests", count: model.pendingRequests.count)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(model.pendingRequests) { user in
                        pendingCard(user)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func pendingCard(_ user: User) -> some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            InitialsAvatar(name: user.displayName, size: 52)
            Text(user.displayName)
                .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.primary)
                .lineLimit(1)
            HStack(spacing: DesignTokens.Spacing.sm) {
                Button {
                    model.acceptFriend(user)
                } label: {
                    Text("Accept")
                        .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                        .background(DesignTokens.Colors.accent)
                        .clipShape(Capsule())
                }
                Button {
                    model.declineFriend(user)
                } label: {
                    Text("Decline")
                        .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                        .foregroundStyle(DesignTokens.Colors.secondary)
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                        .background(DesignTokens.Colors.surface)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
        .frame(width: 160)
    }

    // MARK: - Friends

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            sectionHeader(title: "Friends", count: model.friends.count)
            if model.friends.isEmpty {
                emptyHint("Search the directory and add friends to see free-block overlap.")
            } else {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(model.friends) { friend in
                        NavigationLink(destination: FriendDetailView(friend: friend, model: model)) {
                            friendRow(friend)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func friendRow(_ friend: User) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            InitialsAvatar(name: friend.displayName)
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.displayName)
                    .font(DesignTokens.Typography.quadBody.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.primary)
                Text(classOfLabel(friend.graduationYear))
                    .font(DesignTokens.Typography.quadCaption)
                    .foregroundStyle(DesignTokens.Colors.secondary)
            }
            Spacer()
            if let label = model.freeOverlapLabel(for: friend) {
                Text(label)
                    .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.accent)
                    .multilineTextAlignment(.trailing)
            }
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(DesignTokens.Colors.secondary.opacity(0.5))
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
    }

    // MARK: - Classmates

    private var classmatesSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            sectionHeader(title: "Classmates", count: model.classmates.count)
            if model.classmates.isEmpty {
                emptyHint("No classmates in The Quad yet — share with friends to see them here.")
            } else {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(model.classmates) { user in
                        NavigationLink(destination: FriendDetailView(friend: user, model: model)) {
                            classmateRow(user)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func classmateRow(_ user: User) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            InitialsAvatar(name: user.displayName, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(DesignTokens.Typography.quadBody)
                    .foregroundStyle(DesignTokens.Colors.primary)
                let blocks = model.sharedBlocks(with: user)
                if !blocks.isEmpty {
                    let blockStr = blocks.map { "\($0.rawValue) Block" }.joined(separator: ", ")
                    Text(blockStr)
                        .font(DesignTokens.Typography.quadCaption)
                        .foregroundStyle(DesignTokens.Colors.accent)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(DesignTokens.Colors.secondary.opacity(0.5))
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
    }

    // MARK: - Directory

    private var directorySection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            sectionHeader(title: "Directory", count: model.filteredDirectory.count)
            VStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(model.filteredDirectory) { user in
                    directoryRow(user)
                }
            }
        }
    }

    private func directoryRow(_ user: User) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            InitialsAvatar(name: user.displayName, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(DesignTokens.Typography.quadBody)
                    .foregroundStyle(DesignTokens.Colors.primary)
                Text(classOfLabel(user.graduationYear))
                    .font(DesignTokens.Typography.quadCaption)
                    .foregroundStyle(DesignTokens.Colors.secondary)
            }
            Spacer()
            Button {
                addedName = user.displayName
                showAddAlert = true
            } label: {
                Text("Add")
                    .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.accent)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background(DesignTokens.Colors.accent.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
    }

    // MARK: - Shared helpers

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(DesignTokens.Typography.quadHeadline.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.primary)
            Spacer()
            Text("\(count)")
                .font(DesignTokens.Typography.quadCaption.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.secondary)
        }
    }

    private func emptyHint(_ text: String) -> some View {
        Text(text)
            .font(DesignTokens.Typography.quadCaption)
            .foregroundStyle(DesignTokens.Colors.secondary)
            .padding(DesignTokens.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
    }

    private func classOfLabel(_ year: Int) -> String {
        let twoDigit = year % 100
        return "Class of '\(String(format: "%02d", twoDigit))"
    }
}

// MARK: - FriendDetailView

struct FriendDetailView: View {
    let friend: User
    let model: SchoolViewModel

    private func classOfLabel(_ year: Int) -> String {
        let twoDigit = year % 100
        return "Class of '\(String(format: "%02d", twoDigit))"
    }

    private func formatInterval(_ interval: AvailabilityInterval) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm"
        let startStr = fmt.string(from: interval.start)
        fmt.dateFormat = "h:mm a"
        let endStr = fmt.string(from: interval.end)
        return "\(startStr) – \(endStr) · \(interval.durationMinutes) min"
    }

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                    // Header
                    HStack(spacing: DesignTokens.Spacing.lg) {
                        InitialsAvatar(name: friend.displayName, size: 72)
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            Text(friend.displayName)
                                .font(DesignTokens.Typography.quadTitle)
                                .foregroundStyle(DesignTokens.Colors.primary)
                            Text(classOfLabel(friend.graduationYear))
                                .font(DesignTokens.Typography.quadBody)
                                .foregroundStyle(DesignTokens.Colors.secondary)
                        }
                        Spacer()
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .background(DesignTokens.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.extraLarge))

                    // Shared free time today
                    detailSection(title: "Shared Free Time Today", icon: "clock.badge.checkmark") {
                        let shared = model.sharedFreeBlocks(with: friend)
                        if shared.isEmpty {
                            Text("No shared free blocks today.")
                                .font(DesignTokens.Typography.quadBody)
                                .foregroundStyle(DesignTokens.Colors.secondary)
                        } else {
                            ForEach(shared) { interval in
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundStyle(DesignTokens.Colors.accent)
                                        .frame(width: 20)
                                    Text(formatInterval(interval))
                                        .font(DesignTokens.Typography.quadBody)
                                        .foregroundStyle(DesignTokens.Colors.primary)
                                    Spacer()
                                }
                            }
                        }
                    }

                    // Classes together (if they share block info)
                    if friend.showClassesInDirectory {
                        let shared = model.sharedBlocks(with: friend)
                        if !shared.isEmpty {
                            detailSection(title: "Classes Together", icon: "book.fill") {
                                ForEach(shared, id: \.self) { block in
                                    HStack {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(CourseColors.color(for: block))
                                                .frame(width: 28, height: 28)
                                            Text(block.rawValue)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                        Text("\(block.rawValue) Block")
                                            .font(DesignTokens.Typography.quadBody)
                                            .foregroundStyle(DesignTokens.Colors.primary)
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.xxxl)
            }
        }
        .navigationTitle(friend.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func detailSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Label(title, systemImage: icon)
                .font(DesignTokens.Typography.quadHeadline.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.primary)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                content()
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
    }
}

#Preview {
    SchoolView().preferredColorScheme(.dark)
}
