import Testing
import Foundation
@testable import MindEcho

@MainActor
struct TranscriberPreferenceTests {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "TranscriberPreferenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return defaults
    }

    @Test func defaultType_isSpeechTranscriber() {
        let defaults = makeDefaults()
        let pref = TranscriberPreference(defaults: defaults)
        #expect(pref.type == .speechTranscriber)
    }

    @Test func setType_persistsToUserDefaults() {
        let defaults = makeDefaults()
        let pref = TranscriberPreference(defaults: defaults)

        pref.type = .dictationTranscriber

        #expect(defaults.string(forKey: "transcriberType") == "dictationTranscriber")
    }

    @Test func initFromPersistedValue_restoresType() {
        let defaults = makeDefaults()
        defaults.set("dictationTranscriber", forKey: "transcriberType")

        let pref = TranscriberPreference(defaults: defaults)

        #expect(pref.type == .dictationTranscriber)
    }

    @Test func invalidPersistedValue_defaultsToSpeechTranscriber() {
        let defaults = makeDefaults()
        defaults.set("invalidValue", forKey: "transcriberType")

        let pref = TranscriberPreference(defaults: defaults)

        #expect(pref.type == .speechTranscriber)
    }

    @Test func transcriberType_displayNames() {
        #expect(TranscriberType.speechTranscriber.displayName == "SpeechTranscriber")
        #expect(TranscriberType.dictationTranscriber.displayName == "DictationTranscriber")
    }

    @Test func transcriberType_allCases() {
        #expect(TranscriberType.allCases.count == 2)
    }
}
