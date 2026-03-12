import Foundation
import FoundationModels

struct SummarizationService {
    func summarize(text: String, instruction: String) async throws -> String {
        let session = LanguageModelSession()
        let prompt = "\(instruction)\n\n\(text)"
        let response = try await session.respond(to: prompt)
        return String(response.content).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }
}
