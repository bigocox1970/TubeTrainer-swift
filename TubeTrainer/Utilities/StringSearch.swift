import Foundation

extension String {
    /// Lowercased, diacritic- and punctuation-stripped form for forgiving search.
    var ttNormalized: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var ttTokens: [String] {
        ttNormalized.split(separator: " ").map(String.init)
    }
}

enum ExerciseSearch {
    /// Forgiving match: partial name, aliases, category, equipment.
    /// Every token in the query must appear as a prefix of some token in the haystack.
    static func matches(query: String, exercise: Exercise) -> Bool {
        let q = query.ttNormalized
        guard !q.isEmpty else { return true }
        let queryTokens = q.split(separator: " ").map(String.init)

        var haystackTokens = Set(exercise.normalizedName.split(separator: " ").map(String.init))
        haystackTokens.formUnion(exercise.category.rawValue.ttTokens)
        haystackTokens.formUnion(exercise.equipment.rawValue.ttTokens)
        for alias in exercise.aliases {
            haystackTokens.formUnion(alias.ttTokens)
        }
        // Whole normalized alias strings too (for acronyms like "rdl").
        for alias in exercise.aliases {
            haystackTokens.insert(alias.ttNormalized.replacingOccurrences(of: " ", with: ""))
        }

        return queryTokens.allSatisfy { qt in
            haystackTokens.contains { $0.hasPrefix(qt) || qt.hasPrefix($0) && $0.count >= 2 }
        }
    }
}
