import Foundation

struct WhisperAPIService: Sendable {
    enum WhisperError: LocalizedError {
        case apiKeyMissing
        case fileTooLarge(Int)
        case apiError(String)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .apiKeyMissing:
                "OpenAI API キーが設定されていません。設定画面から API キーを入力してください。"
            case .fileTooLarge(let sizeMB):
                "音声ファイルが上限（25MB）を超えています（\(sizeMB)MB）。"
            case .apiError(let message):
                "Whisper API エラー: \(message)"
            case .invalidResponse:
                "Whisper API から不正なレスポンスが返されました。"
            }
        }
    }

    private static let maxFileSize = 25 * 1024 * 1024 // 25MB
    private static let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!

    func transcribe(audioFileURL: URL, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw WhisperError.apiKeyMissing
        }

        let fileData = try Data(contentsOf: audioFileURL)
        if fileData.count > Self.maxFileSize {
            throw WhisperError.fileTooLarge(fileData.count / (1024 * 1024))
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let fileName = audioFileURL.lastPathComponent

        func appendField(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        // file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)

        appendField(name: "model", value: "gpt-4o-transcribe")
        appendField(name: "language", value: "ja")
        appendField(name: "response_format", value: "text")

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WhisperError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorBody = String(data: data, encoding: .utf8), !errorBody.isEmpty {
                throw WhisperError.apiError(errorBody)
            }
            throw WhisperError.apiError("HTTP \(httpResponse.statusCode)")
        }

        guard let text = String(data: data, encoding: .utf8) else {
            throw WhisperError.invalidResponse
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
