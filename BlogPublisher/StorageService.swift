import Foundation

class StorageService {
    private let fileManager = FileManager.default
    
    private var appSupportDirectory: URL {
        let paths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = paths[0].appendingPathComponent("BlogPublisher", isDirectory: true)
        
        if !fileManager.fileExists(atPath: appSupport.path) {
            try? fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }
        
        return appSupport
    }
    
    private var projectsFile: URL {
        appSupportDirectory.appendingPathComponent("projects.json")
    }
    
    private var settingsFile: URL {
        appSupportDirectory.appendingPathComponent("settings.json")
    }

    private var ideasFile: URL {
        appSupportDirectory.appendingPathComponent("ideas.json")
    }

    private var templatesFile: URL {
        appSupportDirectory.appendingPathComponent("templates.json")
    }

    private var seriesFile: URL {
        appSupportDirectory.appendingPathComponent("series.json")
    }

    private var statsFile: URL {
        appSupportDirectory.appendingPathComponent("stats.json")
    }

    private var schedulesFile: URL {
        appSupportDirectory.appendingPathComponent("schedules.json")
    }
    
    // MARK: - Projects
    func loadProjects() -> [Project] {
        guard fileManager.fileExists(atPath: projectsFile.path),
              let data = try? Data(contentsOf: projectsFile),
              let projects = try? JSONDecoder().decode([Project].self, from: data) else {
            return []
        }
        return projects
    }
    
    func saveProjects(_ projects: [Project]) {
        guard let data = try? JSONEncoder().encode(projects) else { return }
        try? data.write(to: projectsFile)
    }
    
    // MARK: - Settings
    func loadSettings() -> AppSettings {
        guard fileManager.fileExists(atPath: settingsFile.path),
              let data = try? Data(contentsOf: settingsFile),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }
    
    func saveSettings(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        try? data.write(to: settingsFile)
    }
    
    // MARK: - Ideas
    func loadIdeas() -> [Idea] {
        guard fileManager.fileExists(atPath: ideasFile.path),
              let data = try? Data(contentsOf: ideasFile),
              let ideas = try? JSONDecoder().decode([Idea].self, from: data) else {
            return []
        }
        return ideas
    }

    func saveIdeas(_ ideas: [Idea]) {
        guard let data = try? JSONEncoder().encode(ideas) else { return }
        try? data.write(to: ideasFile)
    }

    // MARK: - Templates
    func loadTemplates() -> [PostTemplate] {
        guard fileManager.fileExists(atPath: templatesFile.path),
              let data = try? Data(contentsOf: templatesFile),
              let templates = try? JSONDecoder().decode([PostTemplate].self, from: data) else {
            return []
        }
        return templates
    }

    func saveTemplates(_ templates: [PostTemplate]) {
        guard let data = try? JSONEncoder().encode(templates) else { return }
        try? data.write(to: templatesFile)
    }

    // MARK: - Series
    func loadSeries() -> [Series] {
        guard fileManager.fileExists(atPath: seriesFile.path),
              let data = try? Data(contentsOf: seriesFile),
              let series = try? JSONDecoder().decode([Series].self, from: data) else {
            return []
        }
        return series
    }

    func saveSeries(_ series: [Series]) {
        guard let data = try? JSONEncoder().encode(series) else { return }
        try? data.write(to: seriesFile)
    }

    // MARK: - Writing Stats
    func loadWritingStats() -> WritingStats {
        guard fileManager.fileExists(atPath: statsFile.path),
              let data = try? Data(contentsOf: statsFile),
              let stats = try? JSONDecoder().decode(WritingStats.self, from: data) else {
            return WritingStats()
        }
        return stats
    }

    func saveWritingStats(_ stats: WritingStats) {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        try? data.write(to: statsFile)
    }

    // MARK: - Scheduled Publishes
    func loadScheduledPublishes() -> [ScheduledPublish] {
        guard fileManager.fileExists(atPath: schedulesFile.path),
              let data = try? Data(contentsOf: schedulesFile),
              let schedules = try? JSONDecoder().decode([ScheduledPublish].self, from: data) else {
            return []
        }
        return schedules
    }

    func saveScheduledPublishes(_ schedules: [ScheduledPublish]) {
        guard let data = try? JSONEncoder().encode(schedules) else { return }
        try? data.write(to: schedulesFile)
    }

    // MARK: - Export/Import
    func exportPost(_ post: Post, to url: URL) throws {
        let markdown = """
        ---
        title: \(post.title)
        subtitle: \(post.subtitle)
        tags: \(post.tags.joined(separator: ", "))
        status: \(post.status.rawValue)
        created: \(ISO8601DateFormatter().string(from: post.createdAt))
        updated: \(ISO8601DateFormatter().string(from: post.updatedAt))
        ---
        
        \(post.content)
        """
        
        try markdown.write(to: url, atomically: true, encoding: .utf8)
    }
    
    func importPost(from url: URL) throws -> Post {
        let content = try String(contentsOf: url, encoding: .utf8)
        
        var post = Post()
        
        // Parse frontmatter
        if content.hasPrefix("---") {
            let parts = content.components(separatedBy: "---")
            if parts.count >= 3 {
                let frontmatter = parts[1]
                let body = parts.dropFirst(2).joined(separator: "---").trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Parse frontmatter fields
                for line in frontmatter.components(separatedBy: "\n") {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if let colonIndex = trimmed.firstIndex(of: ":") {
                        let key = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                        let value = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                        
                        switch key {
                        case "title": post.title = value
                        case "subtitle": post.subtitle = value
                        case "tags": post.tags = value.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                        default: break
                        }
                    }
                }
                
                post.content = body
            }
        } else {
            post.content = content
            post.title = url.deletingPathExtension().lastPathComponent
        }
        
        return post
    }
    
    // MARK: - Backup
    func createBackup() throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())

        let backupDir = appSupportDirectory.appendingPathComponent("Backups", isDirectory: true)
        if !fileManager.fileExists(atPath: backupDir.path) {
            try fileManager.createDirectory(at: backupDir, withIntermediateDirectories: true)
        }

        let backupFile = backupDir.appendingPathComponent("backup_\(timestamp).json")

        let backupData: [String: Any] = [
            "projects": loadProjects(),
            "settings": loadSettings(),
            "timestamp": timestamp
        ]

        let data = try JSONSerialization.data(withJSONObject: backupData, options: .prettyPrinted)
        try data.write(to: backupFile)

        return backupFile
    }

    // MARK: - Resources
    func loadMarkdownFilesFromResources() -> [URL] {
        // Bundle의 Resources 폴더에서 직접 마크다운 파일 찾기
        guard let resourcesPath = Bundle.main.resourcePath else {
            print("❌ Bundle의 resourcePath를 찾을 수 없습니다")
            return []
        }

        let resourcesURL = URL(fileURLWithPath: resourcesPath)
        print("📂 Resources 경로: \(resourcesURL.path)")

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: resourcesURL,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )

            let markdownFiles = contents.filter { $0.pathExtension == "md" }
                .sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                    return date1 > date2 // 최신순
                }

            print("📝 발견한 마크다운 파일 (\(markdownFiles.count)개):")
            markdownFiles.forEach { print("   - \($0.lastPathComponent)") }
            return markdownFiles
        } catch {
            print("❌ 폴더 읽기 실패: \(error)")
            print("시도한 경로: \(resourcesURL.path)")
            return []
        }
    }
}
