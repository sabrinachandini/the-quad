import SwiftUI

/// Per-course accent colors. Each course keeps a stable, high-contrast color
/// across the whole app for instant recognition. See docs/DESIGN_SYSTEM.md.
enum CourseColors {

    /// 8 distinct accent colors, high-contrast in both light and dark mode.
    static let palette: [Color] = [
        Color(red: 0.35, green: 0.34, blue: 0.84), // indigo
        Color(red: 0.95, green: 0.46, blue: 0.21), // orange
        Color(red: 0.18, green: 0.68, blue: 0.53), // teal
        Color(red: 0.85, green: 0.27, blue: 0.51), // magenta
        Color(red: 0.20, green: 0.55, blue: 0.90), // blue
        Color(red: 0.55, green: 0.44, blue: 0.90), // violet
        Color(red: 0.90, green: 0.70, blue: 0.20), // amber
        Color(red: 0.30, green: 0.72, blue: 0.35)  // green
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
