import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct PostListView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var postToDelete: Post?
    @State private var showDeleteAlert = false
    @State private var showTagFilter = false

    // MARK: - Computed Properties
    var allTags: [String] {
        appState.allTags()
    }

    var filteredPosts: [Post] {
        guard let project = appState.selectedProject else { return [] }

        var posts = project.posts

        // 태그 필터 적용
        if !appState.selectedTags.isEmpty {
            posts = posts.filter { post in
                !appState.selectedTags.isDisjoint(with: Set(post.tags))
            }
        }

        // 카테고리 필터 적용
        if let category = appState.selectedCategory {
            posts = posts.filter { $0.category == category }
        }

        // 플랫폼 필터 적용
        if let platform = appState.selectedPlatformFilter {
            posts = posts.filter { $0.publishedPlatforms.contains(platform) }
        }

        // 검색 필터 적용
        if !searchText.isEmpty {
            posts = posts.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        return posts.sorted { $0.createdAt > $1.createdAt }
    }

    // 월별 그룹화
    var postsByMonth: [(String, [Post])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"

        var grouped: [String: [Post]] = [:]
        for post in filteredPosts {
            let key = formatter.string(from: post.createdAt)
            grouped[key, default: []].append(post)
        }

        return grouped.sorted { lhs, rhs in
            let lhsDate = lhs.value.first?.createdAt ?? Date.distantPast
            let rhsDate = rhs.value.first?.createdAt ?? Date.distantPast
            return lhsDate > rhsDate
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Filter Bar
            if showTagFilter {
                filterBar
                Divider()
            }

            // Content
            if filteredPosts.isEmpty {
                emptyView
            } else {
                postListContent
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("글 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) { postToDelete = nil }
            Button("삭제", role: .destructive) {
                if let post = postToDelete {
                    appState.deletePost(post)
                }
                postToDelete = nil
            }
        } message: {
            Text("'\(postToDelete?.title ?? "")'을(를) 삭제하시겠습니까?")
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                // 프로젝트 선택 드롭다운
                projectPicker

                Spacer()

                // 필터 토글
                Button {
                    withAnimation { showTagFilter.toggle() }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(hasActiveFilters ? .blue : .secondary)
                }
                .buttonStyle(.plain)
                .help("필터")

                // 글 불러오기 버튼
                Button { importMarkdownFile() } label: {
                    Image(systemName: "doc.badge.plus")
                }
                .buttonStyle(.plain)
                .help("마크다운 파일 불러오기")

                // 새 글 버튼
                Button { appState.createNewPost() } label: {
                    Image(systemName: "square.and.pencil")
                }
                .buttonStyle(.plain)
                .help("새 글")

                // 설정 버튼
                Button { appState.showNewPlatformSheet = true } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .help("플랫폼 설정")
            }

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("검색...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
        .padding()
    }

    // MARK: - Project Picker
    private var projectPicker: some View {
        Menu {
            ForEach(appState.projects) { project in
                Button {
                    appState.selectedProject = project
                    appState.selectedPost = project.posts.first
                    clearAllFilters()
                } label: {
                    HStack {
                        Image(systemName: project.icon)
                        Text(project.name)
                        if project.id == appState.selectedProject?.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            Divider()
            Button {
                appState.showNewProjectSheet = true
            } label: {
                Label("새 프로젝트", systemImage: "plus")
            }
        } label: {
            HStack(spacing: 6) {
                if let project = appState.selectedProject {
                    Image(systemName: project.icon)
                        .foregroundStyle(project.projectColor)
                    Text(project.name)
                        .font(.headline)
                } else {
                    Text("프로젝트 선택")
                        .font(.headline)
                }
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .menuStyle(.borderlessButton)
    }

    // MARK: - Filter Bar
    private var filterBar: some View {
        VStack(spacing: 8) {
            // 카테고리 & 플랫폼 필터
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    // 전체 해제 버튼
                    if hasActiveFilters {
                        Button {
                            clearAllFilters()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark")
                                Text("필터 해제")
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)

                        Divider().frame(height: 20)
                    }

                    // 카테고리 필터
                    Text("종류:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach(PostCategory.allCases) { category in
                        let isSelected = appState.selectedCategory == category
                        Button {
                            appState.selectedCategory = isSelected ? nil : category
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isSelected ? category.color : category.color.opacity(0.1))
                            .foregroundColor(isSelected ? .white : category.color)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }

                    if !publishedPlatforms.isEmpty {
                        Divider().frame(height: 20)

                        // 플랫폼 필터
                        Text("플랫폼:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(publishedPlatforms, id: \.self) { platform in
                            if let platformType = PlatformType(rawValue: platform) {
                                let isSelected = appState.selectedPlatformFilter == platform
                                Button {
                                    appState.selectedPlatformFilter = isSelected ? nil : platform
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: platformType.icon)
                                        Text(platformType.defaultName)
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(isSelected ? platformType.color : platformType.color.opacity(0.1))
                                    .foregroundColor(isSelected ? .white : platformType.color)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }

            // 태그 필터
            if !allTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        Text("태그:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(allTags, id: \.self) { tag in
                            let isSelected = appState.selectedTags.contains(tag)
                            Button {
                                appState.toggleTagFilter(tag)
                            } label: {
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                                    .foregroundColor(isSelected ? .white : .blue)
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var hasActiveFilters: Bool {
        !appState.selectedTags.isEmpty ||
        appState.selectedCategory != nil ||
        appState.selectedPlatformFilter != nil
    }

    private var publishedPlatforms: [String] {
        guard let project = appState.selectedProject else { return [] }
        var platforms = Set<String>()
        for post in project.posts {
            platforms.formUnion(post.publishedPlatforms)
        }
        return platforms.sorted()
    }

    private func clearAllFilters() {
        appState.clearTagFilters()
        appState.selectedCategory = nil
        appState.selectedPlatformFilter = nil
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)

            Text("글이 없습니다")
                .foregroundStyle(.secondary)

            Button("새 글 작성") {
                appState.createNewPost()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Post List Content
    private var postListContent: some View {
        List(selection: Binding(
            get: { appState.selectedPost },
            set: { appState.selectedPost = $0 }
        )) {
            ForEach(postsByMonth, id: \.0) { month, posts in
                Section(header: monthHeader(month)) {
                    ForEach(posts) { post in
                        PostRow(post: post)
                            .tag(post)
                            .contextMenu { postContextMenu(for: post) }
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    private func monthHeader(_ month: String) -> some View {
        HStack {
            Image(systemName: "calendar")
                .font(.caption)
            Text(month)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.secondary)
    }

    // MARK: - Context Menu
    @ViewBuilder
    private func postContextMenu(for post: Post) -> some View {
        Button("복제") { duplicatePost(post) }
        Button("내보내기...") { exportPost(post) }

        Divider()

        Button("삭제", role: .destructive) {
            postToDelete = post
            showDeleteAlert = true
        }
    }

    // MARK: - Helper Functions
    private func duplicatePost(_ post: Post) {
        let newPost = Post(
            title: "\(post.title) (복사본)",
            content: post.content,
            subtitle: post.subtitle,
            tags: post.tags,
            coverImageURL: post.coverImageURL,
            status: .draft,
            category: post.category
        )

        guard var project = appState.selectedProject else { return }
        project.posts.insert(newPost, at: 0)
        appState.updateProject(project)
        appState.selectedPost = newPost
    }

    private func exportPost(_ post: Post) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "\(post.title).md"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? appState.storageService.exportPost(post, to: url)
            }
        }
    }

    private func importMarkdownFile() {
        let panel = NSOpenPanel()
        var allowedTypes: [UTType] = [.plainText]
        if let markdownType = UTType("net.daringfireball.markdown") {
            allowedTypes.append(markdownType)
        }
        panel.allowedContentTypes = allowedTypes
        panel.allowsMultipleSelection = true
        panel.message = "불러올 마크다운 파일을 선택하세요"
        panel.prompt = "불러오기"

        panel.begin { response in
            if response == .OK {
                for url in panel.urls {
                    appState.importMarkdownFile(from: url)
                }
            }
        }
    }
}

// MARK: - Post Row
struct PostRow: View {
    let post: Post

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }

    private var isPublished: Bool {
        !post.publishedPlatforms.isEmpty || post.status == .published
    }

    var body: some View {
        HStack(spacing: 12) {
            // 발행 상태 인디케이터
            Circle()
                .fill(isPublished ? Color.green : Color.orange)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(post.title)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    // 카테고리 & 상태 배지
                    HStack(spacing: 4) {
                        // 카테고리
                        Image(systemName: post.category.icon)
                            .font(.caption2)
                            .foregroundStyle(post.category.color)

                        Text(post.status.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(post.status.color.opacity(0.2))
                            .foregroundStyle(post.status.color)
                            .cornerRadius(4)
                    }
                }

                Text(post.content.isEmpty ? "내용 없음" : post.content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack {
                    // Tags
                    if !post.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(post.tags.prefix(3), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }

                    Spacer()

                    Text(dateFormatter.string(from: post.updatedAt))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                // Published platforms
                if !post.publishedPlatforms.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "paperplane.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)

                        ForEach(post.publishedPlatforms, id: \.self) { platformId in
                            if let platformType = PlatformType(rawValue: platformId) {
                                HStack(spacing: 2) {
                                    Image(systemName: platformType.icon)
                                        .font(.caption)
                                    Text(platformType.defaultName)
                                        .font(.caption2)
                                }
                                .foregroundStyle(platformType.color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(platformType.color.opacity(0.1))
                                .cornerRadius(4)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}
