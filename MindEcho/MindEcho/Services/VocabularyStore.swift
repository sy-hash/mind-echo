import Foundation
import Observation

@Observable
final class VocabularyStore {
    private static let defaultKey = "userVocabulary"

    private let defaults: UserDefaults
    private let key: String

    var words: [String] {
        didSet { save() }
    }

    init(defaults: UserDefaults = .standard, key: String = defaultKey) {
        self.defaults = defaults
        self.key = key
        self.words = defaults.stringArray(forKey: key) ?? []
    }

    func add(_ word: String) {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !words.contains(trimmed) else { return }
        words.append(trimmed)
    }

    func remove(at offsets: IndexSet) {
        words.remove(atOffsets: offsets)
    }

    private func save() {
        defaults.set(words, forKey: key)
    }
}
