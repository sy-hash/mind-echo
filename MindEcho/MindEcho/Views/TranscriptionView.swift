import MindEchoCore
import Speech
import SwiftUI
import UIKit

struct TranscriptionView: View {
    let recording: Recording
    var vocabularyWords: [String] = []
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = TranscriptionViewModel()
    @State private var shareItems: [Any]?

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView("書き起こし中...")
                        .accessibilityIdentifier("transcription.loading")
                case .success(let text):
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            summarySection
                            Text(text)
                                .padding(.horizontal)
                                .textSelection(.enabled)
                                .accessibilityIdentifier("transcription.resultText")
                        }
                        .padding(.vertical)
                    }
                case .failure(let message):
                    ContentUnavailableView {
                        Label("エラー", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    }
                    .accessibilityIdentifier("transcription.error")
                }
            }
            .navigationTitle("書き起こし #\(recording.sequenceNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityIdentifier("transcription.closeButton")
                }
                if case .success = viewModel.state {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            sharePDF()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityIdentifier("transcription.shareButton")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { shareItems != nil },
                set: { if !$0 { shareItems = nil } }
            )) {
                if let items = shareItems {
                    ShareSheet(activityItems: items)
                }
            }
        }
        .task {
            viewModel.vocabularyWords = vocabularyWords
            if ProcessInfo.processInfo.arguments.contains("--mock-transcription") {
                viewModel.transcribe = { _, _, _ in
                    try await Task.sleep(for: .milliseconds(500))
                    return "これはモックの書き起こし結果です。テスト用のテキストデータ。"
                }
                viewModel.checkAuthorization = { .authorized }
            }
            if ProcessInfo.processInfo.arguments.contains("--mock-summarization") {
                viewModel.summarize = { text in
                    try await Task.sleep(for: .milliseconds(300))
                    return "これはモックの要約結果です。"
                }
                viewModel.isSummarizationAvailable = { true }
            }
            await viewModel.startTranscription(recording: recording)
        }
    }

    private func sharePDF() {
        guard case .success(let text) = viewModel.state else { return }
        let title = "書き起こし #\(recording.sequenceNumber)"
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let margin: CGFloat = 50
        let contentRect = pageRect.insetBy(dx: margin, dy: margin)

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor.label,
        ]
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.label,
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let data = renderer.pdfData { context in
            context.beginPage()
            let titleString = NSAttributedString(string: title, attributes: titleAttributes)
            let titleSize = titleString.boundingRect(
                with: CGSize(width: contentRect.width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin],
                context: nil
            )
            titleString.draw(in: CGRect(
                x: contentRect.origin.x,
                y: contentRect.origin.y,
                width: contentRect.width,
                height: titleSize.height
            ))

            let bodyTop = contentRect.origin.y + titleSize.height + 20
            let bodyString = NSAttributedString(string: text, attributes: bodyAttributes)
            let textStorage = NSTextStorage(attributedString: bodyString)
            let layoutManager = NSLayoutManager()
            textStorage.addLayoutManager(layoutManager)

            var currentY = bodyTop
            var glyphIndex = 0

            while glyphIndex < layoutManager.numberOfGlyphs {
                let availableHeight = pageRect.height - margin - currentY
                let textContainer = NSTextContainer(
                    size: CGSize(width: contentRect.width, height: availableHeight)
                )
                textContainer.lineFragmentPadding = 0
                layoutManager.addTextContainer(textContainer)

                let glyphRange = layoutManager.glyphRange(for: textContainer)
                if glyphRange.length == 0 { break }

                layoutManager.drawBackground(forGlyphRange: glyphRange, at: CGPoint(x: contentRect.origin.x, y: currentY))
                layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: CGPoint(x: contentRect.origin.x, y: currentY))

                glyphIndex = NSMaxRange(glyphRange)
                if glyphIndex < layoutManager.numberOfGlyphs {
                    context.beginPage()
                    currentY = margin
                }
            }
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("transcription_\(recording.sequenceNumber).pdf")
        try? data.write(to: tempURL)
        shareItems = [tempURL]
    }

    @ViewBuilder
    private var summarySection: some View {
        switch viewModel.summaryState {
        case .idle:
            EmptyView()
        case .loading:
            VStack(alignment: .leading, spacing: 8) {
                Label("要約", systemImage: "text.document")
                    .font(.headline)
                ProgressView("要約を生成中...")
                    .accessibilityIdentifier("transcription.summaryLoading")
            }
            .padding(.horizontal)
        case .success(let summary):
            VStack(alignment: .leading, spacing: 8) {
                Label("要約", systemImage: "text.document")
                    .font(.headline)
                Text(summary)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("transcription.summaryText")
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            Divider()
                .padding(.horizontal)
        case .failure(let message):
            VStack(alignment: .leading, spacing: 8) {
                Label("要約", systemImage: "text.document")
                    .font(.headline)
                Text(message)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("transcription.summaryError")
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            Divider()
                .padding(.horizontal)
        case .unavailable:
            EmptyView()
        }
    }
}
