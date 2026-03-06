import UIKit

enum PDFRenderer {
    private static let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4
    private static let margin: CGFloat = 50

    private static let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: 20),
        .foregroundColor: UIColor.label,
    ]
    private static let bodyAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 14),
        .foregroundColor: UIColor.label,
    ]

    /// Renders a simple PDF with a title and body text, returning the raw PDF data.
    static func render(title: String, body: String) -> Data {
        let contentRect = pageRect.insetBy(dx: margin, dy: margin)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
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
            let bodyString = NSAttributedString(string: body, attributes: bodyAttributes)
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
    }
}
