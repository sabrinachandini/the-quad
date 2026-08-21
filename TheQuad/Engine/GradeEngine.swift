import Foundation

struct GradeEngine {

    // MARK: - Overall Percentage

    /// Weighted average: sum(category.weight * categoryAvg) / sum(weights of non-empty categories)
    static func overallPercentage(_ grade: CourseGrade) -> Double? {
        var weightedSum = 0.0
        var totalWeight = 0.0

        for category in grade.categories {
            guard let avg = categoryAverage(category) else { continue }
            weightedSum += category.weight * avg
            totalWeight += category.weight
        }

        guard totalWeight > 0 else { return nil }
        return weightedSum / totalWeight
    }

    /// Points-based average for a single category (sum earned / sum possible * 100)
    static func categoryAverage(_ category: GradeCategory) -> Double? {
        let gradedEntries = category.entries.filter { !$0.isDropped && $0.pointsEarned != nil }
        guard !gradedEntries.isEmpty else { return nil }
        let earned = gradedEntries.reduce(0.0) { $0 + $1.pointsEarned! }
        let possible = gradedEntries.reduce(0.0) { $0 + $1.pointsPossible }
        guard possible > 0 else { return nil }
        return (earned / possible) * 100.0
    }

    // MARK: - Letter Grade (LHS standard scale)

    static func letterGrade(from percentage: Double) -> String {
        switch percentage {
        case 93...:      return "A"
        case 90..<93:    return "A-"
        case 87..<90:    return "B+"
        case 83..<87:    return "B"
        case 80..<83:    return "B-"
        case 77..<80:    return "C+"
        case 73..<77:    return "C"
        case 70..<73:    return "C-"
        case 67..<70:    return "D+"
        case 60..<67:    return "D"
        default:         return "F"
        }
    }

    // MARK: - What-If: Score Needed in a Category

    /// What score is needed on a hypothetical assignment worth `pointsPossible` points
    /// to achieve a target overall percentage, given current grade state?
    /// Returns nil if target is already achieved or impossible (> 100).
    static func scoreNeeded(
        in category: GradeCategory,
        forOverall targetOverall: Double,
        allCategories: [GradeCategory],
        hypotheticalPointsPossible: Double
    ) -> Double? {
        // Build a modified category with an unknown entry (x earned out of pointsPossible)
        // Solve for x such that overall == targetOverall

        // Current weighted contributions from OTHER categories
        var otherWeightedSum = 0.0
        var otherTotalWeight = 0.0

        for cat in allCategories where cat.id != category.id {
            if let avg = categoryAverage(cat) {
                otherWeightedSum += cat.weight * avg
                otherTotalWeight += cat.weight
            }
        }

        // Current earned/possible in this category
        let gradedEntries = category.entries.filter { !$0.isDropped && $0.pointsEarned != nil }
        let currentEarned = gradedEntries.reduce(0.0) { $0 + $1.pointsEarned! }
        let currentPossible = gradedEntries.reduce(0.0) { $0 + $1.pointsPossible }

        // After adding the hypothetical entry:
        // newCatAvg = (currentEarned + x) / (currentPossible + hypotheticalPointsPossible) * 100
        // overall = (otherWeightedSum + category.weight * newCatAvg) / (otherTotalWeight + category.weight)
        // Solve for x:
        let totalWeight = otherTotalWeight + category.weight
        guard totalWeight > 0 else { return nil }

        // targetOverall * totalWeight = otherWeightedSum + category.weight * newCatAvg
        // newCatAvg = (targetOverall * totalWeight - otherWeightedSum) / category.weight
        let neededCatAvg = (targetOverall * totalWeight - otherWeightedSum) / category.weight

        // neededCatAvg = (currentEarned + x) / (currentPossible + hypotheticalPointsPossible) * 100
        // x = neededCatAvg / 100 * (currentPossible + hypotheticalPointsPossible) - currentEarned
        let newPossible = currentPossible + hypotheticalPointsPossible
        let x = (neededCatAvg / 100.0) * newPossible - currentEarned

        if x < 0 { return nil }   // target already achieved
        if x > hypotheticalPointsPossible { return nil }  // impossible
        return x
    }

    // MARK: - Final Exam Calculator

    /// What score is needed on a final exam worth `finalWeight` (e.g. 0.20)
    /// to achieve `targetPercentage`, given the current course grade?
    /// Returns (scoreNeeded, isAchievable) where isAchievable = scoreNeeded <= 100.0
    static func scoreNeededOnFinal(
        currentGrade: CourseGrade,
        finalWeight: Double,
        targetPercentage: Double
    ) -> (score: Double, isAchievable: Bool)? {
        guard let current = overallPercentage(currentGrade) else { return nil }
        guard finalWeight > 0, finalWeight < 1 else { return nil }

        let preFinalWeight = 1.0 - finalWeight
        // target = preFinalWeight * current + finalWeight * finalScore
        // finalScore = (target - preFinalWeight * current) / finalWeight
        let finalScore = (targetPercentage - preFinalWeight * current) / finalWeight

        return (score: finalScore, isAchievable: finalScore <= 100.0)
    }
}
