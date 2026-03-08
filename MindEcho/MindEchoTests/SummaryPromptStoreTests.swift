import Testing
import Foundation
@testable import MindEcho

@MainActor
struct SummaryPromptStoreTests {
    private func makeStore() -> (SummaryPromptStore, UserDefaults) {
        let suiteName = "SummaryPromptStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = SummaryPromptStore(defaults: defaults)
        return (store, defaults)
    }

    @Test func initialState_hasDefaultPrompt() {
        let (store, _) = makeStore()
        #expect(store.prompt == SummaryPromptStore.defaultPrompt)
    }

    @Test func setPrompt_persistsToUserDefaults() {
        let suiteName = "SummaryPromptStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let store1 = SummaryPromptStore(defaults: defaults)
        store1.prompt = "カスタムプロンプト"

        let store2 = SummaryPromptStore(defaults: defaults)
        #expect(store2.prompt == "カスタムプロンプト")
    }

    @Test func resetToDefault_restoresDefaultPrompt() {
        let (store, _) = makeStore()
        store.prompt = "変更されたプロンプト"
        #expect(store.prompt != SummaryPromptStore.defaultPrompt)

        store.resetToDefault()
        #expect(store.prompt == SummaryPromptStore.defaultPrompt)
    }

    @Test func resetToDefault_persistsDefaultToUserDefaults() {
        let suiteName = "SummaryPromptStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let store1 = SummaryPromptStore(defaults: defaults)
        store1.prompt = "変更されたプロンプト"
        store1.resetToDefault()

        let store2 = SummaryPromptStore(defaults: defaults)
        #expect(store2.prompt == SummaryPromptStore.defaultPrompt)
    }

    @Test func defaultPrompt_matchesHardcodedValue() {
        #expect(SummaryPromptStore.defaultPrompt == "以下の書き起こしテキストを簡潔に要約してください。要約のみを出力し、余計な前置きは不要です。")
    }
}
