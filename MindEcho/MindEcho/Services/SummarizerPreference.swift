import Foundation
import Observation

enum SummarizerType: String, CaseIterable, Sendable {
    case onDevice
    case openAI

    var displayName: String {
        switch self {
        case .onDevice:
            "Apple Foundation Models"
        case .openAI:
            "OpenAI API"
        }
    }

    var description: String {
        switch self {
        case .onDevice:
            "オンデバイスで動作（ネットワーク不要）"
        case .openAI:
            "OpenAI Chat Completions API（ネットワーク必須・テキストが外部送信されます）"
        }
    }
}

@Observable
final class SummarizerPreference {
    private static let defaultKey = "summarizerType"

    private let defaults: UserDefaults
    private let keyName: String

    var type: SummarizerType {
        didSet { defaults.set(type.rawValue, forKey: keyName) }
    }

    init(defaults: UserDefaults = .standard, key: String = defaultKey) {
        self.defaults = defaults
        self.keyName = key
        self.type =
            defaults.string(forKey: key)
            .flatMap(SummarizerType.init(rawValue:)) ?? .onDevice
    }
}
