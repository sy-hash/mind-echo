import Foundation

struct OpenAISummarizationService: Sendable {
    enum SummarizationError: LocalizedError {
        case apiKeyMissing
        case apiError(String)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .apiKeyMissing:
                "OpenAI API キーが設定されていません。設定画面から API キーを入力してください。"
            case .apiError(let message):
                "OpenAI API エラー: \(message)"
            case .invalidResponse:
                "OpenAI API から不正なレスポンスが返されました。"
            }
        }
    }

    private static let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    func summarize(text: String, instruction: String, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw SummarizationError.apiKeyMissing
        }

        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": instruction],
                ["role": "user", "content": text],
            ],
            "temperature": 0.3,
            "max_tokens": 300,
        ]

        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SummarizationError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            // OpenAI エラーレスポンスからユーザー向けメッセージを抽出
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let errorDict = json["error"] as? [String: Any],
                let message = errorDict["message"] as? String,
                !message.isEmpty
            {
                throw SummarizationError.apiError(message)
            }

            // ステータスコードに応じた定型文にフォールバック
            let userMessage: String =
                switch httpResponse.statusCode {
                case 401:
                    "API キーが無効か、認証に失敗しました。設定を確認してください。"
                case 429:
                    "リクエストが多すぎます。しばらく時間をおいてから再試行してください。"
                case 500...599:
                    "OpenAI API 側でエラーが発生しました。時間をおいて再試行してください。"
                default:
                    "HTTP \(httpResponse.statusCode) エラーが発生しました。"
                }
            throw SummarizationError.apiError(userMessage)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let firstChoice = choices.first,
            let message = firstChoice["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw SummarizationError.invalidResponse
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
