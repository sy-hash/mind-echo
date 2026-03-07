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
                    ForEach(TranscriberType.allCases, id: \.self) { type in
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
                    Text("録音完了後の書き起こしに使用するエンジンです。SpeechTranscriber は高精度な生テキスト出力に対応しています。DictationTranscriber は句読点付きの出力に対応しています。どちらもカスタム語彙を利用できます。")
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
