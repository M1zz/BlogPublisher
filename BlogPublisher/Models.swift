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

// MARK: - Post Category
enum PostCategory: String, Codable, CaseIterable, Identifiable {
    case tutorial = "튜토리얼"
    case experience = "경험/회고"
    case review = "리뷰"
    case news = "뉴스/소식"
    case opinion = "의견/생각"
    case etc = "기타"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .tutorial: return "book.fill"
        case .experience: return "person.fill"
        case .review: return "star.fill"
        case .news: return "newspaper.fill"
        case .opinion: return "bubble.left.fill"
        case .etc: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .tutorial: return .blue
        case .experience: return .purple
        case .review: return .orange
        case .news: return .green
        case .opinion: return .pink
        case .etc: return .gray
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
    var category: PostCategory
    var seoTitle: String
    var seoDescription: String

    init(
        id: UUID = UUID(),
        title: String = "제목 없음",
        content: String = "",
        subtitle: String = "",
        tags: [String] = [],
        coverImageURL: String? = nil,
        status: PostStatus = .draft,
        category: PostCategory = .etc,
        seoTitle: String = "",
        seoDescription: String = ""
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
        self.category = category
        self.seoTitle = seoTitle
        self.seoDescription = seoDescription
    }

    // 기존 데이터 호환을 위한 커스텀 디코딩
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        tags = try container.decode([String].self, forKey: .tags)
        coverImageURL = try container.decodeIfPresent(String.self, forKey: .coverImageURL)
        status = try container.decode(PostStatus.self, forKey: .status)
        publishedPlatforms = try container.decode([String].self, forKey: .publishedPlatforms)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        chatHistory = try container.decode([ChatMessage].self, forKey: .chatHistory)
        category = try container.decodeIfPresent(PostCategory.self, forKey: .category) ?? .etc
        seoTitle = try container.decodeIfPresent(String.self, forKey: .seoTitle) ?? ""
        seoDescription = try container.decodeIfPresent(String.self, forKey: .seoDescription) ?? ""
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, content, subtitle, tags, coverImageURL, status
        case publishedPlatforms, createdAt, updatedAt, chatHistory
        case category, seoTitle, seoDescription
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

// MARK: - Idea Model (아이디어 저장소)
struct Idea: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var tags: [String]
    var priority: IdeaPriority
    var status: IdeaStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        tags: [String] = [],
        priority: IdeaPriority = .medium,
        status: IdeaStatus = .new
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.tags = tags
        self.priority = priority
        self.status = status
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum IdeaPriority: String, Codable, CaseIterable {
    case high = "높음"
    case medium = "보통"
    case low = "낮음"

    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .gray
        }
    }
}

enum IdeaStatus: String, Codable, CaseIterable {
    case new = "새 아이디어"
    case inProgress = "작성 중"
    case completed = "완료"
    case archived = "보관"

    var icon: String {
        switch self {
        case .new: return "lightbulb.fill"
        case .inProgress: return "pencil"
        case .completed: return "checkmark.circle.fill"
        case .archived: return "archivebox.fill"
        }
    }
}

// MARK: - Template Model (글 템플릿)
struct PostTemplate: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var content: String
    var category: PostCategory
    var tags: [String]
    var icon: String
    var isBuiltIn: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        content: String,
        category: PostCategory = .etc,
        tags: [String] = [],
        icon: String = "doc.text.fill",
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.content = content
        self.category = category
        self.tags = tags
        self.icon = icon
        self.isBuiltIn = isBuiltIn
        self.createdAt = Date()
    }

    // 기본 제공 템플릿
    static var builtInTemplates: [PostTemplate] {
        [
            PostTemplate(
                name: "TIL (Today I Learned)",
                description: "오늘 배운 내용을 정리하는 템플릿",
                content: """
                # TIL: [주제]

                ## 배운 것

                오늘 배운 핵심 내용을 정리합니다.

                ## 상세 내용

                ### 1. 첫 번째 포인트

                내용 작성...

                ### 2. 두 번째 포인트

                내용 작성...

                ## 코드 예시

                ```swift
                // 코드 예시
                ```

                ## 느낀 점

                -
                -

                ## 다음 학습 계획

                -
                """,
                category: .tutorial,
                tags: ["TIL", "학습"],
                icon: "book.fill",
                isBuiltIn: true
            ),
            PostTemplate(
                name: "튜토리얼",
                description: "단계별 가이드 작성 템플릿",
                content: """
                # [튜토리얼 제목]

                ## 개요

                이 튜토리얼에서는 [목표]를 달성하는 방법을 알아봅니다.

                ## 사전 요구사항

                - 요구사항 1
                - 요구사항 2

                ## 1단계: [단계 제목]

                설명...

                ```swift
                // 코드
                ```

                ## 2단계: [단계 제목]

                설명...

                ## 3단계: [단계 제목]

                설명...

                ## 마무리

                이 튜토리얼에서 배운 내용:
                -
                -

                ## 참고 자료

                - [링크 제목](URL)
                """,
                category: .tutorial,
                tags: ["튜토리얼", "가이드"],
                icon: "list.number",
                isBuiltIn: true
            ),
            PostTemplate(
                name: "회고",
                description: "프로젝트/기간 회고 템플릿",
                content: """
                # [기간/프로젝트] 회고

                ## 기간

                YYYY.MM.DD ~ YYYY.MM.DD

                ## 무엇을 했는가?

                ### 주요 성과
                -
                -

                ### 진행한 작업
                -
                -

                ## 잘한 점 (Keep)

                -
                -

                ## 개선할 점 (Problem)

                -
                -

                ## 시도할 것 (Try)

                -
                -

                ## 배운 점

                -
                -

                ## 다음 목표

                -
                """,
                category: .experience,
                tags: ["회고", "성장"],
                icon: "arrow.counterclockwise",
                isBuiltIn: true
            ),
            PostTemplate(
                name: "기술 리뷰",
                description: "기술/도구 리뷰 템플릿",
                content: """
                # [기술/도구 이름] 리뷰

                ## 한 줄 요약

                [핵심 평가]

                ## 개요

                - **이름**:
                - **버전**:
                - **공식 사이트**:

                ## 사용 배경

                왜 이 기술을 사용하게 되었는지...

                ## 장점

                1. **장점 1**: 설명
                2. **장점 2**: 설명
                3. **장점 3**: 설명

                ## 단점

                1. **단점 1**: 설명
                2. **단점 2**: 설명

                ## 사용 예시

                ```swift
                // 코드 예시
                ```

                ## 비교

                | 항목 | 이 기술 | 대안 |
                |------|--------|------|
                | 성능 |        |      |
                | 사용성 |      |      |

                ## 총평

                ⭐⭐⭐⭐☆ (4/5)

                [최종 평가]

                ## 추천 대상

                - 추천:
                - 비추천:
                """,
                category: .review,
                tags: ["리뷰", "기술"],
                icon: "star.fill",
                isBuiltIn: true
            ),
            PostTemplate(
                name: "문제 해결",
                description: "버그/이슈 해결 과정 기록 템플릿",
                content: """
                # [문제 제목] 해결하기

                ## 문제 상황

                ### 증상

                어떤 문제가 발생했는지...

                ### 에러 메시지

                ```
                에러 메시지
                ```

                ### 환경

                - OS:
                - 버전:

                ## 원인 분석

                ### 시도한 것들

                1. **시도 1**: 결과
                2. **시도 2**: 결과

                ### 발견한 원인

                실제 원인은...

                ## 해결 방법

                ```swift
                // 해결 코드
                ```

                ## 결과

                해결 후 상태...

                ## 배운 점

                -
                -

                ## 참고 자료

                - [링크](URL)
                """,
                category: .tutorial,
                tags: ["문제해결", "디버깅"],
                icon: "wrench.fill",
                isBuiltIn: true
            )
        ]
    }
}

// MARK: - Series Model (시리즈 관리)
struct Series: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var postIds: [UUID]
    var coverImageURL: String?
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        postIds: [UUID] = [],
        coverImageURL: String? = nil,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.postIds = postIds
        self.coverImageURL = coverImageURL
        self.isCompleted = isCompleted
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Writing Stats (글쓰기 통계)
struct WritingStats: Codable {
    var publishHistory: [PublishRecord]
    var currentStreak: Int
    var longestStreak: Int
    var totalPostsPublished: Int
    var lastPublishDate: Date?
    var dailyGoal: Int
    var weeklyGoal: Int

    init() {
        self.publishHistory = []
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalPostsPublished = 0
        self.lastPublishDate = nil
        self.dailyGoal = 1
        self.weeklyGoal = 3
    }

    mutating func recordPublish(postId: UUID, platform: String) {
        let record = PublishRecord(postId: postId, platform: platform, publishedAt: Date())
        publishHistory.append(record)
        totalPostsPublished += 1
        updateStreak()
    }

    mutating func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 오늘 발행했는지 확인
        let publishedToday = publishHistory.contains { record in
            calendar.isDate(record.publishedAt, inSameDayAs: today)
        }

        guard publishedToday else {
            // 어제 발행했는지 확인, 아니면 스트릭 리셋
            if let lastDate = lastPublishDate {
                let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
                if !calendar.isDate(lastDate, inSameDayAs: yesterday) && !calendar.isDate(lastDate, inSameDayAs: today) {
                    currentStreak = 0
                }
            }
            return
        }

        // 어제도 발행했으면 스트릭 증가, 아니면 1로 시작
        if let lastDate = lastPublishDate {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if calendar.isDate(lastDate, inSameDayAs: yesterday) {
                currentStreak += 1
            } else if !calendar.isDate(lastDate, inSameDayAs: today) {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }

        lastPublishDate = today
        longestStreak = max(longestStreak, currentStreak)
    }

    // 히트맵용 데이터 (최근 365일)
    func publishCountByDate() -> [Date: Int] {
        let calendar = Calendar.current
        var counts: [Date: Int] = [:]

        for record in publishHistory {
            let day = calendar.startOfDay(for: record.publishedAt)
            counts[day, default: 0] += 1
        }

        return counts
    }

    // 주간 발행 수
    func postsThisWeek() -> Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!

        return publishHistory.filter { record in
            record.publishedAt >= startOfWeek
        }.count
    }
}

struct PublishRecord: Codable, Hashable {
    let postId: UUID
    let platform: String
    let publishedAt: Date
}

// MARK: - Scheduled Publish (발행 예약)
struct ScheduledPublish: Identifiable, Codable, Hashable {
    let id: UUID
    var postId: UUID
    var platformIds: [UUID]
    var scheduledAt: Date
    var status: ScheduleStatus
    var createdAt: Date

    init(
        id: UUID = UUID(),
        postId: UUID,
        platformIds: [UUID],
        scheduledAt: Date
    ) {
        self.id = id
        self.postId = postId
        self.platformIds = platformIds
        self.scheduledAt = scheduledAt
        self.status = .pending
        self.createdAt = Date()
    }
}

enum ScheduleStatus: String, Codable {
    case pending = "대기 중"
    case completed = "완료"
    case failed = "실패"
    case cancelled = "취소"
}

// MARK: - SEO Analysis Result
struct SEOAnalysis {
    let score: Int // 0-100
    let titleScore: TitleAnalysis
    let contentScore: ContentAnalysis
    let keywordScore: KeywordAnalysis
    let suggestions: [String]

    struct TitleAnalysis {
        let length: Int
        let hasKeyword: Bool
        let score: Int
        let feedback: String
    }

    struct ContentAnalysis {
        let wordCount: Int
        let paragraphCount: Int
        let hasHeadings: Bool
        let hasImages: Bool
        let readingTime: Int
        let score: Int
        let feedback: String
    }

    struct KeywordAnalysis {
        let keyword: String
        let density: Double
        let count: Int
        let score: Int
        let feedback: String
    }
}

// MARK: - Readability Analysis Result
struct ReadabilityAnalysis {
    let score: Int // 0-100
    let grade: ReadabilityGrade
    let avgSentenceLength: Double
    let avgParagraphLength: Double
    let complexSentences: Int
    let suggestions: [String]
}

enum ReadabilityGrade: String {
    case easy = "쉬움"
    case medium = "보통"
    case hard = "어려움"

    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }

    var icon: String {
        switch self {
        case .easy: return "face.smiling"
        case .medium: return "face.dashed"
        case .hard: return "exclamationmark.triangle"
        }
    }
}
