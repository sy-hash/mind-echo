import Foundation
import FoundationModels

struct SummarizationService {
    func summarize(text: String, prompt: String = SummaryPromptStore.defaultPrompt) async throws -> String {
        let session = LanguageModelSession()
        let fullPrompt = "\(prompt)\n\n\(text)"
        let response = try await session.respond(to: fullPrompt)
        return String(response.content).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }
}
