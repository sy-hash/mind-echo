import Foundation
import Observation

enum TranscriberType: String, CaseIterable, Sendable {
    case speechTranscriber
    case dictationTranscriber
    case whisperAPI

    var displayName: String {
        switch self {
        case .speechTranscriber:
            "SpeechTranscriber"
        case .dictationTranscriber:
            "DictationTranscriber"
        case .whisperAPI:
            "Whisper API"
        }
    }

    var description: String {
        switch self {
        case .speechTranscriber:
            "高精度・生テキスト出力"
        case .dictationTranscriber:
            "句読点付き出力"
        case .whisperAPI:
            "OpenAI Whisper API（ネットワーク必須・音声データが外部送信されます）"
        }
    }

    /// リアルタイム書き起こしで使用可能なケース
    static var liveCases: [TranscriberType] {
        [.speechTranscriber, .dictationTranscriber]
    }

    /// 事後書き起こしで使用可能なケース
    static var postRecordingCases: [TranscriberType] {
        allCases
    }
}

@Observable
final class OpenAIAPIKeyStore {
    private static let apiKeyKey = "openAIAPIKey"

    private let defaults: UserDefaults
    private let keyName: String

    var apiKey: String {
        didSet { defaults.set(apiKey, forKey: keyName) }
    }

    init(defaults: UserDefaults = .standard, key: String = apiKeyKey) {
        self.defaults = defaults
        self.keyName = key
        self.apiKey = defaults.string(forKey: key) ?? ""
    }
}

@Observable
final class TranscriberPreference {
    private static let liveKey = "liveTranscriberType"
    private static let postRecordingKey = "postRecordingTranscriberType"

    private let defaults: UserDefaults
    private let liveKeyName: String
    private let postRecordingKeyName: String

    var liveType: TranscriberType {
        didSet { save() }
    }

    var postRecordingType: TranscriberType {
        didSet { save() }
    }

    init(
        defaults: UserDefaults = .standard,
        liveKey: String = liveKey,
        postRecordingKey: String = postRecordingKey
    ) {
        self.defaults = defaults
        self.liveKeyName = liveKey
        self.postRecordingKeyName = postRecordingKey

        self.liveType =
            defaults.string(forKey: liveKey)
            .flatMap(TranscriberType.init(rawValue:)) ?? .speechTranscriber
        self.postRecordingType =
            defaults.string(forKey: postRecordingKey)
            .flatMap(TranscriberType.init(rawValue:)) ?? .speechTranscriber
    }

    private func save() {
        defaults.set(liveType.rawValue, forKey: liveKeyName)
        defaults.set(postRecordingType.rawValue, forKey: postRecordingKeyName)
    }
}
