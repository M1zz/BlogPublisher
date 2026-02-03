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

    // MARK: - Filter State
    @Published var selectedTags: Set<String> = []
    @Published var selectedCategory: PostCategory?
    @Published var selectedPlatformFilter: String?

    // MARK: - Growth Features State
    @Published var ideas: [Idea] = []
    @Published var templates: [PostTemplate] = []
    @Published var series: [Series] = []
    @Published var writingStats: WritingStats = WritingStats()
    @Published var scheduledPublishes: [ScheduledPublish] = []

    // MARK: - UI State for New Features
    @Published var showIdeasSheet = false
    @Published var showTemplatesSheet = false
    @Published var showDashboardSheet = false
    @Published var showPomodoroSheet = false
    @Published var showSEOSheet = false
    @Published var showAITitleSheet = false
    @Published var showSeriesSheet = false
    @Published var showScheduleSheet = false

    // MARK: - Pomodoro State
    @Published var pomodoroTimeRemaining: Int = 25 * 60
    @Published var pomodoroIsRunning = false
    @Published var pomodoroSessionCount = 0
    private var pomodoroTimer: Timer?

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
        ideas = storageService.loadIdeas()
        series = storageService.loadSeries()
        writingStats = storageService.loadWritingStats()
        scheduledPublishes = storageService.loadScheduledPublishes()
        loadTemplates()
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

    func importMarkdownFile(from url: URL) {
        do {
            let post = try storageService.importPost(from: url)

            guard var project = selectedProject else { return }
            project.posts.insert(post, at: 0)
            updateProject(project)
            selectedPost = post
        } catch {
            errorMessage = "파일을 불러올 수 없습니다: \(error.localizedDescription)"
        }
    }

    // MARK: - Tag Management
    func allTags() -> [String] {
        guard let project = selectedProject else { return [] }

        var tags = Set<String>()
        for post in project.posts {
            tags.formUnion(post.tags)
        }
        return tags.sorted()
    }

    func toggleTagFilter(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    func clearTagFilters() {
        selectedTags.removeAll()
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

                // Record stats for streak tracking
                recordPublish(postId: post.id, platform: platform.platformType.rawValue)
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

    // MARK: - Idea Actions
    func createIdea(title: String, description: String = "", tags: [String] = [], priority: IdeaPriority = .medium) {
        let idea = Idea(title: title, description: description, tags: tags, priority: priority)
        ideas.insert(idea, at: 0)
        saveIdeas()
    }

    func updateIdea(_ idea: Idea) {
        if let index = ideas.firstIndex(where: { $0.id == idea.id }) {
            var updated = idea
            updated.updatedAt = Date()
            ideas[index] = updated
            saveIdeas()
        }
    }

    func deleteIdea(_ idea: Idea) {
        ideas.removeAll { $0.id == idea.id }
        saveIdeas()
    }

    func convertIdeaToPost(_ idea: Idea) {
        guard var project = selectedProject else { return }

        let post = Post(
            title: idea.title,
            content: idea.description,
            tags: idea.tags
        )
        project.posts.insert(post, at: 0)
        updateProject(project)
        selectedPost = post

        // 아이디어 상태 업데이트
        var updatedIdea = idea
        updatedIdea.status = .completed
        updateIdea(updatedIdea)
    }

    func saveIdeas() {
        storageService.saveIdeas(ideas)
    }

    // MARK: - Template Actions
    func loadTemplates() {
        var loadedTemplates = storageService.loadTemplates()

        // 기본 템플릿이 없으면 추가
        let builtInIds = Set(PostTemplate.builtInTemplates.map { $0.name })
        let existingBuiltIns = Set(loadedTemplates.filter { $0.isBuiltIn }.map { $0.name })

        for builtIn in PostTemplate.builtInTemplates {
            if !existingBuiltIns.contains(builtIn.name) {
                loadedTemplates.append(builtIn)
            }
        }

        templates = loadedTemplates
        saveTemplates()
    }

    func createTemplate(name: String, description: String, content: String, category: PostCategory, tags: [String]) {
        let template = PostTemplate(
            name: name,
            description: description,
            content: content,
            category: category,
            tags: tags
        )
        templates.append(template)
        saveTemplates()
    }

    func updateTemplate(_ template: PostTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
            saveTemplates()
        }
    }

    func deleteTemplate(_ template: PostTemplate) {
        // 빌트인 템플릿은 삭제 불가
        guard !template.isBuiltIn else { return }
        templates.removeAll { $0.id == template.id }
        saveTemplates()
    }

    func createPostFromTemplate(_ template: PostTemplate) {
        guard var project = selectedProject else { return }

        let post = Post(
            title: template.name,
            content: template.content,
            tags: template.tags,
            category: template.category
        )
        project.posts.insert(post, at: 0)
        updateProject(project)
        selectedPost = post
    }

    func saveTemplates() {
        storageService.saveTemplates(templates)
    }

    // MARK: - Series Actions
    func createSeries(name: String, description: String) {
        let newSeries = Series(name: name, description: description)
        series.append(newSeries)
        saveSeries()
    }

    func addPostToSeries(_ post: Post, series: inout Series) {
        if !series.postIds.contains(post.id) {
            series.postIds.append(post.id)
            updateSeries(series)
        }
    }

    func removePostFromSeries(_ post: Post, series: inout Series) {
        series.postIds.removeAll { $0 == post.id }
        updateSeries(series)
    }

    func updateSeries(_ updatedSeries: Series) {
        if let index = series.firstIndex(where: { $0.id == updatedSeries.id }) {
            var s = updatedSeries
            s.updatedAt = Date()
            series[index] = s
            saveSeries()
        }
    }

    func deleteSeries(_ s: Series) {
        series.removeAll { $0.id == s.id }
        saveSeries()
    }

    func saveSeries() {
        storageService.saveSeries(series)
    }

    // MARK: - Writing Stats Actions
    func recordPublish(postId: UUID, platform: String) {
        writingStats.recordPublish(postId: postId, platform: platform)
        saveWritingStats()
    }

    func saveWritingStats() {
        storageService.saveWritingStats(writingStats)
    }

    // MARK: - Schedule Actions
    func schedulePublish(postId: UUID, platformIds: [UUID], at date: Date) {
        let schedule = ScheduledPublish(postId: postId, platformIds: platformIds, scheduledAt: date)
        scheduledPublishes.append(schedule)
        saveSchedules()
    }

    func cancelSchedule(_ schedule: ScheduledPublish) {
        if let index = scheduledPublishes.firstIndex(where: { $0.id == schedule.id }) {
            scheduledPublishes[index].status = .cancelled
            saveSchedules()
        }
    }

    func saveSchedules() {
        storageService.saveScheduledPublishes(scheduledPublishes)
    }

    // MARK: - Pomodoro Timer
    func startPomodoro(minutes: Int = 25) {
        pomodoroTimeRemaining = minutes * 60
        pomodoroIsRunning = true
        pomodoroTimer?.invalidate()
        pomodoroTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.pomodoroTimeRemaining > 0 {
                    self.pomodoroTimeRemaining -= 1
                } else {
                    self.pomodoroCompleted()
                }
            }
        }
    }

    func pausePomodoro() {
        pomodoroIsRunning = false
        pomodoroTimer?.invalidate()
    }

    func resetPomodoro() {
        pomodoroIsRunning = false
        pomodoroTimer?.invalidate()
        pomodoroTimeRemaining = 25 * 60
    }

    private func pomodoroCompleted() {
        pomodoroIsRunning = false
        pomodoroTimer?.invalidate()
        pomodoroSessionCount += 1
        // TODO: 알림 표시
    }

    // MARK: - SEO & Readability Analysis
    func analyzeSEO(for post: Post, keyword: String) -> SEOAnalysis {
        let content = post.content
        let title = post.title

        // 제목 분석
        let titleLength = title.count
        let titleHasKeyword = title.localizedCaseInsensitiveContains(keyword)
        var titleScore = 0
        var titleFeedback = ""

        if titleLength >= 30 && titleLength <= 60 {
            titleScore = 100
            titleFeedback = "제목 길이가 적절합니다."
        } else if titleLength < 30 {
            titleScore = 60
            titleFeedback = "제목이 너무 짧습니다. 30-60자를 권장합니다."
        } else {
            titleScore = 70
            titleFeedback = "제목이 너무 깁니다. 60자 이내를 권장합니다."
        }

        if titleHasKeyword {
            titleScore = min(100, titleScore + 20)
        } else {
            titleScore = max(0, titleScore - 20)
            titleFeedback += " 제목에 키워드를 포함하세요."
        }

        // 콘텐츠 분석
        let words = content.split(separator: " ")
        let wordCount = words.count
        let paragraphs = content.components(separatedBy: "\n\n")
        let paragraphCount = paragraphs.count
        let hasHeadings = content.contains("## ") || content.contains("### ")
        let hasImages = content.contains("![")
        let readingTime = wordCount / 200 // 분당 200단어 기준

        var contentScore = 0
        var contentFeedback = ""

        if wordCount >= 300 {
            contentScore = 80
            contentFeedback = "콘텐츠 길이가 적절합니다."
        } else {
            contentScore = 50
            contentFeedback = "콘텐츠가 짧습니다. 300단어 이상을 권장합니다."
        }

        if hasHeadings { contentScore += 10 }
        if hasImages { contentScore += 10 }

        // 키워드 분석
        let keywordCount = content.lowercased().components(separatedBy: keyword.lowercased()).count - 1
        let density = wordCount > 0 ? Double(keywordCount) / Double(wordCount) * 100 : 0

        var keywordScore = 0
        var keywordFeedback = ""

        if density >= 1.0 && density <= 3.0 {
            keywordScore = 100
            keywordFeedback = "키워드 밀도가 적절합니다."
        } else if density < 1.0 {
            keywordScore = 60
            keywordFeedback = "키워드 사용이 부족합니다. 1-3%를 권장합니다."
        } else {
            keywordScore = 50
            keywordFeedback = "키워드 과다 사용입니다. 자연스러운 문장을 유지하세요."
        }

        // 종합 점수
        let totalScore = (titleScore + contentScore + keywordScore) / 3

        // 제안
        var suggestions: [String] = []
        if !titleHasKeyword { suggestions.append("제목에 '\(keyword)' 키워드를 포함하세요.") }
        if wordCount < 300 { suggestions.append("콘텐츠를 300단어 이상으로 확장하세요.") }
        if !hasHeadings { suggestions.append("## 또는 ### 제목을 추가하여 구조화하세요.") }
        if !hasImages { suggestions.append("이미지를 추가하여 가독성을 높이세요.") }
        if density < 1.0 { suggestions.append("'\(keyword)' 키워드를 더 자연스럽게 사용하세요.") }

        return SEOAnalysis(
            score: totalScore,
            titleScore: SEOAnalysis.TitleAnalysis(
                length: titleLength,
                hasKeyword: titleHasKeyword,
                score: titleScore,
                feedback: titleFeedback
            ),
            contentScore: SEOAnalysis.ContentAnalysis(
                wordCount: wordCount,
                paragraphCount: paragraphCount,
                hasHeadings: hasHeadings,
                hasImages: hasImages,
                readingTime: readingTime,
                score: contentScore,
                feedback: contentFeedback
            ),
            keywordScore: SEOAnalysis.KeywordAnalysis(
                keyword: keyword,
                density: density,
                count: keywordCount,
                score: keywordScore,
                feedback: keywordFeedback
            ),
            suggestions: suggestions
        )
    }

    func analyzeReadability(for post: Post) -> ReadabilityAnalysis {
        let content = post.content

        // 문장 분리
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        // 단락 분리
        let paragraphs = content.components(separatedBy: "\n\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        // 평균 문장 길이
        let totalSentenceWords = sentences.reduce(0) { $0 + $1.split(separator: " ").count }
        let avgSentenceLength = sentences.isEmpty ? 0 : Double(totalSentenceWords) / Double(sentences.count)

        // 평균 단락 길이
        let totalParagraphSentences = paragraphs.reduce(0) { count, para in
            count + para.components(separatedBy: CharacterSet(charactersIn: ".!?")).filter { !$0.isEmpty }.count
        }
        let avgParagraphLength = paragraphs.isEmpty ? 0 : Double(totalParagraphSentences) / Double(paragraphs.count)

        // 복잡한 문장 수 (20단어 이상)
        let complexSentences = sentences.filter { $0.split(separator: " ").count > 20 }.count

        // 점수 계산
        var score = 100

        if avgSentenceLength > 25 {
            score -= 20
        } else if avgSentenceLength > 20 {
            score -= 10
        }

        if complexSentences > sentences.count / 3 {
            score -= 15
        }

        // 등급 결정
        let grade: ReadabilityGrade
        if score >= 80 {
            grade = .easy
        } else if score >= 60 {
            grade = .medium
        } else {
            grade = .hard
        }

        // 제안
        var suggestions: [String] = []
        if avgSentenceLength > 20 {
            suggestions.append("문장을 더 짧게 나누세요. (평균 15-20단어 권장)")
        }
        if complexSentences > 0 {
            suggestions.append("\(complexSentences)개의 긴 문장을 단순화하세요.")
        }
        if avgParagraphLength > 5 {
            suggestions.append("단락을 더 짧게 나누세요. (3-5문장 권장)")
        }

        return ReadabilityAnalysis(
            score: score,
            grade: grade,
            avgSentenceLength: avgSentenceLength,
            avgParagraphLength: avgParagraphLength,
            complexSentences: complexSentences,
            suggestions: suggestions
        )
    }

    // MARK: - AI Title Suggestions
    func generateTitleSuggestions(for post: Post) async throws -> [String] {
        guard !settings.claudeApiKey.isEmpty else {
            throw ClaudeError.missingAPIKey
        }

        let prompt = """
        다음 블로그 글의 내용을 바탕으로 클릭율이 높은 제목 5개를 제안해주세요.

        글 내용:
        \(post.content.prefix(2000))

        규칙:
        1. 각 제목은 새 줄에 작성
        2. 숫자나 목록 기호 없이 제목만 작성
        3. 40-60자 사이로 작성
        4. 호기심을 자극하거나 가치를 명확히 전달
        5. 한국어로 작성
        """

        let response = try await claudeService.sendMessage(prompt, context: "", history: [])

        let titles = response.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("-") && !$0.hasPrefix("*") }
            .prefix(5)

        return Array(titles)
    }

    // MARK: - Thread/Social Media Conversion
    func convertToTwitterThread(post: Post, maxLength: Int = 280) -> [String] {
        let content = post.content

        // 마크다운 문법 제거
        var cleanContent = content
            .replacingOccurrences(of: "```[\\s\\S]*?```", with: "[코드]", options: .regularExpression)
            .replacingOccurrences(of: "#+ ", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\*\\*([^*]+)\\*\\*", with: "$1", options: .regularExpression)
            .replacingOccurrences(of: "\\*([^*]+)\\*", with: "$1", options: .regularExpression)
            .replacingOccurrences(of: "\\[([^\\]]+)\\]\\([^)]+\\)", with: "$1", options: .regularExpression)

        var threads: [String] = []

        // 첫 번째 스레드: 제목 + 인트로
        threads.append("[\(post.title)]\n\n스레드로 정리합니다.")

        // 단락별로 분리
        let paragraphs = cleanContent.components(separatedBy: "\n\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        var currentThread = ""
        for para in paragraphs {
            let trimmed = para.trimmingCharacters(in: .whitespaces)
            if currentThread.count + trimmed.count + 2 <= maxLength - 10 { // 여유 공간
                currentThread += (currentThread.isEmpty ? "" : "\n\n") + trimmed
            } else {
                if !currentThread.isEmpty {
                    threads.append(currentThread)
                }
                // 너무 긴 단락은 분할
                if trimmed.count > maxLength - 10 {
                    let words = trimmed.split(separator: " ")
                    var chunk = ""
                    for word in words {
                        if chunk.count + word.count + 1 <= maxLength - 10 {
                            chunk += (chunk.isEmpty ? "" : " ") + word
                        } else {
                            threads.append(chunk)
                            chunk = String(word)
                        }
                    }
                    currentThread = chunk
                } else {
                    currentThread = trimmed
                }
            }
        }

        if !currentThread.isEmpty {
            threads.append(currentThread)
        }

        // 마지막 스레드: CTA
        threads.append("전체 글은 블로그에서 확인하세요!")

        // 번호 추가
        return threads.enumerated().map { index, thread in
            "\(index + 1)/\(threads.count)\n\n\(thread)"
        }
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
