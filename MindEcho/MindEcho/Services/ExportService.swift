import AVFoundation
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

    func exportTranscriptPDF(entry: JournalEntry, to directory: URL) throws -> URL {
        try FilePathManager.ensureDirectoryExists(directory)

        let dateHeader = DateHelper.displayString(for: entry.date)
        let transcriptions = entry.sortedRecordings.compactMap(\.transcription)
        let body = transcriptions.joined(separator: "\n\n")

        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4
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
            // Draw title on first page
            context.beginPage()
            let titleString = NSAttributedString(string: dateHeader, attributes: titleAttributes)
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

            // Draw body text with automatic page breaks
            let bodyTop = contentRect.origin.y + titleSize.height + 20
            let bodyString = NSAttributedString(string: body, attributes: bodyAttributes)
            let textStorage = NSTextStorage(attributedString: bodyString)
            let layoutManager = NSLayoutManager()
            textStorage.addLayoutManager(layoutManager)

            var currentY = bodyTop
            let textContainerWidth = contentRect.width
            var glyphIndex = 0

            while glyphIndex < layoutManager.numberOfGlyphs {
                let availableHeight = pageRect.height - margin - currentY
                let textContainer = NSTextContainer(
                    size: CGSize(width: textContainerWidth, height: availableHeight)
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

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        let dateStr = formatter.string(from: entry.date)
        let exportURL = directory.appendingPathComponent("\(dateStr)_transcript.pdf")

        try data.write(to: exportURL)
        return exportURL
    }

    func exportCombinedTranscript(entry: JournalEntry, to directory: URL) throws -> URL {
        try FilePathManager.ensureDirectoryExists(directory)

        // Build transcript text with date header
        let dateHeader = DateHelper.displayString(for: entry.date)
        let transcriptions = entry.sortedRecordings.compactMap(\.transcription)
        let body = transcriptions.joined(separator: "\n\n")
        let content = dateHeader + "\n\n" + body

        // Write to export directory
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        let dateStr = formatter.string(from: entry.date)
        let exportURL = directory.appendingPathComponent("\(dateStr)_transcript.txt")

        try content.write(to: exportURL, atomically: true, encoding: .utf8)

        return exportURL
    }
}
