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

    // MARK: - Dispatch (共通エントリポイント)

    static func summarize(text: String, instruction: String, type: SummarizerType, apiKey: String) async throws
        -> String
    {
        switch type {
        case .onDevice:
            try await SummarizationService().summarize(text: text, instruction: instruction)
        case .openAI:
            try await OpenAISummarizationService().summarize(text: text, instruction: instruction, apiKey: apiKey)
        }
    }

    static func isAvailable(type: SummarizerType, apiKey: String) -> Bool {
        switch type {
        case .onDevice:
            Self.isAvailable
        case .openAI:
            !apiKey.isEmpty
        }
    }
}
