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

    func exportTranscription(entry: JournalEntry, to directory: URL) throws -> URL {
        try FilePathManager.ensureDirectoryExists(directory)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        let dateStr = formatter.string(from: entry.date)

        // Build header: "2025-02-07 Fri"
        let headerFormatter = DateFormatter()
        headerFormatter.locale = Locale(identifier: "en_US_POSIX")
        headerFormatter.dateFormat = "yyyy-MM-dd E"
        let header = headerFormatter.string(from: entry.date)

        // PDF layout constants
        let pageSize = CGSize(width: 612, height: 792) // US Letter
        let margin: CGFloat = 50
        let contentWidth = pageSize.width - margin * 2

        let headerFont = UIFont.systemFont(ofSize: 18, weight: .bold)
        let labelFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let bodyFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let bodyColor = UIColor.darkGray

        let headerAttributes: [NSAttributedString.Key: Any] = [.font: headerFont]
        let labelAttributes: [NSAttributedString.Key: Any] = [.font: labelFont]
        let bodyAttributes: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: bodyColor]

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))

        let data = pdfRenderer.pdfData { context in
            context.beginPage()
            var y = margin

            // Draw header
            let headerRect = CGRect(x: margin, y: y, width: contentWidth, height: .greatestFiniteMagnitude)
            let headerDrawn = (header as NSString).boundingRect(
                with: headerRect.size, options: .usesLineFragmentOrigin,
                attributes: headerAttributes, context: nil
            )
            (header as NSString).draw(in: CGRect(x: margin, y: y, width: contentWidth, height: headerDrawn.height),
                                      withAttributes: headerAttributes)
            y += headerDrawn.height + 20

            // Draw each transcription
            for recording in entry.sortedRecordings {
                guard let transcription = recording.transcription else { continue }

                let label = "#\(recording.sequenceNumber)"
                let labelSize = (label as NSString).boundingRect(
                    with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                    options: .usesLineFragmentOrigin, attributes: labelAttributes, context: nil
                )
                let bodySize = (transcription as NSString).boundingRect(
                    with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                    options: .usesLineFragmentOrigin, attributes: bodyAttributes, context: nil
                )
                let blockHeight = labelSize.height + 4 + bodySize.height + 16

                // New page if needed
                if y + blockHeight > pageSize.height - margin {
                    context.beginPage()
                    y = margin
                }

                (label as NSString).draw(
                    in: CGRect(x: margin, y: y, width: contentWidth, height: labelSize.height),
                    withAttributes: labelAttributes
                )
                y += labelSize.height + 4

                (transcription as NSString).draw(
                    in: CGRect(x: margin, y: y, width: contentWidth, height: bodySize.height),
                    withAttributes: bodyAttributes
                )
                y += bodySize.height + 16
            }
        }

        let exportURL = directory.appendingPathComponent("\(dateStr)_transcription.pdf")
        try data.write(to: exportURL)

        return exportURL
    }
}
