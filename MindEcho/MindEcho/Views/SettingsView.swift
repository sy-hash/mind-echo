import SwiftUI

struct SettingsView: View {
    @Bindable var transcriberPreference: TranscriberPreference
    @Bindable var summarizerPreference: SummarizerPreference
    @Bindable var openAIAPIKeyStore: OpenAIAPIKeyStore
    @Bindable var summaryPromptStore: SummaryPromptStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(TranscriberType.liveCases, id: \.self) { type in
                        Button {
                            transcriberPreference.liveType = type
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
                                if transcriberPreference.liveType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .accessibilityIdentifier("settings.liveTranscriber.\(type.rawValue)")
                    }
                } header: {
                    Text("リアルタイム書き起こしエンジン")
                } footer: {
                    Text("録音中にリアルタイムで表示される書き起こしに使用するエンジンです。")
                }

                Section {
                    ForEach(TranscriberType.postRecordingCases, id: \.self) { type in
                        Button {
                            transcriberPreference.postRecordingType = type
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
                                if transcriberPreference.postRecordingType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .accessibilityIdentifier("settings.postRecordingTranscriber.\(type.rawValue)")
                    }
                } header: {
                    Text("事後書き起こしエンジン")
                } footer: {
                    Text("録音完了後の書き起こしに使用するエンジンです。Whisper API はネットワーク接続が必要で、音声データが OpenAI サーバーに送信されます。")
                }

                Section {
                    ForEach(SummarizerType.allCases, id: \.self) { type in
                        Button {
                            summarizerPreference.type = type
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
                                if summarizerPreference.type == type {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .accessibilityIdentifier("settings.summarizer.\(type.rawValue)")
                    }
                } header: {
                    Text("要約エンジン")
                } footer: {
                    Text("書き起こしテキストの要約に使用するエンジンです。OpenAI API はネットワーク接続が必要で、テキストが OpenAI サーバーに送信されます。")
                }

                Section {
                    SecureField("sk-...", text: $openAIAPIKeyStore.apiKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .accessibilityIdentifier("settings.openAIAPIKey")
                } header: {
                    Text("OpenAI API キー")
                } footer: {
                    Text("Whisper API および OpenAI 要約を使用するために必要です。API キーは端末内に保存されます。")
                }

                Section {
                    TextEditor(text: $summaryPromptStore.instruction)
                        .frame(minHeight: 80)
                        .accessibilityIdentifier("settings.summaryPrompt")
                    Button("デフォルトに戻す") {
                        summaryPromptStore.instruction = SummaryPromptStore.defaultInstruction
                    }
                    .accessibilityIdentifier("settings.summaryPromptResetButton")
                } header: {
                    Text("要約プロンプト")
                } footer: {
                    Text("録音の書き起こしを要約する際に使用する指示文です。書き起こしテキストは自動的に指示文の後に追加されます。")
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
