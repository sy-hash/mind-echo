import Foundation
import FoundationModels

struct SummarizationService {
    func summarize(text: String) async throws -> String {
        let session = LanguageModelSession()
        let prompt = "以下の書き起こしテキストを簡潔に要約してください。要約のみを出力し、余計な前置きは不要です。\n\n\(text)"
        let response = try await session.respond(to: prompt)
        return String(response.content).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var isAvailable: Bool {
        LanguageModelSession.isAvailable
    }
}
