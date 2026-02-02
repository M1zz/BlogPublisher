import Foundation

class PlatformService {
    
    func publish(post: Post, to platform: PlatformConfig) async -> PublishResult {
        switch platform.platformType {
        case .hashnode:
            return await publishToHashnode(post: post, config: platform)
        case .substack:
            return await prepareForSubstack(post: post, config: platform)
        case .devto:
            return await publishToDevTo(post: post, config: platform)
        case .medium:
            return await publishToMedium(post: post, config: platform)
        case .tistory:
            return await publishToTistory(post: post, config: platform)
        case .custom:
            return await publishToCustom(post: post, config: platform)
        }
    }
    
    // MARK: - Hashnode
    private func publishToHashnode(post: Post, config: PlatformConfig) async -> PublishResult {
        guard !config.apiKey.isEmpty else {
            return PublishResult(
                platform: .hashnode,
                success: false,
                message: "API 키가 설정되지 않았습니다.",
                url: nil
            )
        }
        
        guard let publicationId = config.additionalConfig["publicationId"], !publicationId.isEmpty else {
            return PublishResult(
                platform: .hashnode,
                success: false,
                message: "Publication ID가 설정되지 않았습니다.",
                url: nil
            )
        }
        
        let mutation = """
        mutation PublishPost($input: PublishPostInput!) {
            publishPost(input: $input) {
                post {
                    id
                    slug
                    title
                    url
                }
            }
        }
        """
        
        let slug = createSlug(from: post.title)
        // 태그 slug도 영문만 허용 - 한글 태그는 고유한 영문 slug 생성
        let tags = post.tags.enumerated().map { index, tag -> [String: String] in
            let tagSlug = createSlug(from: tag, fallbackIndex: index)
            return ["slug": tagSlug, "name": tag]
        }
        
        let variables: [String: Any] = [
            "input": [
                "publicationId": publicationId,
                "title": post.title,
                "subtitle": post.subtitle,
                "contentMarkdown": post.content,
                "slug": slug,
                "tags": tags,
                "settings": [
                    "enableTableOfContent": true
                ]
            ]
        ]
        
        let payload: [String: Any] = [
            "query": mutation,
            "variables": variables
        ]
        
        do {
            var request = URLRequest(url: URL(string: "https://gql.hashnode.com/")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(config.apiKey, forHTTPHeaderField: "Authorization")
            let requestBody = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = requestBody

            // 요청 로그
            let requestLog = String(data: requestBody, encoding: .utf8) ?? "요청 데이터 없음"

            let (data, response) = try await URLSession.shared.data(for: request)

            // 응답 로그
            let responseLog = String(data: data, encoding: .utf8) ?? "응답 데이터 없음"
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let debugLog = """
            === Hashnode API 로그 ===
            상태 코드: \(statusCode)

            [요청]
            \(requestLog)

            [응답]
            \(responseLog)
            """

            print(debugLog) // 콘솔에도 출력

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataObj = json["data"] as? [String: Any],
               let publishPost = dataObj["publishPost"] as? [String: Any],
               let postObj = publishPost["post"] as? [String: Any],
               let url = postObj["url"] as? String {
                return PublishResult(
                    platform: .hashnode,
                    success: true,
                    message: "발행 완료!",
                    url: url,
                    debugLog: debugLog
                )
            } else if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let errors = json["errors"] as? [[String: Any]],
                      let firstError = errors.first,
                      let message = firstError["message"] as? String {
                return PublishResult(
                    platform: .hashnode,
                    success: false,
                    message: message,
                    url: nil,
                    debugLog: debugLog
                )
            }

            return PublishResult(
                platform: .hashnode,
                success: false,
                message: "알 수 없는 응답",
                url: nil,
                debugLog: debugLog
            )

        } catch {
            return PublishResult(
                platform: .hashnode,
                success: false,
                message: error.localizedDescription,
                url: nil,
                debugLog: "오류: \(error.localizedDescription)"
            )
        }
    }
    
    // MARK: - Substack (HTML Generation - Manual Copy)
    private func prepareForSubstack(post: Post, config: PlatformConfig) async -> PublishResult {
        // Substack은 공식 API가 없으므로 HTML을 클립보드에 복사
        let html = convertToSubstackHTML(post: post)
        
        await MainActor.run {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(html, forType: .html)
            pasteboard.setString(post.content, forType: .string)
        }
        
        let publicationUrl = config.additionalConfig["publicationUrl"] ?? "your-newsletter.substack.com"
        
        return PublishResult(
            platform: .substack,
            success: true,
            message: "HTML이 클립보드에 복사되었습니다. Substack 에디터에 붙여넣기 하세요.",
            url: "https://\(publicationUrl)/publish"
        )
    }
    
    private func convertToSubstackHTML(post: Post) -> String {
        var html = post.content
        
        // Basic markdown to HTML conversion
        // Headers
        html = html.replacingOccurrences(of: "(?m)^### (.+)$", with: "<h3>$1</h3>", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?m)^## (.+)$", with: "<h2>$1</h2>", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?m)^# (.+)$", with: "<h1>$1</h1>", options: .regularExpression)
        
        // Bold and italic
        html = html.replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "<strong>$1</strong>", options: .regularExpression)
        html = html.replacingOccurrences(of: "\\*(.+?)\\*", with: "<em>$1</em>", options: .regularExpression)
        
        // Links
        html = html.replacingOccurrences(of: "\\[(.+?)\\]\\((.+?)\\)", with: "<a href=\"$2\">$1</a>", options: .regularExpression)
        
        // Code blocks
        html = html.replacingOccurrences(of: "```\\w*\\n([\\s\\S]*?)```", with: "<pre><code>$1</code></pre>", options: .regularExpression)
        html = html.replacingOccurrences(of: "`(.+?)`", with: "<code>$1</code>", options: .regularExpression)
        
        // Paragraphs
        let paragraphs = html.components(separatedBy: "\n\n")
        html = paragraphs.map { p in
            if p.hasPrefix("<h") || p.hasPrefix("<pre") || p.hasPrefix("<ul") || p.hasPrefix("<ol") {
                return p
            }
            return "<p>\(p)</p>"
        }.joined(separator: "\n")
        
        return html
    }
    
    // MARK: - DEV.to
    private func publishToDevTo(post: Post, config: PlatformConfig) async -> PublishResult {
        guard !config.apiKey.isEmpty else {
            return PublishResult(
                platform: .devto,
                success: false,
                message: "API 키가 설정되지 않았습니다.",
                url: nil
            )
        }
        
        let payload: [String: Any] = [
            "article": [
                "title": post.title,
                "published": true,
                "body_markdown": post.content,
                "tags": post.tags.prefix(4).map { $0.lowercased().replacingOccurrences(of: " ", with: "") }
            ]
        ]
        
        do {
            var request = URLRequest(url: URL(string: "https://dev.to/api/articles")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(config.apiKey, forHTTPHeaderField: "api-key")
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return PublishResult(platform: .devto, success: false, message: "Invalid response", url: nil)
            }
            
            if httpResponse.statusCode == 201,
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let url = json["url"] as? String {
                return PublishResult(
                    platform: .devto,
                    success: true,
                    message: "발행 완료!",
                    url: url
                )
            }
            
            return PublishResult(
                platform: .devto,
                success: false,
                message: "발행 실패: HTTP \(httpResponse.statusCode)",
                url: nil
            )
            
        } catch {
            return PublishResult(
                platform: .devto,
                success: false,
                message: error.localizedDescription,
                url: nil
            )
        }
    }
    
    // MARK: - Medium
    private func publishToMedium(post: Post, config: PlatformConfig) async -> PublishResult {
        guard !config.apiKey.isEmpty else {
            return PublishResult(
                platform: .medium,
                success: false,
                message: "API 키가 설정되지 않았습니다.",
                url: nil
            )
        }
        
        guard let authorId = config.additionalConfig["authorId"], !authorId.isEmpty else {
            return PublishResult(
                platform: .medium,
                success: false,
                message: "Author ID가 설정되지 않았습니다.",
                url: nil
            )
        }
        
        let payload: [String: Any] = [
            "title": post.title,
            "contentFormat": "markdown",
            "content": post.content,
            "tags": Array(post.tags.prefix(5)),
            "publishStatus": "public"
        ]
        
        do {
            var request = URLRequest(url: URL(string: "https://api.medium.com/v1/users/\(authorId)/posts")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return PublishResult(platform: .medium, success: false, message: "Invalid response", url: nil)
            }
            
            if httpResponse.statusCode == 201,
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataObj = json["data"] as? [String: Any],
               let url = dataObj["url"] as? String {
                return PublishResult(
                    platform: .medium,
                    success: true,
                    message: "발행 완료!",
                    url: url
                )
            }
            
            return PublishResult(
                platform: .medium,
                success: false,
                message: "발행 실패: HTTP \(httpResponse.statusCode)",
                url: nil
            )
            
        } catch {
            return PublishResult(
                platform: .medium,
                success: false,
                message: error.localizedDescription,
                url: nil
            )
        }
    }
    
    // MARK: - Tistory
    private func publishToTistory(post: Post, config: PlatformConfig) async -> PublishResult {
        guard !config.apiKey.isEmpty else {
            return PublishResult(
                platform: .tistory,
                success: false,
                message: "Access Token이 설정되지 않았습니다.",
                url: nil
            )
        }
        
        guard let blogName = config.additionalConfig["blogName"], !blogName.isEmpty else {
            return PublishResult(
                platform: .tistory,
                success: false,
                message: "블로그 이름이 설정되지 않았습니다.",
                url: nil
            )
        }
        
        var components = URLComponents(string: "https://www.tistory.com/apis/post/write")!
        components.queryItems = [
            URLQueryItem(name: "access_token", value: config.apiKey),
            URLQueryItem(name: "output", value: "json"),
            URLQueryItem(name: "blogName", value: blogName),
            URLQueryItem(name: "title", value: post.title),
            URLQueryItem(name: "content", value: post.content),
            URLQueryItem(name: "visibility", value: "3"), // 공개
            URLQueryItem(name: "tag", value: post.tags.joined(separator: ","))
        ]
        
        do {
            var request = URLRequest(url: components.url!)
            request.httpMethod = "POST"
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return PublishResult(platform: .tistory, success: false, message: "Invalid response", url: nil)
            }
            
            if httpResponse.statusCode == 200,
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let tistory = json["tistory"] as? [String: Any],
               let status = tistory["status"] as? String,
               status == "200",
               let postId = tistory["postId"] as? String {
                return PublishResult(
                    platform: .tistory,
                    success: true,
                    message: "발행 완료!",
                    url: "https://\(blogName).tistory.com/\(postId)"
                )
            }
            
            return PublishResult(
                platform: .tistory,
                success: false,
                message: "발행 실패",
                url: nil
            )
            
        } catch {
            return PublishResult(
                platform: .tistory,
                success: false,
                message: error.localizedDescription,
                url: nil
            )
        }
    }
    
    // MARK: - Custom Platform
    private func publishToCustom(post: Post, config: PlatformConfig) async -> PublishResult {
        guard let endpoint = config.additionalConfig["apiEndpoint"], !endpoint.isEmpty else {
            return PublishResult(
                platform: .custom,
                success: false,
                message: "API Endpoint가 설정되지 않았습니다.",
                url: nil
            )
        }
        
        let payload: [String: Any] = [
            "title": post.title,
            "content": post.content,
            "tags": post.tags
        ]
        
        do {
            var request = URLRequest(url: URL(string: endpoint)!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if !config.apiKey.isEmpty {
                request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
            }
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return PublishResult(platform: .custom, success: false, message: "Invalid response", url: nil)
            }
            
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                var url: String? = nil
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    url = json["url"] as? String
                }
                return PublishResult(
                    platform: .custom,
                    success: true,
                    message: "발행 완료!",
                    url: url
                )
            }
            
            return PublishResult(
                platform: .custom,
                success: false,
                message: "발행 실패: HTTP \(httpResponse.statusCode)",
                url: nil
            )
            
        } catch {
            return PublishResult(
                platform: .custom,
                success: false,
                message: error.localizedDescription,
                url: nil
            )
        }
    }
    
    // MARK: - Helpers
    private func createSlug(from title: String, fallbackIndex: Int? = nil) -> String {
        var slug = title.lowercased()

        // 영문, 숫자, 공백, 하이픈만 남기고 나머지 제거 (한글 포함)
        // Hashnode 요구사항: ^[a-z0-9-]{1,250}$
        slug = slug.unicodeScalars.filter { scalar in
            let isLowercase = scalar.value >= 97 && scalar.value <= 122  // a-z
            let isDigit = scalar.value >= 48 && scalar.value <= 57       // 0-9
            let isSpace = scalar.value == 32                              // space
            let isHyphen = scalar.value == 45                             // -
            return isLowercase || isDigit || isSpace || isHyphen
        }.map { Character($0) }.map { String($0) }.joined()

        // 공백을 하이픈으로 변환
        slug = slug.replacingOccurrences(of: " ", with: "-")

        // 연속된 하이픈 제거
        while slug.contains("--") {
            slug = slug.replacingOccurrences(of: "--", with: "-")
        }

        // 앞뒤 하이픈 제거
        slug = slug.trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        // 빈 slug면 fallback 사용
        if slug.isEmpty {
            if let index = fallbackIndex {
                // 태그용: 고유 인덱스 기반 slug
                slug = "tag-\(index + 1)"
            } else {
                // 포스트용: 타임스탬프 기반 slug
                slug = "post-\(Int(Date().timeIntervalSince1970))"
            }
        }

        // 250자 제한
        if slug.count > 250 {
            slug = String(slug.prefix(250))
        }

        return slug
    }
}

// NSPasteboard for macOS
#if os(macOS)
import AppKit
#endif
