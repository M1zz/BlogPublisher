import SwiftUI
import AppKit

struct PostListView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var postToDelete: Post?
    @State private var showDeleteAlert = false
    
    var filteredPosts: [Post] {
        guard let project = appState.selectedProject else { return [] }
        
        if searchText.isEmpty {
            return project.posts
        }
        
        return project.posts.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Project Picker
            VStack(spacing: 8) {
                HStack {
                    // 프로젝트 선택 드롭다운
                    Menu {
                        ForEach(appState.projects) { project in
                            Button {
                                appState.selectedProject = project
                                appState.selectedPost = project.posts.first
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

                    Spacer()

                    // 새 글 버튼
                    Button {
                        appState.createNewPost()
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .buttonStyle(.plain)
                    .help("새 글")

                    // 설정 버튼
                    Button {
                        appState.showNewPlatformSheet = true
                    } label: {
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
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }
            .padding()

            Divider()
            
            // Post List
            if filteredPosts.isEmpty {
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
            } else {
                List(selection: $appState.selectedPost) {
                    ForEach(filteredPosts) { post in
                        PostRow(post: post)
                            .tag(post)
                            .contextMenu {
                                Button("복제") {
                                    duplicatePost(post)
                                }
                                
                                Button("내보내기...") {
                                    exportPost(post)
                                }
                                
                                Divider()

                                Button("삭제", role: .destructive) {
                                    postToDelete = post
                                    showDeleteAlert = true
                                }
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("글 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) {
                postToDelete = nil
            }
            Button("삭제", role: .destructive) {
                if let post = postToDelete {
                    appState.deletePost(post)
                }
                postToDelete = nil
            }
        } message: {
            Text("'\(postToDelete?.title ?? "")'을(를) 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.")
        }
    }
    
    private func duplicatePost(_ post: Post) {
        let newPost = Post(
            title: "\(post.title) (복사본)",
            content: post.content,
            subtitle: post.subtitle,
            tags: post.tags,
            coverImageURL: post.coverImageURL,
            status: .draft
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
}

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

                    // Status badge
                    HStack(spacing: 4) {
                        if isPublished {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
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
