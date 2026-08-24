import SwiftUI

/// Per-course accent colors. Each course keeps a stable, high-contrast color
/// across the whole app for instant recognition. See docs/DESIGN_SYSTEM.md.
enum CourseColors {

    /// 8 distinct accent colors, high-contrast in both light and dark mode.
    static let palette: [Color] = [
        Color(light: Color(hex: "#4B48CC"), dark: Color(hex: "#7573F0")), // indigo
        Color(light: Color(hex: "#E06818"), dark: Color(hex: "#F07830")), // orange
        Color(light: Color(hex: "#1A9B72"), dark: Color(hex: "#22C090")), // teal
        Color(light: Color(hex: "#C43578"), dark: Color(hex: "#E04E8C")), // magenta
        Color(light: Color(hex: "#2175D4"), dark: Color(hex: "#4090E8")), // blue
        Color(light: Color(hex: "#7250D8"), dark: Color(hex: "#9070F0")), // violet
        Color(light: Color(hex: "#C49010"), dark: Color(hex: "#E0AA20")), // amber
        Color(light: Color(hex: "#2EA048"), dark: Color(hex: "#40BC5C")), // green
    ]

    /// Color for a specific palette index (wraps around the palette).
    static func color(atIndex index: Int) -> Color {
        guard !palette.isEmpty else { return DesignTokens.Colors.accent }
        let i = ((index % palette.count) + palette.count) % palette.count
        return palette[i]
    }

    /// Deterministically assigns a color by block letter so a given block always
    /// gets the same hue even before a course is enrolled.
    static func color(for block: AcademicBlock) -> Color {
        let orderedBlocks = AcademicBlock.allCases
        let idx = orderedBlocks.firstIndex(of: block) ?? 0
        return color(atIndex: idx)
    }
}
