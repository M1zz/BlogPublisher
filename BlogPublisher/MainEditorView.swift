import SwiftUI
import AppKit

struct MainEditorView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        EditorPanel()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        appState.showPublishSheet = true
                    } label: {
                        Label("발행", systemImage: "paperplane.fill")
                    }
                    .help("발행하기")
                }
            }
    }
}

// MARK: - Editor Panel
struct EditorPanel: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Post metadata
            PostMetadataHeader()

            Divider()

            // WYSIWYG Editor
            if let post = appState.selectedPost {
                RichTextEditor(
                    content: Binding(
                        get: { post.content },
                        set: { newContent in
                            var updated = post
                            updated.content = newContent
                            appState.updatePost(updated)
                        }
                    )
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}

// MARK: - Post Metadata Header
struct PostMetadataHeader: View {
    @EnvironmentObject var appState: AppState
    @State private var newTag = ""
    
    var body: some View {
        if let post = appState.selectedPost {
            VStack(alignment: .leading, spacing: 12) {
                // Title
                TextField("제목", text: Binding(
                    get: { post.title },
                    set: { newTitle in
                        var updated = post
                        updated.title = newTitle
                        appState.updatePost(updated)
                    }
                ))
                .font(.title.bold())
                .textFieldStyle(.plain)
                
                // Subtitle
                TextField("부제목 (선택사항)", text: Binding(
                    get: { post.subtitle },
                    set: { newSubtitle in
                        var updated = post
                        updated.subtitle = newSubtitle
                        appState.updatePost(updated)
                    }
                ))
                .font(.title3)
                .foregroundStyle(.secondary)
                .textFieldStyle(.plain)
                
                // Tags
                HStack {
                    ForEach(post.tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text("#\(tag)")
                                .font(.caption)
                            
                            Button {
                                var updated = post
                                updated.tags.removeAll { $0 == tag }
                                appState.updatePost(updated)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption2)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .cornerRadius(4)
                    }
                    
                    // Add tag field
                    TextField("태그 추가", text: $newTag)
                        .textFieldStyle(.plain)
                        .frame(width: 100)
                        .onSubmit {
                            if !newTag.isEmpty && !post.tags.contains(newTag) {
                                var updated = post
                                updated.tags.append(newTag)
                                appState.updatePost(updated)
                                newTag = ""
                            }
                        }
                }
                
                // Status and platform info
                HStack {
                    // Status picker
                    Picker("상태", selection: Binding(
                        get: { post.status },
                        set: { newStatus in
                            var updated = post
                            updated.status = newStatus
                            appState.updatePost(updated)
                        }
                    )) {
                        ForEach(PostStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                    
                    Spacer()
                    
                    // Word count
                    let wordCount = post.content.split(separator: " ").count
                    Text("\(wordCount)자")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
        }
    }
}

// MARK: - Notion-style WYSIWYG Markdown Editor
struct RichTextEditor: NSViewRepresentable {
    @Binding var content: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor.textBackgroundColor

        // Custom Layout Manager 설정
        let textStorage = NSTextStorage()
        let layoutManager = CodeBlockLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        let textContainer = NSTextContainer(containerSize: containerSize)
        textContainer.widthTracksTextView = true
        textContainer.heightTracksTextView = false
        layoutManager.addTextContainer(textContainer)

        let textView = NotionStyleTextView(frame: scrollView.contentView.bounds, textContainer: textContainer)
        textView.isRichText = true
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.font = NSFont.systemFont(ofSize: 16)
        textView.textColor = NSColor.textColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textContainerInset = NSSize(width: 60, height: 40)

        // 스크롤 관련 설정
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        textView.delegate = context.coordinator

        textView.string = content
        textView.renderMarkdown()

        scrollView.documentView = textView

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NotionStyleTextView else { return }

        if textView.string != content && !context.coordinator.isEditing {
            let selectedRange = textView.selectedRange()
            textView.string = content
            textView.renderMarkdown()

            let safeLocation = min(selectedRange.location, content.count)
            textView.setSelectedRange(NSRange(location: safeLocation, length: 0))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor
        var isEditing = false
        private var previousLineRange: NSRange?

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textDidBeginEditing(_ notification: Notification) {
            isEditing = true
        }

        func textDidEndEditing(_ notification: Notification) {
            isEditing = false
            if let textView = notification.object as? NotionStyleTextView {
                textView.renderMarkdown()
            }
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NotionStyleTextView else { return }
            parent.content = textView.string
            textView.renderMarkdown()
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NotionStyleTextView else { return }

            let currentLine = textView.currentLineRange()
            if previousLineRange != currentLine {
                previousLineRange = currentLine
                textView.renderMarkdown()
            }
        }
    }
}

// MARK: - Custom Layout Manager (코드 블록 배경 & 수평선 그리기)
class CodeBlockLayoutManager: NSLayoutManager {

    var codeBlockRanges: [NSRange] = []
    var horizontalRuleRanges: [NSRange] = []

    var codeBlockBackground: NSColor {
        if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(white: 0.2, alpha: 1.0)
        } else {
            return NSColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1.0)
        }
    }

    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

        guard let textContainer = textContainers.first,
              let textView = textContainer.textView else { return }

        NSGraphicsContext.saveGraphicsState()

        // 코드 블록 배경 그리기
        for range in codeBlockRanges {
            guard range.location != NSNotFound else { continue }

            let glyphRange = self.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            guard glyphRange.location != NSNotFound else { continue }

            if NSIntersectionRange(glyphRange, glyphsToShow).length > 0 {
                var rect = boundingRect(forGlyphRange: glyphRange, in: textContainer)

                rect.origin.x = origin.x + 8
                rect.origin.y += origin.y
                rect.size.width = textView.bounds.width - textView.textContainerInset.width * 2 - 16

                rect.origin.y -= 8
                rect.size.height += 16

                let path = NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8)
                codeBlockBackground.setFill()
                path.fill()
            }
        }

        // 수평선 그리기
        for range in horizontalRuleRanges {
            guard range.location != NSNotFound else { continue }

            let glyphRange = self.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            guard glyphRange.location != NSNotFound else { continue }

            if NSIntersectionRange(glyphRange, glyphsToShow).length > 0 {
                let rect = boundingRect(forGlyphRange: glyphRange, in: textContainer)

                let lineY = rect.origin.y + origin.y + rect.height / 2
                let startX = origin.x + textView.textContainerInset.width
                let endX = textView.bounds.width - textView.textContainerInset.width

                // 실제 선 그리기
                let linePath = NSBezierPath()
                linePath.move(to: NSPoint(x: startX, y: lineY))
                linePath.line(to: NSPoint(x: endX, y: lineY))
                linePath.lineWidth = 1.5

                NSColor.separatorColor.setStroke()
                linePath.stroke()
            }
        }

        NSGraphicsContext.restoreGraphicsState()
    }
}

// MARK: - Notion Style TextView
class NotionStyleTextView: NSTextView {

    private var editingLineRange: NSRange?
    private var codeBlockRanges: [NSRange] = []

    var codeBlockLayoutManager: CodeBlockLayoutManager? {
        return layoutManager as? CodeBlockLayoutManager
    }

    // 코드 블록 배경색 (에디터 배경보다 진하게)
    var codeBlockBackground: NSColor {
        if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(white: 0.18, alpha: 1.0)
        } else {
            return NSColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        }
    }

    func currentLineRange() -> NSRange {
        let text = string as NSString
        let cursorLocation = min(selectedRange().location, text.length)
        return text.lineRange(for: NSRange(location: cursorLocation, length: 0))
    }

    func renderMarkdown() {
        guard let storage = textStorage else { return }
        let text = string
        guard !text.isEmpty else { return }

        let fullRange = NSRange(location: 0, length: text.count)
        let currentLine = currentLineRange()

        storage.beginEditing()

        // 기본 스타일
        let defaultParagraph = NSMutableParagraphStyle()
        defaultParagraph.lineSpacing = 6
        defaultParagraph.paragraphSpacing = 12

        storage.setAttributes([
            .font: NSFont.systemFont(ofSize: 16),
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: defaultParagraph
        ], range: fullRange)

        // 각 마크다운 요소 렌더링
        renderHeaders(storage: storage, text: text, editingLine: currentLine)
        renderCodeBlocks(storage: storage, text: text, editingLine: currentLine)
        renderInlineCode(storage: storage, text: text, editingLine: currentLine)
        renderBold(storage: storage, text: text, editingLine: currentLine)
        renderItalic(storage: storage, text: text, editingLine: currentLine)
        renderLinks(storage: storage, text: text, editingLine: currentLine)
        renderBlockquotes(storage: storage, text: text, editingLine: currentLine)
        renderLists(storage: storage, text: text, editingLine: currentLine)
        renderHorizontalRules(storage: storage, text: text, editingLine: currentLine)

        storage.endEditing()
    }

    private func isEditing(_ range: NSRange, in editingLine: NSRange) -> Bool {
        return NSIntersectionRange(range, editingLine).length > 0
    }

    private func hideText(in range: NSRange, storage: NSTextStorage) {
        storage.addAttributes([
            .font: NSFont.systemFont(ofSize: 0.1),
            .foregroundColor: NSColor.clear
        ], range: range)
    }

    // MARK: - Headers
    private func renderHeaders(storage: NSTextStorage, text: String, editingLine: NSRange) {
        let pattern = "^(#{1,6}) (.+)$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) else { return }

        for match in regex.matches(in: text, range: NSRange(location: 0, length: text.count)) {
            let hashRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            let level = hashRange.length
            let fontSize: CGFloat = [32, 26, 22, 18, 16, 15][min(level - 1, 5)]

            if isEditing(match.range, in: editingLine) {
                // 편집 중: 마크다운 문법 표시
                storage.addAttributes([
                    .foregroundColor: NSColor.systemOrange.withAlphaComponent(0.6),
                    .font: NSFont.systemFont(ofSize: fontSize, weight: .bold)
                ], range: hashRange)
                storage.addAttributes([
                    .font: NSFont.systemFont(ofSize: fontSize, weight: .bold)
                ], range: contentRange)
            } else {
                // 렌더링: # 숨기고 스타일만 적용
                hideText(in: NSRange(location: hashRange.location, length: hashRange.length + 1), storage: storage)
                storage.addAttributes([
                    .font: NSFont.systemFont(ofSize: fontSize, weight: .bold)
                ], range: contentRange)
            }
        }
    }

    // MARK: - Code Blocks
    private func renderCodeBlocks(storage: NSTextStorage, text: String, editingLine: NSRange) {
        // ```언어\n코드내용\n``` 패턴
        let pattern = "(```)(\\w*\\n)([\\s\\S]*?)(```)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }

        let cursorLocation = selectedRange().location
        codeBlockRanges = []

        let codeParagraph = NSMutableParagraphStyle()
        codeParagraph.lineSpacing = 4
        codeParagraph.paragraphSpacingBefore = 12
        codeParagraph.paragraphSpacing = 12
        codeParagraph.headIndent = 16
        codeParagraph.firstLineHeadIndent = 16
        codeParagraph.tailIndent = -16

        for match in regex.matches(in: text, range: NSRange(location: 0, length: text.count)) {
            let fullRange = match.range
            let openTicksRange = match.range(at: 1)      // ```
            let langLineRange = match.range(at: 2)       // swift\n
            let codeRange = match.range(at: 3)           // 코드 내용
            let closeTicksRange = match.range(at: 4)     // ```

            // 코드 블록 범위 저장 (LayoutManager에서 배경 그리기용)
            codeBlockRanges.append(fullRange)

            // 커서가 코드 블록 내부에 있는지 확인
            let isCursorInBlock = cursorLocation >= fullRange.location &&
                                  cursorLocation <= fullRange.location + fullRange.length

            // 코드 블록 기본 스타일
            storage.addAttributes([
                .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                .paragraphStyle: codeParagraph
            ], range: fullRange)

            if isCursorInBlock {
                // 편집 중: 마커 표시
                storage.addAttributes([
                    .foregroundColor: NSColor.secondaryLabelColor
                ], range: openTicksRange)

                if langLineRange.length > 1 {
                    let langOnlyRange = NSRange(location: langLineRange.location, length: langLineRange.length - 1)
                    storage.addAttributes([
                        .foregroundColor: NSColor.systemPurple
                    ], range: langOnlyRange)
                }

                storage.addAttributes([
                    .foregroundColor: NSColor.secondaryLabelColor
                ], range: closeTicksRange)
            } else {
                // 렌더링: 마커 숨기기
                let firstLineRange = NSRange(location: openTicksRange.location,
                                             length: openTicksRange.length + langLineRange.length)
                storage.addAttributes([
                    .font: NSFont.systemFont(ofSize: 0.1),
                    .foregroundColor: NSColor.clear
                ], range: firstLineRange)

                storage.addAttributes([
                    .font: NSFont.systemFont(ofSize: 0.1),
                    .foregroundColor: NSColor.clear
                ], range: closeTicksRange)

                storage.addAttributes([
                    .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                    .foregroundColor: NSColor.textColor
                ], range: codeRange)
            }
        }

        // Layout Manager에 코드 블록 범위 전달
        codeBlockLayoutManager?.codeBlockRanges = codeBlockRanges
    }

    // MARK: - Inline Code
    private func renderInlineCode(storage: NSTextStorage, text: String, editingLine: NSRange) {
        let pattern = "(?<!`)`([^`\\n]+)`(?!`)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }

        for match in regex.matches(in: text, range: NSRange(location: 0, length: text.count)) {
            let fullRange = match.range
            let contentRange = match.range(at: 1)

            if isEditing(fullRange, in: editingLine) {
                storage.addAttributes([
                    .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
                    .foregroundColor: NSColor.systemPink,
                    .backgroundColor: NSColor.systemGray.withAlphaComponent(0.15)
                ], range: fullRange)
            } else {
                // 백틱 숨기기
                hideText(in: NSRange(location: fullRange.location, length: 1), storage: storage)
                hideText(in: NSRange(location: fullRange.location + fullRange.length - 1, length: 1), storage: storage)
                storage.addAttributes([
                    .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .medium),
                    .foregroundColor: NSColor.systemPink,
                    .backgroundColor: NSColor.systemGray.withAlphaComponent(0.15)
                ], range: contentRange)
            }
        }
    }

    // MARK: - Bold
    private func renderBold(storage: NSTextStorage, text: String, editingLine: NSRange) {
        let pattern = "\\*\\*([^*]+)\\*\\*"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }

        for match in regex.matches(in: text, range: NSRange(location: 0, length: text.count)) {
            let fullRange = match.range
            let contentRange = match.range(at: 1)

            if isEditing(fullRange, in: editingLine) {
                storage.addAttributes([
                    .font: NSFont.boldSystemFont(ofSize: 16)
                ], range: fullRange)
                storage.addAttributes([
                    .foregroundColor: NSColor.tertiaryLabelColor
                ], range: NSRange(location: fullRange.location, length: 2))
                storage.addAttributes([
                    .foregroundColor: NSColor.tertiaryLabelColor
                ], range: NSRange(location: fullRange.location + fullRange.length - 2, length: 2))
            } else {
                hideText(in: NSRange(location: fullRange.location, length: 2), storage: storage)
                hideText(in: NSRange(location: fullRange.location + fullRange.length - 2, length: 2), storage: storage)
                storage.addAttributes([
                    .font: NSFont.boldSystemFont(ofSize: 16)
                ], range: contentRange)
            }
        }
    }

    // MARK: - Italic
    private func renderItalic(storage: NSTextStorage, text: String, editingLine: NSRange) {
        let pattern = "(?<!\\*)\\*([^*]+)\\*(?!\\*)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }

        let italicFont = NSFontManager.shared.font(
            withFamily: NSFont.systemFont(ofSize: 16).familyName ?? "Helvetica",
            traits: .italicFontMask,
            weight: 5,
            size: 16
        ) ?? NSFont.systemFont(ofSize: 16)

        for match in regex.matches(in: text, range: NSRange(location: 0, length: text.count)) {
            let fullRange = match.range
            let contentRange = match.range(at: 1)

            if isEditing(fullRange, in: editingLine) {
                storage.addAttributes([.font: italicFont], range: fullRange)
                storage.addAttributes([
                    .foregroundColor: NSColor.tertiaryLabelColor
                ], range: NSRange(location: fullRange.location, length: 1))
                storage.addAttributes([
                    .foregroundColor: NSColor.tertiaryLabelColor
                ], range: NSRange(location: fullRange.location + fullRange.length - 1, length: 1))
            } else {
                hideText(in: NSRange(location: fullRange.location, length: 1), storage: storage)
                hideText(in: NSRange(location: fullRange.location + fullRange.length - 1, length: 1), storage: storage)
                storage.addAttributes([.font: italicFont], range: contentRange)
            }
        }
    }

    // MARK: - Links
    private func renderLinks(storage: NSTextStorage, text: String, editingLine: NSRange) {
        let pattern = "\\[([^\\]]+)\\]\\(([^)]+)\\)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }

        for match in regex.matches(in: text, range: NSRange(location: 0, length: text.count)) {
            let fullRange = match.range
            let textRange = match.range(at: 1)
            let urlRange = match.range(at: 2)

            if isEditing(fullRange, in: editingLine) {
                storage.addAttributes([
                    .foregroundColor: NSColor.systemBlue
                ], range: fullRange)
                storage.addAttributes([
                    .foregroundColor: NSColor.tertiaryLabelColor
                ], range: NSRange(location: fullRange.location, length: 1))
                storage.addAttributes([
                    .foregroundColor: NSColor.tertiaryLabelColor
                ], range: NSRange(location: textRange.location + textRange.length, length: 2))
                storage.addAttributes([
                    .foregroundColor: NSColor.systemGray
                ], range: urlRange)
                storage.addAttributes([
                    .foregroundColor: NSColor.tertiaryLabelColor
                ], range: NSRange(location: fullRange.location + fullRange.length - 1, length: 1))
            } else {
                // [ 숨기기
                hideText(in: NSRange(location: fullRange.location, length: 1), storage: storage)
                // ]( 숨기기
                hideText(in: NSRange(location: textRange.location + textRange.length, length: 2), storage: storage)
                // URL 숨기기
                hideText(in: urlRange, storage: storage)
                // ) 숨기기
                hideText(in: NSRange(location: fullRange.location + fullRange.length - 1, length: 1), storage: storage)

                storage.addAttributes([
                    .foregroundColor: NSColor.systemBlue,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ], range: textRange)
            }
        }
    }

    // MARK: - Blockquotes
    private func renderBlockquotes(storage: NSTextStorage, text: String, editingLine: NSRange) {
        let pattern = "^(>) (.+)$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) else { return }

        let quoteParagraph = NSMutableParagraphStyle()
        quoteParagraph.headIndent = 16
        quoteParagraph.firstLineHeadIndent = 0
        quoteParagraph.paragraphSpacingBefore = 8
        quoteParagraph.paragraphSpacing = 8

        for match in regex.matches(in: text, range: NSRange(location: 0, length: text.count)) {
            let markerRange = match.range(at: 1)
            let contentRange = match.range(at: 2)

            if isEditing(match.range, in: editingLine) {
                storage.addAttributes([
                    .foregroundColor: NSColor.systemBlue
                ], range: markerRange)
                storage.addAttributes([
                    .foregroundColor: NSColor.secondaryLabelColor,
                    .paragraphStyle: quoteParagraph
                ], range: contentRange)
            } else {
                // > 를 파란 막대로 대체 효과
                storage.addAttributes([
                    .foregroundColor: NSColor.systemBlue,
                    .font: NSFont.systemFont(ofSize: 20, weight: .heavy)
                ], range: markerRange)
                storage.addAttributes([
                    .foregroundColor: NSColor.secondaryLabelColor,
                    .backgroundColor: NSColor.systemBlue.withAlphaComponent(0.05),
                    .paragraphStyle: quoteParagraph
                ], range: contentRange)
            }
        }
    }

    // MARK: - Lists
    private func renderLists(storage: NSTextStorage, text: String, editingLine: NSRange) {
        // 불릿 리스트
        let bulletPattern = "^(\\s*)([-*]) (.+)$"
        if let regex = try? NSRegularExpression(pattern: bulletPattern, options: .anchorsMatchLines) {
            for match in regex.matches(in: text, range: NSRange(location: 0, length: text.count)) {
                let bulletRange = match.range(at: 2)

                if !isEditing(match.range, in: editingLine) {
                    // - 또는 * 를 • 스타일로
                    storage.addAttributes([
                        .foregroundColor: NSColor.systemBlue
                    ], range: bulletRange)
                }
            }
        }

        // 숫자 리스트
        let numberPattern = "^(\\s*)(\\d+\\.) (.+)$"
        if let regex = try? NSRegularExpression(pattern: numberPattern, options: .anchorsMatchLines) {
            for match in regex.matches(in: text, range: NSRange(location: 0, length: text.count)) {
                let numberRange = match.range(at: 2)

                storage.addAttributes([
                    .foregroundColor: NSColor.systemBlue,
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 16, weight: .medium)
                ], range: numberRange)
            }
        }
    }

    // MARK: - Horizontal Rules
    private func renderHorizontalRules(storage: NSTextStorage, text: String, editingLine: NSRange) {
        let pattern = "^[-*_]{3,}$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) else { return }

        var hrRanges: [NSRange] = []

        let hrParagraph = NSMutableParagraphStyle()
        hrParagraph.alignment = .center
        hrParagraph.paragraphSpacingBefore = 20
        hrParagraph.paragraphSpacing = 20

        for match in regex.matches(in: text, range: NSRange(location: 0, length: text.count)) {
            hrRanges.append(match.range)

            if isEditing(match.range, in: editingLine) {
                // 편집 중: 원본 표시
                storage.addAttributes([
                    .foregroundColor: NSColor.tertiaryLabelColor,
                    .paragraphStyle: hrParagraph
                ], range: match.range)
            } else {
                // 렌더링: 텍스트 숨기고 Layout Manager가 선 그림
                storage.addAttributes([
                    .font: NSFont.systemFont(ofSize: 0.1),
                    .foregroundColor: NSColor.clear,
                    .paragraphStyle: hrParagraph
                ], range: match.range)
            }
        }

        // Layout Manager에 수평선 범위 전달
        codeBlockLayoutManager?.horizontalRuleRanges = hrRanges
    }

    // MARK: - Copy Support
    override func copy(_ sender: Any?) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let range = selectedRange()
        if range.length > 0 {
            let selectedText = (string as NSString).substring(with: range)
            pasteboard.setString(selectedText, forType: .string)
        } else {
            pasteboard.setString(string, forType: .string)
        }
    }
}
