import SwiftUI

/// Central design tokens for The Quad. All views must use these — never hardcode
/// colors, spacing, or radii. See docs/DESIGN_SYSTEM.md.
enum DesignTokens {

    // MARK: - Colors (adaptive light / true-black dark)
    enum Colors {
        static let background = Color(
            light: Color(red: 0.96, green: 0.96, blue: 0.97),
            dark: .black // true black #000000
        )
        static let surface = Color(
            light: .white,
            dark: Color(red: 0.09, green: 0.09, blue: 0.10)
        )
        static let primary = Color(
            light: Color(red: 0.05, green: 0.05, blue: 0.07),
            dark: .white
        )
        static let secondary = Color(
            light: Color(red: 0.42, green: 0.42, blue: 0.45),
            dark: Color(red: 0.62, green: 0.62, blue: 0.66)
        )
        static let accent = Color(
            light: Color(red: 0.35, green: 0.34, blue: 0.84),   // indigo
            dark: Color(red: 0.46, green: 0.45, blue: 0.95)
        )
        static let destructive = Color(
            light: Color(red: 0.85, green: 0.19, blue: 0.19),
            dark: Color(red: 1.0, green: 0.36, blue: 0.34)
        )
    }

    // MARK: - Typography
    enum Typography {
        static let quadTitle = Font.system(size: 34, weight: .bold, design: .default)
        static let quadHeadline = Font.system(size: 22, weight: .semibold, design: .default)
        static let quadBody = Font.system(size: 17, weight: .regular, design: .default)
        static let quadCaption = Font.system(size: 13, weight: .regular, design: .default)
    }

    // MARK: - Spacing (4pt grid)
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }

    // MARK: - Animation
    enum Animations {
        static let standard: Animation = .spring(response: 0.3, dampingFraction: 0.8)
    }
}

// MARK: - Adaptive Color helper
extension Color {
    /// Creates a color that resolves differently in light vs dark mode.
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}
