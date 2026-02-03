import SwiftUI

// MARK: - Templates View
struct TemplatesView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: PostTemplate?
    @State private var showNewTemplateForm = false
    @State private var searchText = ""

    var filteredTemplates: [PostTemplate] {
        if searchText.isEmpty {
            return appState.templates
        }
        return appState.templates.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var builtInTemplates: [PostTemplate] {
        filteredTemplates.filter { $0.isBuiltIn }
    }

    var customTemplates: [PostTemplate] {
        filteredTemplates.filter { !$0.isBuiltIn }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("템플릿")
                        .font(.title2.bold())
                    Spacer()
                    Button {
                        showNewTemplateForm = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                }
                .padding()

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("템플릿 검색...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal)

                Divider()
                    .padding(.top, 8)

                // Template List
                List(selection: $selectedTemplate) {
                    if !builtInTemplates.isEmpty {
                        Section("기본 템플릿") {
                            ForEach(builtInTemplates) { template in
                                TemplateListRow(template: template)
                                    .tag(template)
                            }
                        }
                    }

                    if !customTemplates.isEmpty {
                        Section("내 템플릿") {
                            ForEach(customTemplates) { template in
                                TemplateListRow(template: template)
                                    .tag(template)
                                    .contextMenu {
                                        Button("삭제", role: .destructive) {
                                            appState.deleteTemplate(template)
                                        }
                                    }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 250)
        } detail: {
            if let template = selectedTemplate {
                TemplateDetailView(template: template) {
                    appState.createPostFromTemplate(template)
                    dismiss()
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("템플릿을 선택하세요")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 800, height: 500)
        .sheet(isPresented: $showNewTemplateForm) {
            NewTemplateSheet()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("닫기") { dismiss() }
            }
        }
    }
}

struct TemplateListRow: View {
    let template: PostTemplate

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: template.icon)
                .foregroundStyle(template.category.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(template.name)
                        .font(.subheadline)
                    if template.isBuiltIn {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }
                Text(template.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TemplateDetailView: View {
    let template: PostTemplate
    let onUse: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: template.icon)
                    .foregroundStyle(template.category.color)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.title2.bold())
                    Text(template.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    onUse()
                } label: {
                    Label("이 템플릿 사용", systemImage: "doc.badge.plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            // Tags and Category
            HStack {
                // Category
                HStack(spacing: 4) {
                    Image(systemName: template.category.icon)
                    Text(template.category.rawValue)
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(template.category.color.opacity(0.1))
                .foregroundStyle(template.category.color)
                .cornerRadius(12)

                // Tags
                ForEach(template.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .cornerRadius(12)
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Preview
            ScrollView {
                Text(template.content)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color(nsColor: .textBackgroundColor))
        }
    }
}

// MARK: - New Template Sheet
struct NewTemplateSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var content = ""
    @State private var category: PostCategory = .etc
    @State private var tagsText = ""

    var tags: [String] {
        tagsText.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("새 템플릿 만들기")
                    .font(.title2.bold())
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            Form {
                Section("기본 정보") {
                    TextField("템플릿 이름", text: $name)
                    TextField("설명", text: $description)

                    Picker("카테고리", selection: $category) {
                        ForEach(PostCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }

                    TextField("태그 (쉼표로 구분)", text: $tagsText)
                }

                Section("템플릿 내용") {
                    TextEditor(text: $content)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 200)
                }
            }
            .formStyle(.grouped)

            Divider()

            // Actions
            HStack {
                Button("취소") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("저장") {
                    saveTemplate()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || content.isEmpty)
            }
            .padding()
        }
        .frame(width: 500, height: 550)
    }

    func saveTemplate() {
        appState.createTemplate(
            name: name,
            description: description,
            content: content,
            category: category,
            tags: tags
        )
        dismiss()
    }
}

// MARK: - Series Management View
struct SeriesManagementView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showNewSeriesForm = false
    @State private var newSeriesName = ""
    @State private var newSeriesDescription = ""
    @State private var selectedSeries: Series?

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("시리즈")
                        .font(.title2.bold())
                    Spacer()
                    Button {
                        showNewSeriesForm = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                }
                .padding()

                Divider()

                if appState.series.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "books.vertical")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("시리즈가 없습니다")
                            .foregroundStyle(.secondary)
                        Text("연재물을 시리즈로 묶어 관리하세요")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List(selection: $selectedSeries) {
                        ForEach(appState.series) { s in
                            SeriesListRow(series: s)
                                .tag(s)
                                .contextMenu {
                                    Button("삭제", role: .destructive) {
                                        appState.deleteSeries(s)
                                    }
                                }
                        }
                    }
                    .listStyle(.sidebar)
                }
            }
            .frame(minWidth: 250)
        } detail: {
            if let series = selectedSeries {
                SeriesDetailView(series: series)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "books.vertical")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("시리즈를 선택하세요")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 700, height: 500)
        .sheet(isPresented: $showNewSeriesForm) {
            VStack(spacing: 16) {
                Text("새 시리즈")
                    .font(.title2.bold())

                TextField("시리즈 이름", text: $newSeriesName)
                    .textFieldStyle(.roundedBorder)

                TextField("설명", text: $newSeriesDescription)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("취소") {
                        showNewSeriesForm = false
                        newSeriesName = ""
                        newSeriesDescription = ""
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("생성") {
                        appState.createSeries(name: newSeriesName, description: newSeriesDescription)
                        showNewSeriesForm = false
                        newSeriesName = ""
                        newSeriesDescription = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newSeriesName.isEmpty)
                }
            }
            .padding()
            .frame(width: 350)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("닫기") { dismiss() }
            }
        }
    }
}

struct SeriesListRow: View {
    let series: Series

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "books.vertical")
                .foregroundStyle(.purple)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(series.name)
                        .font(.subheadline)
                    if series.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
                Text("\(series.postIds.count)개의 글")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SeriesDetailView: View {
    @EnvironmentObject var appState: AppState
    let series: Series

    var postsInSeries: [Post] {
        guard let project = appState.selectedProject else { return [] }
        return series.postIds.compactMap { postId in
            project.posts.first { $0.id == postId }
        }
    }

    var availablePosts: [Post] {
        guard let project = appState.selectedProject else { return [] }
        return project.posts.filter { !series.postIds.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(series.name)
                        .font(.title2.bold())
                    Text(series.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if series.isCompleted {
                    Label("완료", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .padding()

            Divider()

            // Posts in series
            List {
                Section("시리즈 글 (\(postsInSeries.count))") {
                    ForEach(Array(postsInSeries.enumerated()), id: \.element.id) { index, post in
                        HStack {
                            Text("\(index + 1)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 24)

                            Text(post.title)
                                .font(.subheadline)

                            Spacer()

                            Button {
                                removePost(post)
                            } label: {
                                Image(systemName: "minus.circle")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .onMove { from, to in
                        movePost(from: from, to: to)
                    }
                }

                if !availablePosts.isEmpty {
                    Section("추가 가능한 글") {
                        ForEach(availablePosts) { post in
                            HStack {
                                Text(post.title)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Button {
                                    addPost(post)
                                } label: {
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    func addPost(_ post: Post) {
        var updated = series
        updated.postIds.append(post.id)
        appState.updateSeries(updated)
    }

    func removePost(_ post: Post) {
        var updated = series
        updated.postIds.removeAll { $0 == post.id }
        appState.updateSeries(updated)
    }

    func movePost(from source: IndexSet, to destination: Int) {
        var updated = series
        updated.postIds.move(fromOffsets: source, toOffset: destination)
        appState.updateSeries(updated)
    }
}
