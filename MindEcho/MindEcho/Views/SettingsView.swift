import SwiftUI

struct SettingsView: View {
    @Bindable var transcriberPreference: TranscriberPreference
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(TranscriberType.allCases, id: \.self) { type in
                        Button {
                            transcriberPreference.type = type
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(type.displayName)
                                        .foregroundStyle(.primary)
                                    Text(type.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if transcriberPreference.type == type {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .accessibilityIdentifier("settings.transcriber.\(type.rawValue)")
                    }
                } header: {
                    Text("書き起こしエンジン")
                } footer: {
                    Text("SpeechTranscriber は高精度ですがカスタム語彙が効きません。DictationTranscriber は句読点付きの出力でカスタム語彙に対応しています。")
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityIdentifier("settings.closeButton")
                }
            }
        }
    }
}
