import Foundation

// MARK: - Errors

enum AspenParseError: Error, LocalizedError {
    case loginPageReturned
    case noCoursesFound
    case structureChanged(String)

    var errorDescription: String? {
        switch self {
        case .loginPageReturned:
            return "Aspen returned the login page — session may have expired."
        case .noCoursesFound:
            return "No courses found in the Aspen grade list."
        case .structureChanged(let detail):
            return "Aspen HTML structure has changed and could not be parsed: \(detail)"
        }
    }
}

// MARK: - Data Types

struct AspenCourseSummary {
    let oid: String
    let name: String
    let teacher: String?
    let termGradePercent: Double?
    let termGradeLetter: String?
}

// MARK: - Parser

struct AspenHTMLParser {

    // MARK: - Validation

    static func isLoginPage(_ html: String) -> Bool {
        let loginSignals = [
            "logon.do",
            "id=\"logonForm\"",
            "name=\"username\"",
            "name=\"password\"",
            "Aspen Student Portal",
            // New Angular SPA login page markers
            "aspen-login",
            "app/rest/auth",
            "app-root",
        ]
        let lower = html.lowercased()
        // Classic portal: has a password field
        // Angular SPA: has aspen-login route or app-root (Angular bootstrap tag)
        let hasClassicLogin = loginSignals.prefix(5).contains { lower.contains($0.lowercased()) } && lower.contains("password")
        let hasAngularLogin = loginSignals.suffix(3).contains { lower.contains($0.lowercased()) }
        return hasClassicLogin || hasAngularLogin
    }

    static func isErrorPage(_ html: String) -> Bool {
        let errorSignals = [
            "An error has occurred",
            "errorMessageStyle",
            "class=\"error\"",
            "Access Denied",
            "403 Forbidden",
        ]
        return errorSignals.contains { html.contains($0) }
    }

    // MARK: - Course List

    /// Parse the Aspen portal class list page.
    /// Extracts course name, teacher, numeric grade, letter grade, and OID.
    static func parseCourseList(html: String) throws -> [AspenCourseSummary] {
        guard !isLoginPage(html) else {
            throw AspenParseError.loginPageReturned
        }

        // Aspen X2/X3 renders a table with id="dataGrid" or class="listTable"
        // Rows contain <tr> elements with <td> cells.
        // We extract table rows from the grade table region.

        // Find the main data table
        guard let tableRange = findTableRange(in: html) else {
            throw AspenParseError.structureChanged("Could not locate grade table in HTML")
        }

        let tableHTML = String(html[tableRange])
        let rows = extractTableRows(from: tableHTML)

        // Skip header row(s)
        let dataRows = rows.filter { row in
            let lower = row.lowercased()
            return !lower.contains("<th") &&
                   !lower.contains("class=\"listHeader\"") &&
                   !lower.contains("class=\"header\"") &&
                   row.contains("<td")
        }

        guard !dataRows.isEmpty else {
            throw AspenParseError.noCoursesFound
        }

        var courses: [AspenCourseSummary] = []

        for row in dataRows {
            guard let course = parseCourseRow(row) else { continue }
            courses.append(course)
        }

        if courses.isEmpty {
            throw AspenParseError.noCoursesFound
        }

        return courses
    }

    // MARK: - Course Detail

    /// Parse the course detail page to extract grade categories and entries.
    static func parseCourseDetail(html: String, courseName: String) throws -> [GradeCategory] {
        guard !isLoginPage(html) else {
            throw AspenParseError.loginPageReturned
        }

        // Aspen course detail shows assignment categories as separate tables
        // Each table starts with a category header
        let categoryBlocks = extractCategoryBlocks(from: html)

        if categoryBlocks.isEmpty {
            // No assignments yet — return a single empty category rather than erroring
            return [GradeCategory(
                id: UUID(),
                name: "Assignments",
                weight: 1.0,
                entries: []
            )]
        }

        var categories: [GradeCategory] = []

        for block in categoryBlocks {
            let category = parseCategoryBlock(block)
            categories.append(category)
        }

        return categories
    }

    // MARK: - Private: Table Parsing

    private static func findTableRange(in html: String) -> Range<String.Index>? {
        // Step 1: look for grade table by known Aspen identifier patterns
        let tablePatterns = [
            "id=\"dataGrid\"",
            "class=\"listTable\"",
            "id=\"classListTable\"",
            "portalClassList",
            "class=\"dataGrid\"",
            "class=\"portalGrid\"",
        ]

        for pattern in tablePatterns {
            if let patternRange = html.range(of: pattern, options: .caseInsensitive) {
                let searchBack = html[html.startIndex..<patternRange.lowerBound]
                if let tableStart = searchBack.range(of: "<table", options: [.caseInsensitive, .backwards]) {
                    let searchForward = html[patternRange.upperBound...]
                    if let tableEnd = searchForward.range(of: "</table>", options: .caseInsensitive) {
                        return tableStart.lowerBound..<tableEnd.upperBound
                    }
                }
            }
        }

        // Step 2: collect ALL <table>…</table> blocks and pick the one with the most <td> cells
        // This handles Aspen deployments that don't use the standard identifiers above.
        var allTables: [(range: Range<String.Index>, tdCount: Int)] = []
        var search = html.startIndex

        while search < html.endIndex,
              let tableStart = html.range(of: "<table", options: .caseInsensitive, range: search..<html.endIndex) {
            // Find the matching </table> (non-nested; good enough for Aspen's flat structure)
            if let tableEnd = html.range(of: "</table>", options: .caseInsensitive,
                                          range: tableStart.upperBound..<html.endIndex) {
                let tableHTML = String(html[tableStart.lowerBound..<tableEnd.upperBound])
                let tdCount = tableHTML.components(separatedBy: "<td").count - 1
                if tdCount > 0 {
                    allTables.append((range: tableStart.lowerBound..<tableEnd.upperBound, tdCount: tdCount))
                }
                search = tableEnd.upperBound
            } else {
                break
            }
        }

        // Pick the largest table (most <td> cells) — the grade list table is typically the biggest
        return allTables.max(by: { $0.tdCount < $1.tdCount })?.range
    }

    private static func extractTableRows(from html: String) -> [String] {
        var rows: [String] = []
        var search = html.startIndex

        while search < html.endIndex,
              let rowStart = html.range(of: "<tr", options: .caseInsensitive, range: search..<html.endIndex) {
            let afterOpen = rowStart.upperBound
            if let rowEnd = html.range(of: "</tr>", options: .caseInsensitive,
                                        range: afterOpen..<html.endIndex) {
                let rowContent = String(html[rowStart.lowerBound..<rowEnd.upperBound])
                rows.append(rowContent)
                search = rowEnd.upperBound
            } else {
                break
            }
        }

        return rows
    }

    private static func extractCells(from row: String) -> [String] {
        var cells: [String] = []
        var search = row.startIndex

        while search < row.endIndex,
              let cellStart = row.range(of: "<td", options: .caseInsensitive, range: search..<row.endIndex) {
            let afterOpen = cellStart.upperBound
            if let cellEnd = row.range(of: "</td>", options: .caseInsensitive,
                                        range: afterOpen..<row.endIndex) {
                let cellContent = String(row[cellStart.lowerBound..<cellEnd.upperBound])
                cells.append(stripHTML(cellContent))
                search = cellEnd.upperBound
            } else {
                break
            }
        }

        return cells
    }

    // MARK: - Private: Course Row Parsing

    private static func parseCourseRow(_ row: String) -> AspenCourseSummary? {
        let cells = extractCells(from: row)
        guard cells.count >= 2 else { return nil }

        // Extract OID from href in the row
        let oid = extractOID(from: row) ?? UUID().uuidString

        // Aspen typically: Course Name | Teacher | Term Grade | Letter Grade | ...
        // Cell positions vary by district config. We try positional then fallback.
        let name = cells[0].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        let teacher = cells.count > 1 ? nilIfEmpty(cells[1]) : nil
        let gradeString = cells.count > 2 ? cells[2].trimmingCharacters(in: .whitespacesAndNewlines) : ""
        let letterString = cells.count > 3 ? cells[3].trimmingCharacters(in: .whitespacesAndNewlines) : ""

        let termGradePercent = parseGradePercent(from: gradeString)
        let termGradeLetter = nilIfEmpty(letterString.components(separatedBy: .whitespaces).first ?? "")

        return AspenCourseSummary(
            oid: oid,
            name: name,
            teacher: teacher,
            termGradePercent: termGradePercent,
            termGradeLetter: termGradeLetter
        )
    }

    private static func extractOID(from html: String) -> String? {
        // Links look like: href="...?oid=XXXXXXXXXX..." or oid=XXXXXXXXXX
        let pattern = "oid=([A-Za-z0-9_\\-]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        if let match = regex.firstMatch(in: html, options: [], range: range),
           let oidRange = Range(match.range(at: 1), in: html) {
            return String(html[oidRange])
        }
        return nil
    }

    private static func parseGradePercent(from string: String) -> Double? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        // Handle formats: "89.5", "89.50%", "89"
        let cleaned = trimmed.replacingOccurrences(of: "%", with: "")
        return Double(cleaned)
    }

    // MARK: - Private: Category Parsing

    private static func extractCategoryBlocks(from html: String) -> [String] {
        var blocks: [String] = []

        // Aspen renders each grade category as a separate section, often in
        // divs with class="categoryHeader" or within separate table structures.
        // We split on category header markers.

        let categoryMarkers = [
            "class=\"categoryHeader\"",
            "class=\"gradeCategory\"",
            "id=\"categoryTable",
        ]

        for marker in categoryMarkers {
            if html.contains(marker) {
                blocks = splitOnMarker(html: html, marker: marker)
                if !blocks.isEmpty { return blocks }
            }
        }

        // Fallback: look for <h3> or <h4> category headings followed by tables
        blocks = extractBlocksByHeadings(from: html)
        return blocks
    }

    private static func splitOnMarker(html: String, marker: String) -> [String] {
        var blocks: [String] = []
        var ranges: [Range<String.Index>] = []
        var search = html.startIndex

        while search < html.endIndex,
              let found = html.range(of: marker, options: .caseInsensitive, range: search..<html.endIndex) {
            ranges.append(found)
            search = found.upperBound
        }

        for (i, range) in ranges.enumerated() {
            let blockStart = range.lowerBound
            let blockEnd = i + 1 < ranges.count ? ranges[i + 1].lowerBound : html.endIndex
            blocks.append(String(html[blockStart..<blockEnd]))
        }

        return blocks
    }

    private static func extractBlocksByHeadings(from html: String) -> [String] {
        var blocks: [String] = []
        var search = html.startIndex

        // Look for heading tags that might delimit categories
        let headingTags = ["<h3", "<h4", "<h2"]
        for tag in headingTags {
            search = html.startIndex
            var ranges: [Range<String.Index>] = []

            while search < html.endIndex,
                  let found = html.range(of: tag, options: .caseInsensitive, range: search..<html.endIndex) {
                ranges.append(found)
                search = found.upperBound
            }

            if !ranges.isEmpty {
                for (i, range) in ranges.enumerated() {
                    let blockStart = range.lowerBound
                    let blockEnd = i + 1 < ranges.count ? ranges[i + 1].lowerBound : html.endIndex
                    blocks.append(String(html[blockStart..<blockEnd]))
                }
                return blocks
            }
        }

        return blocks
    }

    private static func parseCategoryBlock(_ block: String) -> GradeCategory {
        // Extract category name
        let categoryName = extractCategoryName(from: block) ?? "Assignments"

        // Extract weight if visible (e.g., "50%" or "Weight: 0.50")
        let weight = extractCategoryWeight(from: block) ?? 1.0

        // Extract assignment rows
        let rows = extractTableRows(from: block)
        var entries: [GradeEntry] = []

        for row in rows {
            let cells = extractCells(from: row)
            if let entry = parseAssignmentRow(cells: cells, rowHTML: row) {
                entries.append(entry)
            }
        }

        return GradeCategory(id: UUID(), name: categoryName, weight: weight, entries: entries)
    }

    private static func extractCategoryName(from block: String) -> String? {
        // Try heading tags first
        for tag in ["h3", "h4", "h2"] {
            if let text = extractTagContent(tag: tag, from: block), !text.isEmpty {
                let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleaned.isEmpty { return cleaned }
            }
        }
        // Try categoryHeader class content
        if let range = block.range(of: "categoryHeader", options: .caseInsensitive) {
            let after = String(block[range.upperBound...])
            if let text = extractNextTextContent(from: after) {
                return text
            }
        }
        return nil
    }

    private static func extractCategoryWeight(from block: String) -> Double? {
        // Look for patterns like "50%", "Weight: 0.50", "50.00%"
        let pattern = "(?:weight[:\\s]*)?([0-9]+(?:\\.[0-9]+)?)\\s*%"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let range = NSRange(block.startIndex..<block.endIndex, in: block)
        if let match = regex.firstMatch(in: block, options: [], range: range),
           let pctRange = Range(match.range(at: 1), in: block),
           let pct = Double(block[pctRange]) {
            return pct / 100.0
        }
        return nil
    }

    private static func parseAssignmentRow(cells: [String], rowHTML: String) -> GradeEntry? {
        guard cells.count >= 2 else { return nil }

        let title = cells[0].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty,
              !title.lowercased().contains("assignment"),  // skip header rows
              !title.lowercased().contains("category") else {
            return nil
        }

        let isMissing = rowHTML.lowercased().contains("missing") ||
                        cells.contains { $0.lowercased().contains("missing") }
        let isExempt  = rowHTML.lowercased().contains("exempt") ||
                        cells.contains { $0.lowercased().contains("exempt") }

        // Find score cell — look for "earned / possible" pattern or numeric values
        var pointsEarned: Double? = nil
        var pointsPossible: Double = 100.0

        for cell in cells.dropFirst() {
            let trimmed = cell.trimmingCharacters(in: .whitespacesAndNewlines)
            if let (earned, possible) = parseScoreCell(trimmed) {
                pointsEarned = earned
                pointsPossible = possible
                break
            }
        }

        // Parse date if present (last cell often has date)
        var date: Date? = nil
        if let lastCell = cells.last {
            date = parseDate(from: lastCell)
        }

        let isDropped = isExempt || (isMissing && pointsEarned == nil)

        return GradeEntry(
            id: UUID(),
            title: title,
            pointsEarned: isMissing ? nil : pointsEarned,
            pointsPossible: pointsPossible,
            isDropped: isDropped,
            date: date,
            provenance: .aspen
        )
    }

    private static func parseScoreCell(_ cell: String) -> (earned: Double, possible: Double)? {
        // Format: "94 / 100" or "94.00 / 100" or "94"
        let slashPattern = "([0-9]+(?:\\.[0-9]+)?)\\s*/\\s*([0-9]+(?:\\.[0-9]+)?)"
        if let regex = try? NSRegularExpression(pattern: slashPattern),
           let match = regex.firstMatch(in: cell, range: NSRange(cell.startIndex..., in: cell)),
           let earnedRange = Range(match.range(at: 1), in: cell),
           let possibleRange = Range(match.range(at: 2), in: cell),
           let earned = Double(cell[earnedRange]),
           let possible = Double(cell[possibleRange]) {
            return (earned: earned, possible: possible)
        }

        // Bare number — assume /100
        let trimmed = cell.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Double(trimmed), value >= 0 {
            return (earned: value, possible: 100.0)
        }

        return nil
    }

    private static func parseDate(from string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        let formatters = [
            "MM/dd/yyyy",
            "M/d/yyyy",
            "yyyy-MM-dd",
        ].map { format -> DateFormatter in
            let f = DateFormatter()
            f.dateFormat = format
            f.locale = Locale(identifier: "en_US_POSIX")
            return f
        }
        for formatter in formatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        return nil
    }

    // MARK: - HTML Utilities

    private static func stripHTML(_ html: String) -> String {
        var result = html
        // Remove all tags
        if let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: []) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
        }
        // Decode common HTML entities
        result = result
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func extractTagContent(tag: String, from html: String) -> String? {
        guard let openRange = html.range(of: "<\(tag)", options: .caseInsensitive),
              let closeTag = html.range(of: ">", range: openRange.upperBound..<html.endIndex),
              let endRange = html.range(of: "</\(tag)>", options: .caseInsensitive,
                                         range: closeTag.upperBound..<html.endIndex) else {
            return nil
        }
        return stripHTML(String(html[closeTag.upperBound..<endRange.lowerBound]))
    }

    private static func extractNextTextContent(from html: String) -> String? {
        guard let openAngle = html.range(of: ">"),
              let closeAngle = html.range(of: "<", range: openAngle.upperBound..<html.endIndex) else {
            return nil
        }
        let text = String(html[openAngle.upperBound..<closeAngle.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }

    private static func nilIfEmpty(_ string: String) -> String? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
