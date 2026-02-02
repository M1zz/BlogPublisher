import SwiftUI
import AppKit

// MARK: - New Project Sheet
struct NewProjectSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColor = "blue"
    
    let icons = [
        "folder.fill", "doc.text.fill", "book.fill", "pencil",
        "chevron.left.forwardslash.chevron.right", "brain.head.profile",
        "lightbulb.fill", "star.fill", "heart.fill", "flame.fill"
    ]
    
    let colors = ["blue", "purple", "pink", "red", "orange", "yellow", "green"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("새 프로젝트")
                    .font(.title2.bold())
                Spacer()
                Button("취소") { dismiss() }
                    .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            Form {
                Section {
                    TextField("프로젝트 이름", text: $name)
                    TextField("설명 (선택사항)", text: $description)
                }
                
                Section("아이콘") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Section("색상") {
                    HStack(spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(colorFromString(color))
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        if selectedColor == color {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.white)
                                                .font(.caption.bold())
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            
            Divider()
            
            // Footer
            HStack {
                Spacer()
                Button("생성") {
                    appState.createProject(
                        name: name,
                        description: description,
                        icon: selectedIcon,
                        color: selectedColor
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
            .padding()
        }
        .frame(width: 450, height: 500)
    }
    
    private func colorFromString(_ string: String) -> Color {
        switch string {
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

// MARK: - Platform Management Sheet
struct NewPlatformSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var showAddPlatform = false
    @State private var platformToDelete: PlatformConfig?
    @State private var showDeleteAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("플랫폼 관리")
                    .font(.title2.bold())
                Spacer()
                Button("완료") { dismiss() }
                    .buttonStyle(.plain)
            }
            .padding()

            Divider()

            if let project = appState.selectedProject {
                if project.platforms.isEmpty && !showAddPlatform {
                    // 플랫폼 없음
                    VStack(spacing: 16) {
                        Image(systemName: "globe")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)

                        Text("등록된 플랫폼이 없습니다")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text("글을 발행할 플랫폼을 추가하세요")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Button("플랫폼 추가") {
                            showAddPlatform = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if showAddPlatform {
                    // 플랫폼 추가 폼
                    AddPlatformForm(showAddPlatform: $showAddPlatform)
                } else {
                    // 플랫폼 목록
                    List {
                        Section("등록된 플랫폼") {
                            ForEach(project.platforms) { platform in
                                PlatformRow(platform: platform) {
                                    platformToDelete = platform
                                    showDeleteAlert = true
                                }
                            }
                        }
                    }
                    .listStyle(.inset)

                    Divider()

                    // Footer
                    HStack {
                        Spacer()
                        Button {
                            showAddPlatform = true
                        } label: {
                            Label("플랫폼 추가", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
        }
        .frame(width: 500, height: 450)
        .alert("플랫폼 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) {
                platformToDelete = nil
            }
            Button("삭제", role: .destructive) {
                if let platform = platformToDelete {
                    appState.deletePlatform(platform)
                }
                platformToDelete = nil
            }
        } message: {
            Text("'\(platformToDelete?.name ?? "")'을(를) 삭제하시겠습니까?")
        }
    }
}

// MARK: - Platform Row
struct PlatformRow: View {
    let platform: PlatformConfig
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: platform.platformType.icon)
                .font(.title2)
                .foregroundStyle(platform.platformType.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(platform.name)
                    .font(.headline)

                HStack(spacing: 4) {
                    if platform.platformType.supportsDirectPublish {
                        Text("직접 발행")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .cornerRadius(4)
                    } else {
                        Text("클립보드 복사")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundStyle(.orange)
                            .cornerRadius(4)
                    }

                    if !platform.apiKey.isEmpty {
                        Text("API 키 설정됨")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Platform Form
struct AddPlatformForm: View {
    @EnvironmentObject var appState: AppState
    @Binding var showAddPlatform: Bool

    @State private var selectedPlatform: PlatformType = .hashnode
    @State private var customName = ""
    @State private var apiKey = ""
    @State private var additionalConfig: [String: String] = [:]

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("플랫폼 선택") {
                    Picker("플랫폼", selection: $selectedPlatform) {
                        ForEach(PlatformType.allCases) { platform in
                            Label(platform.defaultName, systemImage: platform.icon)
                                .tag(platform)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .onChange(of: selectedPlatform) { _, _ in
                        additionalConfig = [:]
                    }
                }

                Section("설정") {
                    if selectedPlatform == .custom {
                        TextField("플랫폼 이름", text: $customName)
                    }

                    SecureField("API Key / Token", text: $apiKey)
                        .help(apiKeyHelp)

                    ForEach(selectedPlatform.requiredFields) { field in
                        TextField(field.label, text: Binding(
                            get: { additionalConfig[field.key] ?? "" },
                            set: { additionalConfig[field.key] = $0 }
                        ))
                        .help(field.placeholder)
                    }
                }

                if !selectedPlatform.supportsDirectPublish {
                    Section {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.orange)
                            Text("이 플랫폼은 직접 발행을 지원하지 않습니다.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button("취소") {
                    showAddPlatform = false
                }
                .buttonStyle(.plain)

                Spacer()

                Button("API 키 얻는 방법") {
                    openAPIKeyHelp()
                }
                .buttonStyle(.link)

                Button("추가") {
                    let config = PlatformConfig(
                        platformType: selectedPlatform,
                        name: selectedPlatform == .custom ? customName : selectedPlatform.defaultName,
                        apiKey: apiKey,
                        additionalConfig: additionalConfig
                    )
                    appState.addPlatform(config)
                    showAddPlatform = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiKey.isEmpty && selectedPlatform != .substack)
            }
            .padding()
        }
    }

    private var apiKeyHelp: String {
        switch selectedPlatform {
        case .hashnode:
            return "Hashnode Settings > Developer > Personal Access Token"
        case .substack:
            return "브라우저 개발자도구 > Cookies > connect.sid (선택사항)"
        case .medium:
            return "Medium Settings > Security > Integration Tokens"
        case .devto:
            return "DEV.to Settings > Extensions > API Keys"
        case .tistory:
            return "Tistory 오픈 API > Access Token"
        case .custom:
            return "해당 플랫폼의 API 문서 참조"
        }
    }

    private func openAPIKeyHelp() {
        let url: String
        switch selectedPlatform {
        case .hashnode:
            url = "https://hashnode.com/settings/developer"
        case .substack:
            url = "https://support.substack.com"
        case .medium:
            url = "https://medium.com/me/settings"
        case .devto:
            url = "https://dev.to/settings/extensions"
        case .tistory:
            url = "https://www.tistory.com/guide/api/manage/register"
        case .custom:
            url = "https://www.google.com"
        }

        if let nsUrl = URL(string: url) {
            NSWorkspace.shared.open(nsUrl)
        }
    }
}

// MARK: - Publish Sheet
struct PublishSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedPlatforms: Set<UUID> = []
    @State private var isPublishing = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("발행하기")
                    .font(.title2.bold())
                Spacer()
                Button("취소") { dismiss() }
                    .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            if let post = appState.selectedPost {
                // Post preview
                VStack(alignment: .leading, spacing: 8) {
                    Text(post.title)
                        .font(.headline)
                    
                    if !post.subtitle.isEmpty {
                        Text(post.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        ForEach(post.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                .padding()
            }
            
            // Platform selection
            if let project = appState.selectedProject {
                if project.platforms.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        
                        Text("설정된 플랫폼이 없습니다")
                            .font(.headline)
                        
                        Button("플랫폼 추가") {
                            dismiss()
                            appState.showNewPlatformSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List(selection: $selectedPlatforms) {
                        Section("발행할 플랫폼 선택") {
                            ForEach(project.platforms) { platform in
                                PlatformSelectionRow(platform: platform)
                                    .tag(platform.id)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            appState.deletePlatform(platform)
                                        } label: {
                                            Label("삭제", systemImage: "trash")
                                        }
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            appState.deletePlatform(platform)
                                        } label: {
                                            Label("삭제", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            }
            
            // Results
            if !appState.publishResults.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("발행 결과")
                        .font(.headline)

                    ForEach(appState.publishResults) { result in
                        PublishResultRow(result: result)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            HStack {
                if let project = appState.selectedProject, !project.platforms.isEmpty {
                    Button("전체 선택") {
                        selectedPlatforms = Set(project.platforms.map { $0.id })
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                if appState.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("발행 중...")
                        .foregroundStyle(.secondary)
                } else {
                    Button("발행") {
                        publish()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedPlatforms.isEmpty)
                }
            }
            .padding()
        }
        .frame(width: 500, height: 600)
    }
    
    private func publish() {
        guard let project = appState.selectedProject,
              let post = appState.selectedPost else { return }
        
        let platformsToPublish = project.platforms.filter { selectedPlatforms.contains($0.id) }
        
        Task {
            await appState.publishPost(post, to: platformsToPublish)
        }
    }
}

// MARK: - Publish Result Row
struct PublishResultRow: View {
    let result: PublishResult
    @State private var showLog = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(result.success ? .green : .red)

                Text(result.platform.defaultName)
                    .font(.headline)

                Spacer()

                if result.success, let url = result.url {
                    Button("열기") {
                        if let nsUrl = URL(string: url) {
                            NSWorkspace.shared.open(nsUrl)
                        }
                    }
                    .buttonStyle(.link)
                } else {
                    Text(result.message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                // 로그 보기 버튼
                if result.debugLog != nil {
                    Button {
                        showLog.toggle()
                    } label: {
                        Image(systemName: showLog ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help("로그 보기")
                }
            }

            // 디버그 로그 표시
            if showLog, let log = result.debugLog {
                ScrollView {
                    Text(log)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

                HStack {
                    Spacer()
                    Button("로그 복사") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(log, forType: .string)
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct PlatformSelectionRow: View {
    let platform: PlatformConfig

    var body: some View {
        HStack {
            Image(systemName: platform.platformType.icon)
                .foregroundStyle(platform.platformType.color)
                .frame(width: 24)

            VStack(alignment: .leading) {
                Text(platform.name)
                    .font(.headline)

                if !platform.platformType.supportsDirectPublish {
                    Text("클립보드 복사 방식")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            if platform.isEnabled {
                Image(systemName: "checkmark")
                    .foregroundStyle(.green)
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var apiKey = ""
    
    var body: some View {
        TabView {
            // General Settings
            Form {
                Section("Claude API") {
                    SecureField("API Key", text: $apiKey)
                        .onAppear {
                            apiKey = appState.settings.claudeApiKey
                        }
                    
                    Button("저장") {
                        appState.settings.claudeApiKey = apiKey
                        appState.saveSettings()
                    }
                    .disabled(apiKey == appState.settings.claudeApiKey)
                    
                    Link("API 키 발급받기", destination: URL(string: "https://console.anthropic.com/")!)
                }
                
                Section("자동 저장") {
                    Toggle("자동 저장 활성화", isOn: Binding(
                        get: { appState.settings.autoSaveEnabled },
                        set: {
                            appState.settings.autoSaveEnabled = $0
                            appState.saveSettings()
                        }
                    ))
                    
                    Picker("저장 간격", selection: Binding(
                        get: { appState.settings.autoSaveInterval },
                        set: {
                            appState.settings.autoSaveInterval = $0
                            appState.saveSettings()
                        }
                    )) {
                        Text("10초").tag(10)
                        Text("30초").tag(30)
                        Text("1분").tag(60)
                        Text("5분").tag(300)
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("일반", systemImage: "gear")
            }
            
            // About
            VStack(spacing: 20) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)
                
                Text("Blog Publisher")
                    .font(.title.bold())
                
                Text("버전 1.0.0")
                    .foregroundStyle(.secondary)
                
                Text("Claude와 함께 블로그 글을 작성하고\n여러 플랫폼에 발행하세요.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabItem {
                Label("정보", systemImage: "info.circle")
            }
        }
        .frame(width: 450, height: 350)
    }
}
