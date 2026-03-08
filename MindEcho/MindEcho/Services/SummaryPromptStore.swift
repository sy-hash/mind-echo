import Foundation
import Observation

@Observable
final class SummaryPromptStore {
    static let defaultPrompt = "以下の書き起こしテキストを簡潔に要約してください。要約のみを出力し、余計な前置きは不要です。"

    private static let promptKey = "summaryPrompt"

    private let defaults: UserDefaults
    private let key: String

    var prompt: String {
        didSet { defaults.set(prompt, forKey: key) }
    }

    init(defaults: UserDefaults = .standard, key: String = promptKey) {
        self.defaults = defaults
        self.key = key
        self.prompt = defaults.string(forKey: key) ?? Self.defaultPrompt
    }

    func resetToDefault() {
        prompt = Self.defaultPrompt
    }
}
