import AVFoundation
import CoreText
import Foundation
import MindEchoAudio
import MindEchoCore
import UIKit

struct ExportServiceImpl: Exporting {
    func exportMergedAudio(entry: JournalEntry, to directory: URL) async throws -> URL {
        try FilePathManager.ensureDirectoryExists(directory)

        // Generate TTS announcement
        let ttsBuffer = try await TTSGenerator.generateDateAnnouncement(for: entry.date)

        // Get recording file URLs in sequence order
        let recordingURLs = entry.sortedRecordings.map { recording in
            FilePathManager.recordingsDirectory.appendingPathComponent(recording.audioFileName)
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        let dateStr = formatter.string(from: entry.date)

        // First merge to Merged directory
        let mergedURL = FilePathManager.mergedDirectory.appendingPathComponent("\(dateStr)_merged.m4a")
        _ = try await AudioMerger.merge(
            ttsBuffer: ttsBuffer,
            recordingURLs: recordingURLs,
            outputURL: mergedURL
        )

        // Copy to export directory
        let exportURL = directory.appendingPathComponent("\(dateStr)_merged.m4a")
        try? FileManager.default.removeItem(at: exportURL)
        try FileManager.default.copyItem(at: mergedURL, to: exportURL)

        return exportURL
    }

    func exportCombinedTranscript(entry: JournalEntry, to directory: URL) throws -> URL {
        try FilePathManager.ensureDirectoryExists(directory)

        let content = transcriptContent(for: entry)

        // Write to export directory
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        let dateStr = formatter.string(from: entry.date)
        let exportURL = directory.appendingPathComponent("\(dateStr)_transcript.txt")

        try content.write(to: exportURL, atomically: true, encoding: .utf8)

        return exportURL
    }

    func exportTranscriptPDF(entry: JournalEntry, to directory: URL) throws -> URL {
        try FilePathManager.ensureDirectoryExists(directory)

        let content = transcriptContent(for: entry)
        let exportURL = directory.appendingPathComponent(
            FilePathManager.exportTranscriptPDFURL(for: entry.date).lastPathComponent
        )

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat = 40
        let textRect = pageRect.insetBy(dx: margin, dy: margin)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineSpacing = 4

        let bodyFont = UIFont.systemFont(ofSize: 14)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle,
        ]
        let attributedText = NSAttributedString(string: content, attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attributedText)

        try renderer.writePDF(to: exportURL) { context in
            var currentRange = CFRange(location: 0, length: 0)

            while currentRange.location < attributedText.length {
                context.beginPage()

                let path = CGPath(rect: textRect, transform: nil)
                let frame = CTFramesetterCreateFrame(
                    framesetter,
                    currentRange,
                    path,
                    nil
                )

                let visibleRange = CTFrameGetVisibleStringRange(frame)
                let cgContext = context.cgContext
                cgContext.saveGState()
                cgContext.textMatrix = .identity
                cgContext.translateBy(x: 0, y: pageRect.height)
                cgContext.scaleBy(x: 1, y: -1)
                CTFrameDraw(frame, cgContext)
                cgContext.restoreGState()

                currentRange.location += visibleRange.length
            }
        }

        return exportURL
    }

    private func transcriptContent(for entry: JournalEntry) -> String {
        let dateHeader = DateHelper.displayString(for: entry.date)
        let transcriptions = entry.sortedRecordings.compactMap(\.transcription)
        let body = transcriptions.joined(separator: "\n\n")
        return dateHeader + "\n\n" + body
    }
}
