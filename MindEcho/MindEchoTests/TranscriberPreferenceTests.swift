import Foundation
import Testing

@testable import MindEcho

@MainActor
struct TranscriberPreferenceTests {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "TranscriberPreferenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return defaults
    }

    @Test func defaultLiveType_isSpeechTranscriber() {
        let defaults = makeDefaults()
        let pref = TranscriberPreference(defaults: defaults)
        #expect(pref.liveType == .speechTranscriber)
    }

    @Test func defaultPostRecordingType_isSpeechTranscriber() {
        let defaults = makeDefaults()
        let pref = TranscriberPreference(defaults: defaults)
        #expect(pref.postRecordingType == .speechTranscriber)
    }

    @Test func setLiveType_persistsToUserDefaults() {
        let defaults = makeDefaults()
        let pref = TranscriberPreference(defaults: defaults)

        pref.liveType = .dictationTranscriber

        #expect(defaults.string(forKey: "liveTranscriberType") == "dictationTranscriber")
    }

    @Test func setPostRecordingType_persistsToUserDefaults() {
        let defaults = makeDefaults()
        let pref = TranscriberPreference(defaults: defaults)

        pref.postRecordingType = .dictationTranscriber

        #expect(defaults.string(forKey: "postRecordingTranscriberType") == "dictationTranscriber")
    }

    @Test func initFromPersistedValues_restoresTypes() {
        let defaults = makeDefaults()
        defaults.set("dictationTranscriber", forKey: "liveTranscriberType")
        defaults.set("speechTranscriber", forKey: "postRecordingTranscriberType")

        let pref = TranscriberPreference(defaults: defaults)

        #expect(pref.liveType == .dictationTranscriber)
        #expect(pref.postRecordingType == .speechTranscriber)
    }

    @Test func invalidPersistedValue_defaultsToSpeechTranscriber() {
        let defaults = makeDefaults()
        defaults.set("invalidValue", forKey: "liveTranscriberType")
        defaults.set("invalidValue", forKey: "postRecordingTranscriberType")

        let pref = TranscriberPreference(defaults: defaults)

        #expect(pref.liveType == .speechTranscriber)
        #expect(pref.postRecordingType == .speechTranscriber)
    }

    @Test func liveAndPostRecordingTypes_canDiffer() {
        let defaults = makeDefaults()
        let pref = TranscriberPreference(defaults: defaults)

        pref.liveType = .dictationTranscriber
        pref.postRecordingType = .speechTranscriber

        #expect(pref.liveType == .dictationTranscriber)
        #expect(pref.postRecordingType == .speechTranscriber)
    }

    @Test func transcriberType_displayNames() {
        #expect(TranscriberType.speechTranscriber.displayName == "SpeechTranscriber")
        #expect(TranscriberType.dictationTranscriber.displayName == "DictationTranscriber")
        #expect(TranscriberType.whisperAPI.displayName == "Whisper API")
    }

    @Test func transcriberType_allCases() {
        #expect(TranscriberType.allCases.count == 3)
    }

    @Test func transcriberType_liveCases_excludesWhisperAPI() {
        #expect(TranscriberType.liveCases.count == 2)
        #expect(!TranscriberType.liveCases.contains(.whisperAPI))
    }

    @Test func transcriberType_postRecordingCases_includesWhisperAPI() {
        #expect(TranscriberType.postRecordingCases.count == 3)
        #expect(TranscriberType.postRecordingCases.contains(.whisperAPI))
    }

    @Test func setPostRecordingType_whisperAPI_persistsToUserDefaults() {
        let defaults = makeDefaults()
        let pref = TranscriberPreference(defaults: defaults)

        pref.postRecordingType = .whisperAPI

        #expect(defaults.string(forKey: "postRecordingTranscriberType") == "whisperAPI")
    }

    @Test func openAIAPIKeyStore_defaultIsEmpty() {
        let defaults = makeDefaults()
        let store = OpenAIAPIKeyStore(defaults: defaults)
        #expect(store.apiKey == "")
    }

    @Test func openAIAPIKeyStore_persistsKey() {
        let defaults = makeDefaults()
        let store = OpenAIAPIKeyStore(defaults: defaults, key: "testOpenAIAPIKey")
        store.apiKey = "sk-test123"
        #expect(defaults.string(forKey: "testOpenAIAPIKey") == "sk-test123")
    }

    @Test func openAIAPIKeyStore_restoresPersistedKey() {
        let defaults = makeDefaults()
        defaults.set("sk-persisted", forKey: "testOpenAIAPIKey")
        let store = OpenAIAPIKeyStore(defaults: defaults, key: "testOpenAIAPIKey")
        #expect(store.apiKey == "sk-persisted")
    }
}
