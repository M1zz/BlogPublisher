import Foundation
import SwiftUI

// MARK: - Project Model
struct Project: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var icon: String
    var color: String
    var platforms: [PlatformConfig]
    var posts: [Post]
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        icon: String = "folder.fill",
        color: String = "blue",
        platforms: [PlatformConfig] = [],
        posts: [Post] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.color = color
        self.platforms = platforms
        self.posts = posts
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var projectColor: Color {
        switch color {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
}

// MARK: - Post Model
struct Post: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var content: String
    var subtitle: String
    var tags: [String]
    var coverImageURL: String?
    var status: PostStatus
    var publishedPlatforms: [String]
    var createdAt: Date
    var updatedAt: Date
    var chatHistory: [ChatMessage]
    
    init(
        id: UUID = UUID(),
        title: String = "제목 없음",
        content: String = "",
        subtitle: String = "",
        tags: [String] = [],
        coverImageURL: String? = nil,
        status: PostStatus = .draft
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.subtitle = subtitle
        self.tags = tags
        self.coverImageURL = coverImageURL
        self.status = status
        self.publishedPlatforms = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.chatHistory = []
    }
}

enum PostStatus: String, Codable, CaseIterable {
    case draft = "초안"
    case ready = "발행 준비"
    case published = "발행됨"
    case scheduled = "예약됨"
    
    var color: Color {
        switch self {
        case .draft: return .gray
        case .ready: return .orange
        case .published: return .green
        case .scheduled: return .blue
        }
    }
}

// MARK: - Platform Models
struct PlatformConfig: Identifiable, Codable, Hashable {
    let id: UUID
    var platformType: PlatformType
    var name: String
    var apiKey: String
    var additionalConfig: [String: String]
    var isEnabled: Bool
    
    init(
        id: UUID = UUID(),
        platformType: PlatformType,
        name: String = "",
        apiKey: String = "",
        additionalConfig: [String: String] = [:],
        isEnabled: Bool = true
    ) {
        self.id = id
        self.platformType = platformType
        self.name = name.isEmpty ? platformType.defaultName : name
        self.apiKey = apiKey
        self.additionalConfig = additionalConfig
        self.isEnabled = isEnabled
    }
}

enum PlatformType: String, Codable, CaseIterable, Identifiable {
    case hashnode = "hashnode"
    case substack = "substack"
    case medium = "medium"
    case devto = "devto"
    case tistory = "tistory"
    case custom = "custom"
    
    var id: String { rawValue }
    
    var defaultName: String {
        switch self {
        case .hashnode: return "Hashnode"
        case .substack: return "Substack"
        case .medium: return "Medium"
        case .devto: return "DEV.to"
        case .tistory: return "Tistory"
        case .custom: return "Custom"
        }
    }
    
    var icon: String {
        switch self {
        case .hashnode: return "h.circle.fill"
        case .substack: return "envelope.fill"
        case .medium: return "m.circle.fill"
        case .devto: return "d.circle.fill"
        case .tistory: return "t.circle.fill"
        case .custom: return "globe"
        }
    }
    
    var color: Color {
        switch self {
        case .hashnode: return .blue
        case .substack: return .orange
        case .medium: return .primary
        case .devto: return .primary
        case .tistory: return .red
        case .custom: return .purple
        }
    }
    
    var requiredFields: [PlatformField] {
        switch self {
        case .hashnode:
            return [
                PlatformField(key: "publicationId", label: "Publication ID", placeholder: "대시보드 URL에서 확인"),
            ]
        case .substack:
            return [
                PlatformField(key: "publicationUrl", label: "Publication URL", placeholder: "your-newsletter.substack.com"),
            ]
        case .medium:
            return [
                PlatformField(key: "authorId", label: "Author ID", placeholder: "Settings에서 확인"),
            ]
        case .devto:
            return []
        case .tistory:
            return [
                PlatformField(key: "blogName", label: "블로그 이름", placeholder: "blogname.tistory.com의 blogname"),
            ]
        case .custom:
            return [
                PlatformField(key: "apiEndpoint", label: "API Endpoint", placeholder: "https://..."),
            ]
        }
    }
    
    var supportsDirectPublish: Bool {
        switch self {
        case .hashnode, .devto, .medium, .tistory: return true
        case .substack, .custom: return false
        }
    }
}

struct PlatformField: Identifiable {
    let id = UUID()
    let key: String
    let label: String
    let placeholder: String
}

// MARK: - Chat Models
struct ChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    let role: ChatRole
    let content: String
    let timestamp: Date
    
    init(id: UUID = UUID(), role: ChatRole, content: String) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

enum ChatRole: String, Codable {
    case user
    case assistant
    case system
}

// MARK: - App Settings
struct AppSettings: Codable {
    var claudeApiKey: String
    var defaultModel: String
    var autoSaveEnabled: Bool
    var autoSaveInterval: Int
    var theme: AppTheme
    
    init() {
        self.claudeApiKey = ""
        self.defaultModel = "claude-sonnet-4-20250514"
        self.autoSaveEnabled = true
        self.autoSaveInterval = 30
        self.theme = .system
    }
}

enum AppTheme: String, Codable, CaseIterable {
    case light = "라이트"
    case dark = "다크"
    case system = "시스템"
}

// MARK: - Publish Result
struct PublishResult: Identifiable {
    let id = UUID()
    let platform: PlatformType
    let success: Bool
    let message: String
    let url: String?
    let debugLog: String?

    init(platform: PlatformType, success: Bool, message: String, url: String?, debugLog: String? = nil) {
        self.platform = platform
        self.success = success
        self.message = message
        self.url = url
        self.debugLog = debugLog
    }
}
