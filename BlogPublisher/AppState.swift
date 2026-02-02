import Foundation
import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published var projects: [Project] = []
    @Published var selectedProject: Project?
    @Published var selectedPost: Post?
    @Published var settings: AppSettings = AppSettings()
    
    // MARK: - UI State
    @Published var showNewProjectSheet = false
    @Published var showNewPlatformSheet = false
    @Published var showSettingsSheet = false
    @Published var showPublishSheet = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var publishResults: [PublishResult] = []
    
    // MARK: - Services
    let claudeService = ClaudeService()
    let platformService = PlatformService()
    let storageService = StorageService()

    // MARK: - File Monitoring
    private var fileMonitorTimer: Timer?
    private var lastCheckedFiles: [URL: Date] = [:]
    
    // MARK: - Initialization
    init() {
        loadData()
        startFileMonitoring()
    }
    
    // MARK: - Data Management
    func loadData() {
        projects = storageService.loadProjects()
        settings = storageService.loadSettings()
        Task { await claudeService.setApiKey(settings.claudeApiKey) }

        // 기본 프로젝트가 없으면 생성
        if projects.isEmpty {
            let samplePost = Post(
                title: "초보 Swift 개발자가 하기 쉬운 실수 10가지",
                content: Self.samplePostContent,
                subtitle: "Swift를 처음 배우는 개발자들이 자주 겪는 실수와 해결 방법",
                tags: ["Swift", "iOS", "초보자", "팁"]
            )

            var devProject = Project(
                name: "개발 블로그",
                description: "iOS, Swift, SwiftUI 개발 관련 포스트",
                icon: "chevron.left.forwardslash.chevron.right",
                color: "blue"
            )
            devProject.posts = [samplePost]

            let growthProject = Project(
                name: "성장 뉴스레터",
                description: "뇌과학, 생산성, 학습 관련 뉴스레터",
                icon: "brain.head.profile",
                color: "purple"
            )
            projects = [devProject, growthProject]
            saveProjects()
        } else {
            // 기존 프로젝트가 있어도 "개발 블로그"에 글이 없으면 샘플 추가
            if let index = projects.firstIndex(where: { $0.name == "개발 블로그" }),
               projects[index].posts.isEmpty {
                let samplePost = Post(
                    title: "초보 Swift 개발자가 하기 쉬운 실수 10가지",
                    content: Self.samplePostContent,
                    subtitle: "Swift를 처음 배우는 개발자들이 자주 겪는 실수와 해결 방법",
                    tags: ["Swift", "iOS", "초보자", "팁"]
                )
                projects[index].posts = [samplePost]
                saveProjects()
            }
        }

        selectedProject = projects.first
        // 첫 번째 글 자동 선택
        if let firstPost = selectedProject?.posts.first {
            selectedPost = firstPost
        }
    }
    
    func saveProjects() {
        storageService.saveProjects(projects)
    }
    
    func saveSettings() {
        storageService.saveSettings(settings)
        Task { await claudeService.setApiKey(settings.claudeApiKey) }
    }
    
    // MARK: - Project Actions
    func createProject(name: String, description: String, icon: String, color: String) {
        let project = Project(
            name: name,
            description: description,
            icon: icon,
            color: color
        )
        projects.append(project)
        selectedProject = project
        saveProjects()
    }
    
    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        if selectedProject?.id == project.id {
            selectedProject = projects.first
        }
        saveProjects()
    }
    
    func updateProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
            if selectedProject?.id == project.id {
                selectedProject = project
            }
            saveProjects()
        }
    }
    
    // MARK: - Post Actions
    func createNewPost() {
        guard var project = selectedProject else { return }
        
        let post = Post()
        project.posts.insert(post, at: 0)
        updateProject(project)
        selectedPost = post
    }
    
    func updatePost(_ post: Post) {
        guard var project = selectedProject,
              let index = project.posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        var updatedPost = post
        updatedPost.updatedAt = Date()
        project.posts[index] = updatedPost
        updateProject(project)
        selectedPost = updatedPost
    }
    
    func deletePost(_ post: Post) {
        guard var project = selectedProject else { return }
        
        project.posts.removeAll { $0.id == post.id }
        updateProject(project)
        
        if selectedPost?.id == post.id {
            selectedPost = project.posts.first
        }
    }
    
    // MARK: - Platform Actions
    func addPlatform(_ config: PlatformConfig) {
        guard var project = selectedProject else { return }
        project.platforms.append(config)
        updateProject(project)
    }
    
    func updatePlatform(_ config: PlatformConfig) {
        guard var project = selectedProject,
              let index = project.platforms.firstIndex(where: { $0.id == config.id }) else { return }
        project.platforms[index] = config
        updateProject(project)
    }
    
    func deletePlatform(_ config: PlatformConfig) {
        guard var project = selectedProject else { return }
        project.platforms.removeAll { $0.id == config.id }
        updateProject(project)
    }
    
    // MARK: - Publishing
    func publishToSelectedPlatforms() {
        showPublishSheet = true
    }
    
    func publishToAllPlatforms() {
        guard let project = selectedProject,
              let post = selectedPost else { return }
        
        Task {
            await publishPost(post, to: project.platforms.filter { $0.isEnabled })
        }
    }
    
    func publishPost(_ post: Post, to platforms: [PlatformConfig]) async {
        isLoading = true
        publishResults = []
        
        for platform in platforms {
            let result = await platformService.publish(post: post, to: platform)
            publishResults.append(result)
            
            if result.success {
                var updatedPost = post
                if !updatedPost.publishedPlatforms.contains(platform.platformType.rawValue) {
                    updatedPost.publishedPlatforms.append(platform.platformType.rawValue)
                }
                updatedPost.status = .published
                updatePost(updatedPost)
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Claude Chat
    func sendMessage(_ content: String) async {
        guard var post = selectedPost else { return }
        
        // Add user message
        let userMessage = ChatMessage(role: .user, content: content)
        post.chatHistory.append(userMessage)
        updatePost(post)
        
        isLoading = true
        
        do {
            let response = try await claudeService.sendMessage(
                content,
                context: post.content,
                history: post.chatHistory.dropLast()
            )
            
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            post.chatHistory.append(assistantMessage)
            updatePost(post)
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func applyAIContent(_ content: String) {
        guard var post = selectedPost else { return }
        post.content = content
        updatePost(post)
    }

    // MARK: - File Monitoring
    func startFileMonitoring() {
        // 2초마다 Resources 폴더 체크
        fileMonitorTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForFileChanges()
            }
        }
    }

    func stopFileMonitoring() {
        fileMonitorTimer?.invalidate()
        fileMonitorTimer = nil
    }

    private func checkForFileChanges() {
        let markdownFiles = storageService.loadMarkdownFilesFromResources()
        print("🔍 파일 체크 시작: \(markdownFiles.count)개 파일")

        for fileURL in markdownFiles {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.contentModificationDateKey])
                guard let modificationDate = resourceValues.contentModificationDate else { continue }

                // 새 파일이거나 수정된 파일인 경우
                if lastCheckedFiles[fileURL] == nil || lastCheckedFiles[fileURL]! < modificationDate {
                    lastCheckedFiles[fileURL] = modificationDate

                    // 파일 내용 읽기
                    let content = try String(contentsOf: fileURL, encoding: .utf8)

                    // 마크다운에서 제목 추출 (첫 번째 # 라인)
                    let title = extractTitleFromMarkdown(content) ?? fileURL.deletingPathExtension().lastPathComponent

                    print("📄 새 파일 발견/수정: \(fileURL.lastPathComponent) -> 제목: \(title)")

                    // "개발 블로그" 프로젝트 찾기
                    guard var project = projects.first(where: { $0.name == "개발 블로그" }) else {
                        print("⚠️ '개발 블로그' 프로젝트를 찾을 수 없습니다")
                        continue
                    }

                    // 같은 제목의 글이 이미 있는지 확인
                    if let existingPostIndex = project.posts.firstIndex(where: { $0.title == title }) {
                        // 기존 글 업데이트
                        print("♻️ 기존 글 업데이트: \(title)")
                        var existingPost = project.posts[existingPostIndex]
                        existingPost.content = content
                        existingPost.updatedAt = Date()
                        project.posts[existingPostIndex] = existingPost
                        updateProject(project)

                        // 현재 선택된 글이면 업데이트
                        if selectedPost?.id == existingPost.id {
                            selectedPost = existingPost
                        }
                    } else {
                        // 새 글 추가
                        print("✨ 새 글 추가: \(title)")
                        let newPost = Post(
                            title: title,
                            content: content,
                            subtitle: "",
                            tags: ["블로그"]
                        )
                        project.posts.insert(newPost, at: 0)
                        updateProject(project)

                        // 자동으로 새 글 선택
                        selectedPost = newPost
                    }
                }
            } catch {
                print("❌ 파일 체크 실패 (\(fileURL.lastPathComponent)): \(error)")
            }
        }
    }

    // 마크다운에서 제목 추출
    private func extractTitleFromMarkdown(_ content: String) -> String? {
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("# ") {
                return trimmed.replacingOccurrences(of: "# ", with: "")
            }
        }
        return nil
    }

    // MARK: - Sample Content
    private static var samplePostContent: String {
        // Bundle에서 SamplePost.md 파일 로드 시도
        if let url = Bundle.main.url(forResource: "SamplePost", withExtension: "md"),
           let content = try? String(contentsOf: url, encoding: .utf8) {
            return content
        }

        // Fallback 콘텐츠
        return """
# 초보 Swift 개발자가 하기 쉬운 실수 10가지

Swift를 처음 배우는 개발자들이 자주 겪는 실수들을 정리했습니다.

## 1. 강제 언래핑 남용

```swift
// ❌ 위험
let name: String? = nil
print(name!) // 크래시!

// ✅ 안전
print(name ?? "기본값")
```

## 2. 순환 참조 (Retain Cycle)

```swift
// ❌ 메모리 누수
onComplete = { self.doSomething() }

// ✅ weak self 사용
onComplete = { [weak self] in self?.doSomething() }
```

## 3. struct와 class 차이

```swift
// struct: 값 복사
var point2 = point1
point2.x = 10  // point1은 변경 안됨

// class: 참조 공유
var loc2 = loc1
loc2.x = 10  // loc1도 변경됨!
```

## 4. 메인 스레드에서 UI 업데이트

```swift
// ❌ 백그라운드에서 UI 변경
URLSession.shared.dataTask { data, _, _ in
    self.label.text = "완료"  // 문제!
}

// ✅ 메인 스레드에서 변경
DispatchQueue.main.async {
    self.label.text = "완료"
}
```

## 5. 옵셔널 체이닝 결과

```swift
let city = user.address?.city  // String? 타입!

// ✅ 안전하게 사용
if let city = user.address?.city {
    print(city)
}
```

---

이 실수들을 피하면 더 안전한 Swift 코드를 작성할 수 있습니다!
"""
    }
}
