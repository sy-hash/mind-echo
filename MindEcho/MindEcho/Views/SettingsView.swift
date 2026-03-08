import SwiftUI

struct SettingsView: View {
    @Bindable var transcriberPreference: TranscriberPreference
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
                    SecureField("sk-...", text: $openAIAPIKeyStore.apiKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .accessibilityIdentifier("settings.openAIAPIKey")
                } header: {
                    Text("OpenAI API キー")
                } footer: {
                    Text("Whisper API を使用するために必要です。API キーは端末内に保存されます。")
                }

                Section {
                    TextEditor(text: $summaryPromptStore.prompt)
                        .frame(minHeight: 100)
                        .accessibilityIdentifier("settings.summaryPrompt")
                    if summaryPromptStore.prompt != SummaryPromptStore.defaultPrompt {
                        Button("デフォルトに戻す") {
                            summaryPromptStore.resetToDefault()
                        }
                        .accessibilityIdentifier("settings.summaryPromptReset")
                    }
                } header: {
                    Text("要約プロンプト")
                } footer: {
                    Text("書き起こしテキストの要約に使用するプロンプトです。書き起こしテキストはプロンプトの後に自動的に追加されます。")
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
