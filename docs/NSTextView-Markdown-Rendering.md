# NSTextView에서 Notion 스타일 마크다운 렌더링 구현기

## 목표
NSTextView에서 Notion처럼 마크다운을 WYSIWYG 스타일로 렌더링하기

- 코드 블록: 둥근 모서리 박스 안에 코드 표시
- 수평선 (`---`): 실제 가로선으로 렌더링
- 헤더, 볼드, 이탤릭 등: 문법 기호 숨기고 스타일만 적용

---

## 삽질 1: Attributed String의 backgroundColor

### 시도
```swift
storage.addAttributes([
    .backgroundColor: NSColor.gray
], range: codeBlockRange)
```

### 문제
- 라인별로 배경색이 적용됨
- 하나의 박스가 아니라 줄마다 따로 하이라이트
- 코드 블록이 "덩어리"로 안 보임

### 결론
❌ Attributed String의 backgroundColor는 블록 단위 배경에 부적합

---

## 삽질 2: NSTextBlock 사용

### 시도
```swift
let codeBlock = NSTextBlock()
codeBlock.backgroundColor = codeBlockBackground
codeBlock.setWidth(8, type: .absoluteValueType, for: .padding)

let paragraphStyle = NSMutableParagraphStyle()
paragraphStyle.textBlocks = [codeBlock]

storage.addAttributes([
    .paragraphStyle: paragraphStyle
], range: fullRange)
```

### 문제
- `borderColor`가 메서드인데 프로퍼티처럼 사용 → 컴파일 에러
- `setBorderColor(_:for:)` 메서드로 수정해도 렌더링이 이상함
- 라운드 코너 지원 안 됨

### 에러 메시지
```
Cannot assign to value: 'borderColor' is a method
```

### 해결
```swift
codeBlock.setBorderColor(NSColor.systemBlue, for: .minX)
```

### 결론
❌ NSTextBlock은 기본적인 박스만 지원, Notion 스타일 불가

---

## 삽질 3: draw(_:) 오버라이드

### 시도
```swift
class NotionStyleTextView: NSTextView {
    override func draw(_ dirtyRect: NSRect) {
        drawCodeBlockBackgrounds()  // 배경 먼저 그리기
        super.draw(dirtyRect)
    }
}
```

### 문제
- `super.draw()`가 텍스트뷰 배경을 다시 그려서 커스텀 배경을 덮어씀
- 배경이 하얗게만 보임

### 결론
❌ NSTextView의 draw()에서 배경 그리기는 덮어써짐

---

## 해결: Custom NSLayoutManager

### 핵심 발견
`NSLayoutManager.drawBackground(forGlyphRange:at:)`를 오버라이드하면 텍스트 배경 뒤에 커스텀 그래픽을 그릴 수 있음

### 최종 구현

```swift
class CodeBlockLayoutManager: NSLayoutManager {
    var codeBlockRanges: [NSRange] = []
    var horizontalRuleRanges: [NSRange] = []

    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

        guard let textContainer = textContainers.first,
              let textView = textContainer.textView else { return }

        NSGraphicsContext.saveGraphicsState()

        // 코드 블록 - 라운드 박스 그리기
        for range in codeBlockRanges {
            let glyphRange = self.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            var rect = boundingRect(forGlyphRange: glyphRange, in: textContainer)

            // 좌표 조정
            rect.origin.x = origin.x + 8
            rect.origin.y += origin.y
            rect.size.width = textView.bounds.width - textView.textContainerInset.width * 2 - 16

            // 패딩 추가
            rect.origin.y -= 8
            rect.size.height += 16

            // 라운드 박스
            let path = NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8)
            codeBlockBackground.setFill()
            path.fill()
        }

        // 수평선 - 실제 선 그리기
        for range in horizontalRuleRanges {
            let glyphRange = self.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            let rect = boundingRect(forGlyphRange: glyphRange, in: textContainer)

            let lineY = rect.origin.y + origin.y + rect.height / 2
            let linePath = NSBezierPath()
            linePath.move(to: NSPoint(x: startX, y: lineY))
            linePath.line(to: NSPoint(x: endX, y: lineY))
            linePath.lineWidth = 1.5

            NSColor.separatorColor.setStroke()
            linePath.stroke()
        }

        NSGraphicsContext.restoreGraphicsState()
    }
}
```

### TextKit 설정

```swift
// Custom Layout Manager 연결
let textStorage = NSTextStorage()
let layoutManager = CodeBlockLayoutManager()
textStorage.addLayoutManager(layoutManager)

let textContainer = NSTextContainer(containerSize: containerSize)
textContainer.widthTracksTextView = true
layoutManager.addTextContainer(textContainer)

let textView = NotionStyleTextView(frame: .zero, textContainer: textContainer)
```

### 범위 전달

```swift
// 렌더링 시 Layout Manager에 범위 전달
func renderCodeBlocks(...) {
    // ... 코드 블록 찾기 ...
    codeBlockLayoutManager?.codeBlockRanges = codeBlockRanges
}

func renderHorizontalRules(...) {
    // ... 수평선 찾기 ...
    codeBlockLayoutManager?.horizontalRuleRanges = hrRanges
}
```

---

## 핵심 교훈

| 방법 | 결과 | 이유 |
|------|------|------|
| `.backgroundColor` 속성 | ❌ | 라인별 하이라이트만 가능 |
| `NSTextBlock` | ❌ | 라운드 코너 불가, 제한적 |
| `draw()` 오버라이드 | ❌ | super.draw()가 덮어씀 |
| `NSLayoutManager.drawBackground()` | ✅ | 텍스트 뒤 배경에 자유롭게 그리기 가능 |

---

## 다크모드 지원

```swift
var codeBlockBackground: NSColor {
    if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
        return NSColor(white: 0.2, alpha: 1.0)  // 다크모드
    } else {
        return NSColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1.0)  // 라이트모드
    }
}
```

---

## 스크롤 문제 해결

Custom Layout Manager 사용 시 스크롤이 안 되는 문제 발생

### 원인
- textContainer 크기 설정 오류
- isVerticallyResizable 미설정

### 해결
```swift
textContainer.widthTracksTextView = true
textContainer.heightTracksTextView = false  // 중요!

textView.minSize = NSSize(width: 0, height: 0)
textView.maxSize = NSSize(width: .greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
textView.isVerticallyResizable = true
textView.isHorizontallyResizable = false
```

---

## 참고 사항

- Notion은 웹 기반(Electron)이라 CSS로 쉽게 박스 스타일링 가능
- NSTextView에서 같은 효과를 내려면 TextKit의 Layout Manager 커스터마이징 필요
- TextKit 2 (iOS 15+, macOS 12+)에서는 더 쉬운 방법이 있을 수 있음
