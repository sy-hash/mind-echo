import Foundation
import Testing

@testable import MindEcho

@MainActor
struct VocabularyStoreTests {
    private func makeStore() -> (VocabularyStore, UserDefaults) {
        let suiteName = "VocabularyStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = VocabularyStore(defaults: defaults)
        return (store, defaults)
    }

    @Test func initialState_isEmpty() {
        let (store, _) = makeStore()
        #expect(store.words.isEmpty)
    }

    @Test func add_appendsWord() {
        let (store, _) = makeStore()
        store.add("テスト")
        #expect(store.words == ["テスト"])
    }

    @Test func add_trimWhitespace() {
        let (store, _) = makeStore()
        store.add("  テスト  ")
        #expect(store.words == ["テスト"])
    }

    @Test func add_duplicateIsIgnored() {
        let (store, _) = makeStore()
        store.add("テスト")
        store.add("テスト")
        #expect(store.words == ["テスト"])
    }

    @Test func add_emptyStringIsIgnored() {
        let (store, _) = makeStore()
        store.add("")
        store.add("   ")
        #expect(store.words.isEmpty)
    }

    @Test func remove_deletesAtOffsets() {
        let (store, _) = makeStore()
        store.add("A")
        store.add("B")
        store.add("C")
        store.remove(at: IndexSet(integer: 1))
        #expect(store.words == ["A", "C"])
    }

    @Test func persistence_roundTrip() {
        let suiteName = "VocabularyStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let store1 = VocabularyStore(defaults: defaults)
        store1.add("永続化テスト")

        let store2 = VocabularyStore(defaults: defaults)
        #expect(store2.words == ["永続化テスト"])
    }
}
