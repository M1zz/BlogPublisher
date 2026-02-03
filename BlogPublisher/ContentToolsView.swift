import SwiftUI

// MARK: - AI Title Suggestions View
struct AITitleSuggestionsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var suggestions: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("AI 제목 추천")
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

            if let post = appState.selectedPost {
                VStack(spacing: 16) {
                    // Current title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("현재 제목")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(post.title)
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(8)
                    }

                    Divider()

                    // Suggestions
                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("AI가 제목을 생성하고 있습니다...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxHeight: .infinity)
                    } else if let error = errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button("다시 시도") {
                                generateSuggestions()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxHeight: .infinity)
                    } else if suggestions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.largeTitle)
                                .foregroundStyle(.purple)
                            Text("AI가 클릭율 높은 제목을 추천해드립니다")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button("제목 추천받기") {
                                generateSuggestions()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                Text("추천 제목")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                ForEach(suggestions, id: \.self) { title in
                                    TitleSuggestionRow(title: title) {
                                        applyTitle(title)
                                    }
                                }

                                Button("다시 추천받기") {
                                    generateSuggestions()
                                }
                                .buttonStyle(.bordered)
                                .padding(.top)
                            }
                        }
                    }
                }
                .padding()
            } else {
                Text("선택된 글이 없습니다")
                    .foregroundStyle(.secondary)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 500, height: 450)
    }

    func generateSuggestions() {
        guard let post = appState.selectedPost else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let titles = try await appState.generateTitleSuggestions(for: post)
                await MainActor.run {
                    suggestions = titles
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    func applyTitle(_ title: String) {
        guard var post = appState.selectedPost else { return }
        post.title = title
        appState.updatePost(post)
        dismiss()
    }
}

struct TitleSuggestionRow: View {
    let title: String
    let onApply: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)

            Spacer()

            Button("적용") {
                onApply()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - SEO Analysis View
struct SEOAnalysisView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var keyword = ""
    @State private var analysis: SEOAnalysis?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "magnifyingglass.circle.fill")
                    .foregroundStyle(.green)
                Text("SEO 분석")
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

            ScrollView {
                VStack(spacing: 20) {
                    // Keyword input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("타겟 키워드")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            TextField("키워드 입력", text: $keyword)
                                .textFieldStyle(.roundedBorder)
                            Button("분석") {
                                analyzePost()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(keyword.isEmpty)
                        }
                    }

                    if let seo = analysis {
                        // Overall Score
                        SEOScoreGauge(score: seo.score)

                        Divider()

                        // Title Analysis
                        SEOSectionCard(
                            title: "제목",
                            score: seo.titleScore.score,
                            icon: "textformat",
                            details: [
                                ("길이", "\(seo.titleScore.length)자"),
                                ("키워드 포함", seo.titleScore.hasKeyword ? "예" : "아니오")
                            ],
                            feedback: seo.titleScore.feedback
                        )

                        // Content Analysis
                        SEOSectionCard(
                            title: "콘텐츠",
                            score: seo.contentScore.score,
                            icon: "doc.text",
                            details: [
                                ("단어 수", "\(seo.contentScore.wordCount)개"),
                                ("단락 수", "\(seo.contentScore.paragraphCount)개"),
                                ("읽기 시간", "\(seo.contentScore.readingTime)분"),
                                ("제목 태그", seo.contentScore.hasHeadings ? "있음" : "없음"),
                                ("이미지", seo.contentScore.hasImages ? "있음" : "없음")
                            ],
                            feedback: seo.contentScore.feedback
                        )

                        // Keyword Analysis
                        SEOSectionCard(
                            title: "키워드",
                            score: seo.keywordScore.score,
                            icon: "key",
                            details: [
                                ("키워드", seo.keywordScore.keyword),
                                ("등장 횟수", "\(seo.keywordScore.count)회"),
                                ("밀도", String(format: "%.1f%%", seo.keywordScore.density))
                            ],
                            feedback: seo.keywordScore.feedback
                        )

                        // Suggestions
                        if !seo.suggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("개선 제안")
                                    .font(.headline)

                                ForEach(seo.suggestions, id: \.self) { suggestion in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "lightbulb.fill")
                                            .foregroundStyle(.yellow)
                                        Text(suggestion)
                                            .font(.subheadline)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(8)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("키워드를 입력하고 분석 버튼을 누르세요")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                .padding()
            }
        }
        .frame(width: 550, height: 600)
    }

    func analyzePost() {
        guard let post = appState.selectedPost, !keyword.isEmpty else { return }
        analysis = appState.analyzeSEO(for: post, keyword: keyword)
    }
}

struct SEOScoreGauge: View {
    let score: Int

    var scoreColor: Color {
        if score >= 80 { return .green }
        else if score >= 60 { return .orange }
        else { return .red }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(scoreColor.opacity(0.2), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack {
                    Text("\(score)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("점")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            Text(scoreLabel)
                .font(.subheadline)
                .foregroundStyle(scoreColor)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    var scoreLabel: String {
        if score >= 80 { return "좋은 SEO 점수입니다!" }
        else if score >= 60 { return "개선이 필요합니다" }
        else { return "SEO 최적화가 필요합니다" }
    }
}

struct SEOSectionCard: View {
    let title: String
    let score: Int
    let icon: String
    let details: [(String, String)]
    let feedback: String

    var scoreColor: Color {
        if score >= 80 { return .green }
        else if score >= 60 { return .orange }
        else { return .red }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(score)점")
                    .font(.subheadline.bold())
                    .foregroundStyle(scoreColor)
            }

            HStack(spacing: 16) {
                ForEach(details, id: \.0) { label, value in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(value)
                            .font(.subheadline)
                    }
                }
            }

            Text(feedback)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Readability Analysis View
struct ReadabilityAnalysisView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var analysis: ReadabilityAnalysis?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundStyle(.blue)
                Text("가독성 분석")
                    .font(.title2.bold())
                Spacer()
                Button("분석하기") {
                    analyzeReadability()
                }
                .buttonStyle(.borderedProminent)
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            if let ra = analysis {
                ScrollView {
                    VStack(spacing: 20) {
                        // Grade Display
                        VStack(spacing: 12) {
                            Image(systemName: ra.grade.icon)
                                .font(.system(size: 48))
                                .foregroundStyle(ra.grade.color)

                            Text(ra.grade.rawValue)
                                .font(.title.bold())
                                .foregroundStyle(ra.grade.color)

                            Text("가독성 점수: \(ra.score)점")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(12)

                        // Stats
                        HStack(spacing: 16) {
                            ReadabilityStatBox(
                                title: "평균 문장 길이",
                                value: String(format: "%.1f", ra.avgSentenceLength),
                                unit: "단어",
                                ideal: "15-20"
                            )
                            ReadabilityStatBox(
                                title: "평균 단락 길이",
                                value: String(format: "%.1f", ra.avgParagraphLength),
                                unit: "문장",
                                ideal: "3-5"
                            )
                            ReadabilityStatBox(
                                title: "복잡한 문장",
                                value: "\(ra.complexSentences)",
                                unit: "개",
                                ideal: "적을수록"
                            )
                        }

                        // Suggestions
                        if !ra.suggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("개선 제안")
                                    .font(.headline)

                                ForEach(ra.suggestions, id: \.self) { suggestion in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .foregroundStyle(.blue)
                                        Text(suggestion)
                                            .font(.subheadline)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "text.alignleft")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("분석 버튼을 눌러 가독성을 확인하세요")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 500, height: 500)
        .onAppear {
            analyzeReadability()
        }
    }

    func analyzeReadability() {
        guard let post = appState.selectedPost else { return }
        analysis = appState.analyzeReadability(for: post)
    }
}

struct ReadabilityStatBox: View {
    let title: String
    let value: String
    let unit: String
    let ideal: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("권장: \(ideal)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Twitter Thread Preview
struct ThreadPreviewView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var threads: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "text.bubble")
                    .foregroundStyle(.blue)
                Text("트위터 스레드 미리보기")
                    .font(.title2.bold())
                Spacer()
                Button("복사") {
                    copyToClipboard()
                }
                .buttonStyle(.bordered)
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            if threads.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("스레드 생성 중...")
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(Array(threads.enumerated()), id: \.offset) { index, thread in
                            ThreadCard(index: index + 1, total: threads.count, content: thread)
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(width: 450, height: 600)
        .onAppear {
            generateThreads()
        }
    }

    func generateThreads() {
        guard let post = appState.selectedPost else { return }
        threads = appState.convertToTwitterThread(post: post)
    }

    func copyToClipboard() {
        let text = threads.joined(separator: "\n\n---\n\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

struct ThreadCard: View {
    let index: Int
    let total: Int
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text("\(index)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }

                Text("\(index)/\(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(content.count)/280")
                    .font(.caption)
                    .foregroundStyle(content.count > 280 ? .red : .secondary)
            }

            Text(content.replacingOccurrences(of: "^\(index)/\(total)\n\n", with: "", options: .regularExpression))
                .font(.subheadline)
                .lineLimit(nil)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}
