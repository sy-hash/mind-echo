import Foundation
import Testing

@testable import MindEcho

@MainActor
struct SummaryPromptStoreTests {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "SummaryPromptStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return defaults
    }

    @Test func defaultInstruction_isExpected() {
        let defaults = makeDefaults()
        let store = SummaryPromptStore(defaults: defaults)
        #expect(store.instruction == SummaryPromptStore.defaultInstruction)
    }

    @Test func setInstruction_persistsToUserDefaults() {
        let defaults = makeDefaults()
        let key = "testSummaryPrompt"
        let store = SummaryPromptStore(defaults: defaults, key: key)

        store.instruction = "カスタムプロンプト"

        #expect(defaults.string(forKey: key) == "カスタムプロンプト")
    }

    @Test func initFromPersistedValue_restoresInstruction() {
        let defaults = makeDefaults()
        let key = "testSummaryPrompt"
        defaults.set("保存済みプロンプト", forKey: key)

        let store = SummaryPromptStore(defaults: defaults, key: key)

        #expect(store.instruction == "保存済みプロンプト")
    }

    @Test func noPersistedValue_usesDefault() {
        let defaults = makeDefaults()
        let store = SummaryPromptStore(defaults: defaults, key: "nonexistentKey")
        #expect(store.instruction == SummaryPromptStore.defaultInstruction)
    }
}
