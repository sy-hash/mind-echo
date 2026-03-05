import SwiftUI

struct VocabularyView: View {
    @Bindable var store: VocabularyStore
    @State private var newWord = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("単語を入力", text: $newWord)
                            .accessibilityIdentifier("vocabulary.textField")
                        Button {
                            store.add(newWord)
                            newWord = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("vocabulary.addButton")
                    }
                }

                Section {
                    ForEach(Array(store.words.enumerated()), id: \.offset) { index, word in
                        Text(word)
                            .accessibilityIdentifier("vocabulary.word.\(index)")
                    }
                    .onDelete { offsets in
                        store.remove(at: offsets)
                    }
                }
                .accessibilityIdentifier("vocabulary.wordList")
            }
            .navigationTitle("カスタム語彙")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityIdentifier("vocabulary.closeButton")
                }
            }
        }
    }
}
