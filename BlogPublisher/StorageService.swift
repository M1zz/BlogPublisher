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
}
