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
    /// Legacy key used before the live/post-recording split.
    private static let legacyKey = "transcriberType"

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

        // Migration: if old single key exists but new keys don't, migrate it.
        let legacyRaw = defaults.string(forKey: TranscriberPreference.legacyKey)
        let liveRaw = defaults.string(forKey: liveKey)
        let postRaw = defaults.string(forKey: postRecordingKey)

        if liveRaw == nil, let legacyRaw {
            self.liveType = TranscriberType(rawValue: legacyRaw) ?? .speechTranscriber
        } else {
            self.liveType = TranscriberType(rawValue: liveRaw ?? "") ?? .speechTranscriber
        }

        if postRaw == nil, let legacyRaw {
            self.postRecordingType = TranscriberType(rawValue: legacyRaw) ?? .speechTranscriber
        } else {
            self.postRecordingType = TranscriberType(rawValue: postRaw ?? "") ?? .speechTranscriber
        }
    }

    private func save() {
        defaults.set(liveType.rawValue, forKey: liveKeyName)
        defaults.set(postRecordingType.rawValue, forKey: postRecordingKeyName)
    }
}
