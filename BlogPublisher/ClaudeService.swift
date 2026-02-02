import Foundation

actor ClaudeService {
    private var apiKey: String = ""
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-sonnet-4-20250514"

    func setApiKey(_ key: String) {
        self.apiKey = key
    }
    
    struct APIRequest: Codable {
        let model: String
        let max_tokens: Int
        let system: String?
        let messages: [APIMessage]
    }
    
    struct APIMessage: Codable {
        let role: String
        let content: String
    }
    
    struct APIResponse: Codable {
        let content: [ContentBlock]
        
        struct ContentBlock: Codable {
            let type: String
            let text: String?
        }
    }
    
    struct APIError: Codable {
        let error: ErrorDetail
        
        struct ErrorDetail: Codable {
            let message: String
        }
    }
    
    func sendMessage(_ message: String, context: String, history: ArraySlice<ChatMessage>) async throws -> String {
        guard !apiKey.isEmpty else {
            throw ClaudeError.missingAPIKey
        }
        
        // Build system prompt
        let systemPrompt = """
        당신은 블로그 글 작성을 도와주는 AI 어시스턴트입니다.
        사용자가 요청하면 블로그 포스트를 작성하거나 수정해주세요.
        
        현재 작업 중인 글의 내용:
        ---
        \(context.isEmpty ? "(아직 내용이 없습니다)" : context)
        ---
        
        규칙:
        1. 마크다운 형식으로 작성하세요
        2. 사용자가 "글을 써줘", "작성해줘" 등을 요청하면 완성된 글을 제공하세요
        3. 사용자가 수정을 요청하면 수정된 전체 글을 제공하세요
        4. 글을 작성할 때는 [CONTENT_START]와 [CONTENT_END] 태그로 감싸주세요
        5. 한국어로 응답하세요
        """
        
        // Build messages
        var messages: [APIMessage] = []
        
        for msg in history {
            messages.append(APIMessage(
                role: msg.role == .user ? "user" : "assistant",
                content: msg.content
            ))
        }
        
        messages.append(APIMessage(role: "user", content: message))
        
        let request = APIRequest(
            model: model,
            max_tokens: 4096,
            system: systemPrompt,
            messages: messages
        )
        
        var urlRequest = URLRequest(url: URL(string: baseURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(APIError.self, from: data) {
                throw ClaudeError.apiError(errorResponse.error.message)
            }
            throw ClaudeError.httpError(httpResponse.statusCode)
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
        
        guard let textContent = apiResponse.content.first(where: { $0.type == "text" }),
              let text = textContent.text else {
            throw ClaudeError.noContent
        }
        
        return text
    }
    
    func extractContent(from response: String) -> String? {
        // [CONTENT_START]와 [CONTENT_END] 사이의 내용 추출
        guard let startRange = response.range(of: "[CONTENT_START]"),
              let endRange = response.range(of: "[CONTENT_END]") else {
            return nil
        }
        
        let content = String(response[startRange.upperBound..<endRange.lowerBound])
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum ClaudeError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case noContent
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Claude API 키가 설정되지 않았습니다. 설정에서 API 키를 입력해주세요."
        case .invalidResponse:
            return "서버 응답을 처리할 수 없습니다."
        case .httpError(let code):
            return "HTTP 오류: \(code)"
        case .apiError(let message):
            return "API 오류: \(message)"
        case .noContent:
            return "응답에 내용이 없습니다."
        }
    }
}
