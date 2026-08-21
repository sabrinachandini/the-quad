import Foundation

// MARK: - Response Types

struct AskResponse {
    let question: String
    let answer: String
    let detail: String?
    let relatedData: AskData?
}

enum AskData {
    case schedule([CourseSession])
    case assignments([Assignment])
    case freeBlocks([AvailabilityInterval])
    case gradeInfo(CourseGrade, Double?)
    case friendOverlap(User, [AvailabilityInterval])
    case dayInfo(DayType?, String)
}

// MARK: - AskEngine

struct AskEngine {
    private let scheduleEngine: ScheduleEngine
    private let freeBlockEngine = FreeBlockEngine()

    init(scheduleEngine: ScheduleEngine = AppState.shared.scheduleEngine) {
        self.scheduleEngine = scheduleEngine
    }

    func answer(_ question: String) -> AskResponse {
        let q = question.lowercased().trimmingCharacters(in: .whitespaces)

        if matchesTomorrow(q) { return answerTomorrow(q) }
        if matchesFriendFree(q) { return answerFriendFree(q) }
        if matchesNextDay(q) { return answerNextDay(q) }
        if matchesDayType(q) { return answerDayType(q) }
        if matchesFreeBlocks(q) { return answerFreeBlocks(q) }
        if matchesMissing(q) { return answerMissing(q) }
        if matchesFinalNeeded(q) { return answerFinalNeeded(q) }
        if matchesDue(q) { return answerDue(q) }
        if matchesGrade(q) { return answerGrade(q) }
        if matchesToday(q) { return answerToday(q) }
        return fallback(q)
    }

    // MARK: - Matchers

    private func matchesToday(_ q: String) -> Bool {
        q.contains("today") || q.contains("class") || q.contains("schedule") || q.contains("have")
    }

    private func matchesTomorrow(_ q: String) -> Bool {
        q.contains("tomorrow")
    }

    private func matchesDayType(_ q: String) -> Bool {
        (q.contains("day") && (q.contains("what") || q.contains("which"))) || q.contains("rotation")
    }

    private func matchesFreeBlocks(_ q: String) -> Bool {
        q.contains("free") || q.contains("available") || q.contains("open")
    }

    private func matchesDue(_ q: String) -> Bool {
        q.contains("due") || q.contains("assignment") || q.contains("homework") || q.contains("work")
    }

    private func matchesMissing(_ q: String) -> Bool {
        q.contains("missing") || q.contains("overdue") || q.contains("late")
    }

    private func matchesGrade(_ q: String) -> Bool {
        q.contains("grade") || q.contains("gpa") || q.contains("doing") || q.contains("average")
    }

    private func matchesFinalNeeded(_ q: String) -> Bool {
        q.contains("final") || (q.contains("need") && q.contains("get")) || q.contains("need on")
    }

    private func matchesFriendFree(_ q: String) -> Bool {
        let friends = AppState.shared.friends
        let firstNames = friends.flatMap { $0.displayName.lowercased().components(separatedBy: " ").prefix(1) }
        return firstNames.contains(where: { q.contains($0) })
            && (q.contains("free") || q.contains("available"))
    }

    private func matchesNextDay(_ q: String) -> Bool {
        q.contains("next day") || q.contains("when is day") || (1...6).contains(where: { q.contains("day \($0)") && q.contains("next") })
    }

    // MARK: - Handlers

    private func answerToday(_ q: String) -> AskResponse {
        let today = Date()
        let sessions = scheduleEngine.studentMeetings(
            for: today,
            enrollments: AppState.shared.enrollments,
            courses: AppState.shared.courses
        )
        if sessions.isEmpty {
            let dt = scheduleEngine.dayType(for: today)
            return AskResponse(
                question: q,
                answer: dt == nil ? "No school today." : "It's a special schedule day with no regular classes.",
                detail: nil,
                relatedData: nil
            )
        }
        let label = dayLabel(for: today)
        let detail = sessions.map { "\($0.slot.block.rawValue) · \($0.course.name)" }.joined(separator: "\n")
        return AskResponse(
            question: q,
            answer: "You have \(sessions.count) class\(sessions.count == 1 ? "" : "es") today (\(label)).",
            detail: detail,
            relatedData: .schedule(sessions)
        )
    }

    private func answerTomorrow(_ q: String) -> AskResponse {
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else {
            return fallback(q)
        }
        let sessions = scheduleEngine.studentMeetings(
            for: tomorrow,
            enrollments: AppState.shared.enrollments,
            courses: AppState.shared.courses
        )
        if sessions.isEmpty {
            return AskResponse(question: q, answer: "No school tomorrow.", detail: nil, relatedData: nil)
        }
        let label = dayLabel(for: tomorrow)
        let detail = sessions.map { "\($0.slot.block.rawValue) · \($0.course.name)" }.joined(separator: "\n")
        return AskResponse(
            question: q,
            answer: "Tomorrow is \(label). You have \(sessions.count) class\(sessions.count == 1 ? "" : "es").",
            detail: detail,
            relatedData: .schedule(sessions)
        )
    }

    private func answerDayType(_ q: String) -> AskResponse {
        let today = Date()
        let dt = scheduleEngine.dayType(for: today)
        let label = dayLabel(for: today)
        return AskResponse(
            question: q,
            answer: "Today is \(label).",
            detail: nil,
            relatedData: .dayInfo(dt, label)
        )
    }

    private func answerNextDay(_ q: String) -> AskResponse {
        let today = Date()
        var targetDayType: DayType? = nil
        for n in 1...6 where q.contains("day \(n)") {
            targetDayType = DayType(rawValue: "day\(n)")
        }

        for offset in 1...30 {
            guard let date = Calendar.current.date(byAdding: .day, value: offset, to: today) else { continue }
            let dt = scheduleEngine.dayType(for: date)
            if let target = targetDayType {
                if dt == target {
                    let dayNum = (target.rotationIndex ?? 0) + 1
                    let dateStr = date.formatted(.dateTime.weekday(.wide).month().day())
                    return AskResponse(
                        question: q,
                        answer: "The next Day \(dayNum) is \(dateStr).",
                        detail: nil,
                        relatedData: .dayInfo(dt, date.formatted(.dateTime.weekday(.wide)))
                    )
                }
            } else if dt != nil {
                let dateStr = date.formatted(.dateTime.weekday(.wide).month().day())
                let label = dayLabel(for: date)
                return AskResponse(
                    question: q,
                    answer: "The next school day is \(dateStr) (\(label)).",
                    detail: nil,
                    relatedData: nil
                )
            }
        }
        return fallback(q)
    }

    private func answerFreeBlocks(_ q: String) -> AskResponse {
        let today = Date()
        let allSlots = scheduleEngine.meetings(for: today)
        let sessions = scheduleEngine.studentMeetings(
            for: today,
            enrollments: AppState.shared.enrollments,
            courses: AppState.shared.courses
        )
        let free = freeBlockEngine.freeBlocks(for: today, allSlots: allSlots, studentSessions: sessions)
        if free.isEmpty {
            return AskResponse(question: q, answer: "No free blocks today — you're fully scheduled.", detail: nil, relatedData: nil)
        }
        let formatted = free.map { formatInterval($0) }.joined(separator: "\n")
        return AskResponse(
            question: q,
            answer: "You have \(free.count) free block\(free.count == 1 ? "" : "s") today.",
            detail: formatted,
            relatedData: .freeBlocks(free)
        )
    }

    private func answerDue(_ q: String) -> AskResponse {
        let upcoming = AppState.shared.assignments
            .filter { !$0.isCompleted }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .prefix(5)
        if upcoming.isEmpty {
            return AskResponse(question: q, answer: "Nothing due — you're all caught up.", detail: nil, relatedData: nil)
        }
        let detail = upcoming.map { a -> String in
            let due = a.dueDate.map { $0.formatted(.dateTime.weekday(.abbreviated).month().day()) } ?? "No date"
            return "\(a.title) · \(due)"
        }.joined(separator: "\n")
        return AskResponse(
            question: q,
            answer: "You have \(upcoming.count) upcoming assignment\(upcoming.count == 1 ? "" : "s").",
            detail: detail,
            relatedData: .assignments(Array(upcoming))
        )
    }

    private func answerMissing(_ q: String) -> AskResponse {
        let now = Date()
        let missing = AppState.shared.assignments.filter { a in
            guard !a.isCompleted, let due = a.dueDate else { return false }
            return due < now
        }
        if missing.isEmpty {
            return AskResponse(question: q, answer: "No missing assignments — great job.", detail: nil, relatedData: nil)
        }
        let detail = missing.map { $0.title }.joined(separator: "\n")
        return AskResponse(
            question: q,
            answer: "\(missing.count) missing assignment\(missing.count == 1 ? "" : "s").",
            detail: detail,
            relatedData: .assignments(missing)
        )
    }

    private func answerGrade(_ q: String) -> AskResponse {
        let grades = AppState.shared.grades
        let courses = AppState.shared.courses

        // Look for a specific course mentioned in the question
        let matchedGrade = grades.first { grade in
            guard let course = courses.first(where: { $0.id == grade.courseId }) else { return false }
            let nameLower = course.name.lowercased()
            let firstName = nameLower.components(separatedBy: " ").first ?? nameLower
            return q.contains(nameLower) || q.contains(firstName)
        }

        if let match = matchedGrade {
            let pct = GradeEngine.overallPercentage(match)
            let letter = pct.map { GradeEngine.letterGrade(from: $0) } ?? "—"
            let pctStr = pct.map { String(format: "%.1f%%", $0) } ?? "—"
            let course = courses.first { $0.id == match.courseId }
            return AskResponse(
                question: q,
                answer: "\(course?.name ?? "That course"): \(letter) (\(pctStr))",
                detail: nil,
                relatedData: .gradeInfo(match, pct)
            )
        }

        // Overall summary
        let summary = grades.compactMap { grade -> String? in
            guard let course = courses.first(where: { $0.id == grade.courseId }),
                  let pct = GradeEngine.overallPercentage(grade) else { return nil }
            return "\(course.name): \(GradeEngine.letterGrade(from: pct)) (\(String(format: "%.1f", pct))%)"
        }.joined(separator: "\n")

        return AskResponse(
            question: q,
            answer: "Here are your current grades.",
            detail: summary.isEmpty ? nil : summary,
            relatedData: nil
        )
    }

    private func answerFinalNeeded(_ q: String) -> AskResponse {
        let targetMap: [(String, Double)] = [
            ("a+", 97), ("a-", 90), ("a", 93), ("b+", 87), ("b-", 80), ("b", 83),
            ("c+", 77), ("c-", 70), ("c", 73)
        ]
        var targetPct = 90.0
        for (letter, pct) in targetMap where q.contains(letter) {
            targetPct = pct
            break
        }

        let grades = AppState.shared.grades
        let courses = AppState.shared.courses

        let grade = grades.first(where: { g in
            guard let course = courses.first(where: { $0.id == g.courseId }) else { return false }
            let nameLower = course.name.lowercased()
            let firstName = nameLower.components(separatedBy: " ").first ?? nameLower
            return q.contains(nameLower) || q.contains(firstName)
        }) ?? grades.first

        guard let g = grade,
              let course = courses.first(where: { $0.id == g.courseId }),
              let result = GradeEngine.scoreNeededOnFinal(
                  currentGrade: g,
                  finalWeight: 0.20,
                  targetPercentage: targetPct
              ) else {
            return AskResponse(question: q, answer: "I need your grade data to calculate that.", detail: nil, relatedData: nil)
        }

        let achievable = result.isAchievable ? "" : " (not achievable — you'd need over 100%)"
        return AskResponse(
            question: q,
            answer: "You need \(String(format: "%.1f", result.score))% on the \(course.name) final to get \(GradeEngine.letterGrade(from: targetPct)).\(achievable)",
            detail: "Assuming the final is worth 20% of your grade.",
            relatedData: .gradeInfo(g, GradeEngine.overallPercentage(g))
        )
    }

    private func answerFriendFree(_ q: String) -> AskResponse {
        let friends = AppState.shared.friends
        guard let friend = friends.first(where: { user in
            let parts = user.displayName.lowercased().components(separatedBy: " ")
            return parts.contains(where: { q.contains($0) })
        }) else {
            return fallback(q)
        }

        let today = Date()
        let allSlots = scheduleEngine.meetings(for: today)

        let mySessions = scheduleEngine.studentMeetings(
            for: today,
            enrollments: AppState.shared.enrollments,
            courses: AppState.shared.courses
        )
        let myFree = freeBlockEngine.freeBlocks(for: today, allSlots: allSlots, studentSessions: mySessions)

        guard let theirCourses = AppState.shared.friendCourses[friend.id] else {
            return AskResponse(
                question: q,
                answer: "\(friend.displayName)'s schedule isn't available.",
                detail: nil,
                relatedData: nil
            )
        }

        let theirEnrollments = theirCourses.map {
            Enrollment(id: UUID(), studentId: friend.id, courseId: $0.id, schoolYear: "2025-26")
        }
        let theirSessions = scheduleEngine.studentMeetings(
            for: today,
            enrollments: theirEnrollments,
            courses: theirCourses
        )
        let theirFree = freeBlockEngine.freeBlocks(for: today, allSlots: allSlots, studentSessions: theirSessions)
        let shared = freeBlockEngine.sharedFreeBlocks(studentA: myFree, studentB: theirFree)

        if shared.isEmpty {
            return AskResponse(
                question: q,
                answer: "You and \(friend.displayName) have no shared free blocks today.",
                detail: nil,
                relatedData: .friendOverlap(friend, [])
            )
        }

        let formatted = shared.map { formatInterval($0) }.joined(separator: "\n")
        return AskResponse(
            question: q,
            answer: "You and \(friend.displayName) are both free during \(shared.count) block\(shared.count == 1 ? "" : "s") today.",
            detail: formatted,
            relatedData: .friendOverlap(friend, shared)
        )
    }

    private func fallback(_ q: String) -> AskResponse {
        AskResponse(
            question: q,
            answer: "I can answer questions about your schedule, grades, assignments, and free blocks.",
            detail: "Try: \"What classes do I have today?\", \"What's due this week?\", \"When are Maya and I both free?\"",
            relatedData: nil
        )
    }

    // MARK: - Helpers

    private func dayLabel(for date: Date) -> String {
        let weekday = date.formatted(.dateTime.weekday(.wide))
        if let dt = scheduleEngine.dayType(for: date), let n = dt.rotationIndex {
            return "\(weekday), Day \(n + 1)"
        }
        return weekday
    }

    private func formatInterval(_ interval: AvailabilityInterval) -> String {
        let start = interval.start.formatted(.dateTime.hour().minute())
        let end = interval.end.formatted(.dateTime.hour().minute())
        let mins = Int(interval.end.timeIntervalSince(interval.start) / 60)
        return "\(start)–\(end) · \(mins) min"
    }
}
