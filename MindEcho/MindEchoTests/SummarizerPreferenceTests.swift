import Testing
import Foundation
@testable import MindEcho

@MainActor
struct SummarizerPreferenceTests {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "SummarizerPreferenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return defaults
    }

    @Test func defaultType_isOnDevice() {
        let defaults = makeDefaults()
        let pref = SummarizerPreference(defaults: defaults)
        #expect(pref.type == .onDevice)
    }

    @Test func setType_persistsToUserDefaults() {
        let defaults = makeDefaults()
        let pref = SummarizerPreference(defaults: defaults)

        pref.type = .openAI

        #expect(defaults.string(forKey: "summarizerType") == "openAI")
    }

    @Test func initFromPersistedValues_restoresType() {
        let defaults = makeDefaults()
        defaults.set("openAI", forKey: "summarizerType")

        let pref = SummarizerPreference(defaults: defaults)

        #expect(pref.type == .openAI)
    }

    @Test func invalidPersistedValue_defaultsToOnDevice() {
        let defaults = makeDefaults()
        defaults.set("invalidValue", forKey: "summarizerType")

        let pref = SummarizerPreference(defaults: defaults)

        #expect(pref.type == .onDevice)
    }

    @Test func summarizerType_displayNames() {
        #expect(SummarizerType.onDevice.displayName == "Apple Foundation Models")
        #expect(SummarizerType.openAI.displayName == "OpenAI API")
    }

    @Test func summarizerType_allCases() {
        #expect(SummarizerType.allCases.count == 2)
        #expect(SummarizerType.allCases.contains(.onDevice))
        #expect(SummarizerType.allCases.contains(.openAI))
    }
}
