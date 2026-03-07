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

        self.liveType = defaults.string(forKey: liveKey)
            .flatMap(TranscriberType.init(rawValue:)) ?? .speechTranscriber
        self.postRecordingType = defaults.string(forKey: postRecordingKey)
            .flatMap(TranscriberType.init(rawValue:)) ?? .speechTranscriber
    }

    private func save() {
        defaults.set(liveType.rawValue, forKey: liveKeyName)
        defaults.set(postRecordingType.rawValue, forKey: postRecordingKeyName)
    }
}
