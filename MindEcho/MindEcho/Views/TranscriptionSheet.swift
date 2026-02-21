import SwiftUI

// MARK: - Transcription State

enum TranscriptionState {
    case idle
    case loading
    case success(String)
    case failure(String)
}

// MARK: - TranscriptionSheet

struct TranscriptionSheet: View {
    let sequenceNumber: Int
    let state: TranscriptionState
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                switch state {
                case .idle:
                    idleView
                case .loading:
                    loadingView
                case .success(let text):
                    successView(text: text)
                case .failure(let message):
                    failureView(message: message)
                }
            }
            .navigationTitle("書き起こし #\(sequenceNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる", action: onDismiss)
                        .accessibilityIdentifier("transcription.closeButton")
                }
            }
        }
    }

    // MARK: - Subviews

    private var idleView: some View {
        ContentUnavailableView(
            "書き起こし準備中",
            systemImage: "waveform",
            description: Text("まもなく開始します")
        )
        .accessibilityIdentifier("transcription.idleView")
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("書き起こし中...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("transcription.loadingView")
    }

    private func successView(text: String) -> some View {
        ScrollView {
            Text(text)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .textSelection(.enabled)
        }
        .accessibilityIdentifier("transcription.resultText")
    }

    private func failureView(message: String) -> some View {
        ContentUnavailableView(
            "書き起こし失敗",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
        .accessibilityIdentifier("transcription.errorView")
    }
}
