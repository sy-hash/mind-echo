import Foundation
import Observation

@Observable
final class SummaryPromptStore {
    private static let defaultKey = "summaryPromptInstruction"
    static let defaultInstruction = "以下の書き起こしテキストを簡潔に要約してください。要約のみを出力し、余計な前置きは不要です。"

    private let defaults: UserDefaults
    private let keyName: String

    var instruction: String {
        didSet { defaults.set(instruction, forKey: keyName) }
    }

    init(defaults: UserDefaults = .standard, key: String = defaultKey) {
        self.defaults = defaults
        self.keyName = key
        self.instruction = defaults.string(forKey: key) ?? Self.defaultInstruction
    }
}
