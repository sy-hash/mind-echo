import MindEchoCore
import UIKit

/// 1日分のジャーナルエントリを PDF ファイルとして生成するサービス
struct PDFExportService {
    private static let pageWidth: CGFloat = 595.2  // A4 width in points
    private static let pageHeight: CGFloat = 841.8  // A4 height in points
    private static let margin: CGFloat = 36.0
    private static let bodyWidth: CGFloat = pageWidth - margin * 2

    /// 1日分のエントリを PDF 化して outputURL に書き出す
    static func generateDailyPDF(entry: JournalEntry, outputURL: URL) throws {
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        )

        let data = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = margin

            // 日付ヘッダー
            let dateString = DateHelper.displayString(for: entry.date)
            y = drawText(
                dateString,
                at: CGPoint(x: margin, y: y),
                font: .boldSystemFont(ofSize: 18),
                color: .label,
                maxWidth: bodyWidth,
                context: context
            )
            y += 12

            // 区切り線
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: margin, y: y))
            linePath.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            UIColor.separator.setStroke()
            linePath.lineWidth = 0.5
            linePath.stroke()
            y += 12

            for recording in entry.sortedRecordings {
                guard let transcription = recording.transcription, !transcription.isEmpty else { continue }

                // 録音メタデータのサブヘッダー
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                let timeStr = timeFormatter.string(from: recording.recordedAt)

                let minutes = Int(recording.duration) / 60
                let seconds = Int(recording.duration) % 60
                let durationStr = String(format: "%d:%02d", minutes, seconds)

                let subheader = "#\(recording.sequenceNumber)  \(timeStr)  (\(durationStr))"

                // ページ終端チェック（サブヘッダー + 最低1行の本文分の余白）
                if y + 60 > pageHeight - margin {
                    context.beginPage()
                    y = margin
                }

                y = drawText(
                    subheader,
                    at: CGPoint(x: margin, y: y),
                    font: .boldSystemFont(ofSize: 13),
                    color: .secondaryLabel,
                    maxWidth: bodyWidth,
                    context: context
                )
                y += 6

                // 書き起こし本文
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineHeightMultiple = 1.4
                let bodyAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.label,
                    .paragraphStyle: paragraphStyle,
                ]
                let attributedBody = NSAttributedString(string: transcription, attributes: bodyAttributes)

                let textStorage = NSTextStorage(attributedString: attributedBody)
                let layoutManager = NSLayoutManager()
                textStorage.addLayoutManager(layoutManager)

                var charIndex = 0
                let totalChars = attributedBody.length

                while charIndex < totalChars {
                    let remainingHeight = pageHeight - margin - y
                    let textContainer = NSTextContainer(
                        size: CGSize(width: bodyWidth, height: remainingHeight)
                    )
                    textContainer.lineFragmentPadding = 0
                    layoutManager.addTextContainer(textContainer)

                    layoutManager.ensureLayout(for: textContainer)
                    let range = layoutManager.glyphRange(for: textContainer)
                    let usedRect = layoutManager.usedRect(for: textContainer)

                    if range.length == 0 {
                        // テキストがこのページに入りきらない場合は改ページ
                        context.beginPage()
                        y = margin
                        // 新しいページで再試行するため textContainer を再作成
                        layoutManager.removeTextContainer(at: layoutManager.textContainers.count - 1)
                        continue
                    }

                    // テキストを描画
                    let drawRect = CGRect(x: margin, y: y, width: bodyWidth, height: usedRect.height)
                    layoutManager.drawBackground(
                        forGlyphRange: range, at: CGPoint(x: margin, y: y))
                    layoutManager.drawGlyphs(forGlyphRange: range, at: CGPoint(x: margin, y: y))

                    y += drawRect.height
                    charIndex += range.length

                    if charIndex < totalChars {
                        // まだ残りがある → 改ページ
                        context.beginPage()
                        y = margin
                    }
                }

                y += 16  // 録音間の余白
            }
        }

        try data.write(to: outputURL)
    }

    // MARK: - Private Helpers

    /// テキストを指定位置に描画し、描画後の y 座標を返す
    @discardableResult
    private static func drawText(
        _ text: String,
        at point: CGPoint,
        font: UIFont,
        color: UIColor,
        maxWidth: CGFloat,
        context: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
        ]
        let rect = CGRect(x: point.x, y: point.y, width: maxWidth, height: .greatestFiniteMagnitude)
        let boundingRect = (text as NSString).boundingRect(
            with: rect.size, options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes, context: nil
        )
        (text as NSString).draw(
            with: CGRect(x: point.x, y: point.y, width: maxWidth, height: boundingRect.height),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        return point.y + boundingRect.height
    }
}
