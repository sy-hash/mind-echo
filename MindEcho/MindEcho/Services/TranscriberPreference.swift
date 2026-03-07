import Foundation
import Observation

enum TranscriberType: String, CaseIterable, Sendable {
    case speechTranscriber
    case dictationTranscriber

    var displayName: String {
        switch self {
        case .speechTranscriber:
            "SpeechTranscriber"
        case .dictationTranscriber:
            "DictationTranscriber"
        }
    }

    var description: String {
        switch self {
        case .speechTranscriber:
            "高精度・生テキスト出力"
        case .dictationTranscriber:
            "句読点付き出力"
        }
    }
}

@Observable
final class TranscriberPreference {
    private static let defaultKey = "transcriberType"

    private let defaults: UserDefaults
    private let key: String

    var type: TranscriberType {
        didSet { save() }
    }

    init(defaults: UserDefaults = .standard, key: String = defaultKey) {
        self.defaults = defaults
        self.key = key
        let raw = defaults.string(forKey: key) ?? ""
        self.type = TranscriberType(rawValue: raw) ?? .speechTranscriber
    }

    private func save() {
        defaults.set(type.rawValue, forKey: key)
    }
}
