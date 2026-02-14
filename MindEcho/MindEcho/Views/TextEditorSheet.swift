import SwiftUI

struct TextEditorSheet: View {
    @Binding var text: String
    var onSave: () -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationStack {
            TextEditor(text: $text)
                .padding()
                .accessibilityIdentifier("home.textEditor")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル", action: onCancel)
                            .accessibilityIdentifier("home.textCancelButton")
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存", action: onSave)
                            .accessibilityIdentifier("home.textSaveButton")
                    }
                }
                .navigationTitle("テキスト入力")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
