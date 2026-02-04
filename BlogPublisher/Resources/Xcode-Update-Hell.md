# Xcode 업데이트만 2시간, 개발은 언제 하지

오늘도 맥북을 켰더니 빨간 뱃지가 반갑게 맞이해준다. App Store 알림 1. 클릭해보니 역시나 Xcode 업데이트. 16.2GB. 예상 소요 시간 2시간 30분.

한숨부터 나온다. 오늘 하려던 작업은 1시간이면 끝날 간단한 버그 픽스였는데, 업데이트 시간이 작업 시간보다 두 배 반이나 길다니. 게다가 이번엔 AI 코딩 어시스턴트가 추가되었다며 용량이 더 커졌다.

---

## 업데이트 안 하면 안 되나요?

처음엔 그냥 무시하고 개발하려고 했다. 근데 문제는 Xcode를 안 업데이트하면 생기는 일들이 너무 많다는 거다.

**2026년 현재, 실제로 겪은 일들**

```swift
// iOS 18 SDK가 필요한 새 API
if #available(iOS 18.0, *) {
    // Xcode 16이 없으면 컴파일조차 안 됨
    view.configureWithAdaptiveLayout { configuration in
        configuration.enableDynamicTypeScaling = true
    }
}

// Swift 6의 strict concurrency
actor DataManager {
    // Xcode 15에서는 actor 문법이 제대로 지원 안 됨
}
```

"이 프로젝트는 Xcode 16.0 이상이 필요합니다"

물론이죠. 팀원이 Xcode 업데이트했는데 나만 안 했으면, 프로젝트 열리지도 않는다. Git conflict보다 더 짜증나는 게 Xcode 버전 차이다.

앱스토어 제출할 때는 더 심각하다. 2025년 말부터 애플이 "iOS 18 SDK로 빌드된 앱만 받습니다"라고 선언했다. 무조건 최신 Xcode가 필요하다.

그리고 솔직히 말하면, AI 코딩 어시스턴트가 궁금하다. "자연어로 코드 작성"이라니, 써보고 싶지 않나?

결국 선택지는 없다. 업데이트는 필수다.

---

## 16GB씩이나 되는 이유가 뭔데

Xcode 하나가 Visual Studio Code의 15배 크기다. 이유를 알아보니 더 황당했다.

**Xcode 16에 들어있는 것들**

- iOS 18, iPadOS 18, watchOS 11, tvOS 18, visionOS 2 시뮬레이터
- macOS Sequoia SDK
- Swift 6 컴파일러 (strict concurrency 지원)
- Swift Testing 프레임워크
- AI 코딩 어시스턴트 모델 (이게 용량을 엄청 차지함)
- Metal 3 디버거
- RealityKit 4
- Interface Builder, Instruments, Reality Composer Pro
- 문서 및 샘플 코드

그러니까 하나의 앱에 6개 플랫폼 전체가 들어있고, 거기에 AI 모델까지 포함된 셈이다. Flutter나 React Native 개발자들이 부러운 이유가 여기 있다.

더 짜증나는 건 "델타 업데이트"가 여전히 없다는 것. 16GB 중에 실제로 바뀐 건 2GB도 안 될 텐데, 매번 전체를 다시 다운로드한다.

**내 맥북 용량 현황 (2026년 기준)**

```bash
$ du -sh /Applications/Xcode.app
41 GB   /Applications/Xcode.app  # AI 모델 포함

$ ls -lh ~/Library/Developer/Xcode
합계 32GB  # 파생 데이터, 시뮬레이터, AI 캐시 등
```

Xcode와 관련 파일만 73GB. M3 Max의 1TB 저장공간도 모자라다.

---

## AI 어시스턴트 때문에 더 느려졌다

Xcode 16의 가장 큰 변화는 생성형 AI 통합이다. 근데 이게 축복인지 저주인지 모르겠다.

**좋은 점**

```swift
// 자연어로 요청하면 코드를 생성해줌
// "이미지를 비동기로 다운로드하고 캐시하는 함수 만들어줘"

func downloadImage(from url: URL) async throws -> UIImage {
    // Xcode AI가 자동 생성
    if let cached = ImageCache.shared.image(for: url) {
        return cached
    }

    let (data, _) = try await URLSession.shared.data(from: url)
    guard let image = UIImage(data: data) else {
        throw ImageError.invalidData
    }

    ImageCache.shared.store(image, for: url)
    return image
}
```

솔직히 편하다. 보일러플레이트 코드는 AI한테 맡기면 된다.

**나쁜 점**

- AI 응답 대기 시간: 5-10초
- 인터넷 연결 필수 (Apple의 서버와 통신)
- 가끔 이상한 코드 생성 (Swift 4 스타일로 짜거나...)
- 배터리 소모 증가
- 그리고... **용량 16GB의 주범**

결국 AI는 끄고 쓰는 사람이 태반이다.

---

## 2시간 30분 동안 뭐 하지?

업데이트 시작하면 맥북은 사실상 사용 불가다. M3 Max여도 팬은 풀가동, CPU는 100%, AI 모델 다운로드 때문에 네트워크도 풀가동이다.

**시도해본 것들**

1. **그냥 기다리기** - 가장 현명한 선택. 커피 마시러 가거나 산책하기.

2. **업데이트하면서 코딩하기** - 시도는 했다. Simulator가 안 돌아가고, AI 어시스턴트가 "업데이트 중에는 사용 불가"라고 하고, Xcode가 튕기고... 결국 포기.

3. **예전 Xcode로 작업하기** - Xcode 15와 16을 동시에 쓰는 방법. 근데 Swift 6 프로젝트는 Xcode 15에서 안 열린다.

4. **Vision Pro로 다른 일 하기** - 2026년답게 Vision Pro를 쓰지만... 사실 그냥 유튜브 본다.

**실제로는 이렇게 됨**

```
09:00 업데이트 시작
09:05 "AI 모델 다운로드 중..." 1%
09:40 "아직도?" → 30%
10:30 "이제 슬슬..." → 55%
11:00 점심 먹으러 나감
12:30 돌아와보니 "Xcode 설치 중..." 무한 로딩
13:00 재부팅
13:15 "남은 시간: 10분" (거짓말)
13:50 드디어 완료
13:55 "Swift 6 마이그레이션 도구를 실행하시겠습니까?"
14:00 "Command Line Tools 업데이트하시겠습니까?" → 또?
14:30 "AI 모델 추가 다운로드 필요" (2GB 더)
```

반나절이 아니라 하루가 증발한다.

---

## 업데이트 후 맞이하는 2026년 현실

업데이트가 끝났다고 해서 바로 개발할 수 있는 건 아니다. 오히려 여기서부터가 시작이다.

**1단계: Swift 6 마이그레이션 지옥**

```
"프로젝트를 Swift 6으로 업데이트하시겠습니까?"
```

아뇨. 절대 안 합니다. Swift 6의 strict concurrency는 기존 코드를 다 빨간줄로 만든다.

```swift
// Swift 5.9에서 잘 되던 코드
class ViewModel {
    var items: [Item] = []

    func update() {
        DispatchQueue.main.async {
            self.items = fetchItems() // Swift 6에서 에러
        }
    }
}

// Swift 6에서 요구하는 코드
@MainActor
class ViewModel {
    var items: [Item] = []

    func update() async {
        self.items = await fetchItems()
    }
}
```

프로젝트 전체를 고쳐야 한다. 마이그레이션은 나중에... 언젠가...

**2단계: 빌드 에러 폭탄**

```swift
// 어제까지 잘 되던 코드
extension View {
    func myModifier() -> some View {
        self.padding()
    }
}

// Xcode 16에서 갑자기
// Warning: 'some View'가 deprecated 되었습니다.
// 대신 'ModifiedContent<Self, PaddingModifier>'를 사용하세요
```

애플이 권장 사항을 바꾸면 기존 코드가 deprecated가 된다. 경고 100개는 기본이다.

**3단계: 시뮬레이터 재다운로드**

"iOS 18.2 Simulator가 없습니다. 다운로드하시겠습니까?" (8.5GB)

아니 방금 16GB 받았는데 왜 또 받아? 알고 보니 최신 OS 시뮬레이터는 여전히 별도로 받아야 한다.

게다가 visionOS 2 시뮬레이터도 받으라고 한다. (12GB) Vision Pro 개발 안 하는데...

**4단계: 의존성 지옥 2026 버전**

```bash
$ pod install
[!] Swift 6.0을 지원하지 않는 라이브러리가 있습니다

$ swift package update
error: Package 'Alamofire' requires Swift 5.9
error: Package 'Realm' is not compatible with Xcode 16

$ carthage update
# 이건 이미 2024년에 죽었다
```

써드파티 라이브러리들이 Xcode 16을 아직 지원 안 하면? Swift 5.9 모드로 돌리거나, 라이브러리를 포크해서 직접 고치거나, 아니면 기다리는 수밖에 없다.

---

## 2026년 생존 전략

몇 년간 이 지옥을 겪으면서 터득한 생존 전략들이다. 2026년 버전으로 업데이트했다.

### 1. 업데이트 타이밍 정하기

**절대 하지 말아야 할 때**
- 월요일 아침: 한 주를 날릴 수 있다
- 릴리스 직전: 자살 행위
- 급한 버그 픽스 있을 때: 당연하지만 사람들은 한다
- Swift 6 마이그레이션 준비 안 됐을 때: 프로젝트가 깨진다

**적절한 타이밍**
- 금요일 오후: 어차피 주말이니까
- 팀 스프린트 끝나고: 다음 주 계획 세우면서 기다리기
- 점심시간 + 회의 시간 + 산책: 3시간이면 딱 맞다
- Swift 5.10으로 안정화된 후: 급하게 Swift 6 쓸 필요 없다

### 2. 여러 Xcode 버전 관리하기 (필수)

2026년에는 이게 생존의 기본이다.

```bash
# xcodes로 여러 버전 관리 (강력 추천)
$ brew install xcodesorg/made/xcodes

# 여러 버전 설치
$ xcodes install 15.4    # 안정판
$ xcodes install 16.0    # 최신판
$ xcodes install 16.1-beta  # 베타 (호기심에...)

# 빠르게 스위칭
$ xcodes select 15.4     # 안정판으로 돌아가기
$ xcodes select 16.0     # 최신으로

# 현재 버전 확인
$ xcode-select -p
```

**주의사항**:
- M3 Max 1TB 기준으로 Xcode 3개 + 시뮬레이터 = 150GB
- 외장 SSD 필수
- Time Machine 끄기 (Xcode 백업하면 용량 폭발)

### 3. AI 어시스턴트 끄기

솔직히 AI는 마케팅이다. 실제로는 GitHub Copilot이나 Cursor가 더 낫다.

```bash
# Xcode 설정 → AI Features → Disable
# 또는 터미널에서
$ defaults write com.apple.dt.Xcode DVTGenerativeIntelligenceEnabled -bool false
```

AI 끄면:
- 앱 시작 5초 빨라짐
- 배터리 30분 더 감
- 인터넷 끊어도 개발 가능
- 용량 3GB 절약

### 4. 시뮬레이터 정리 (2026년 버전)

```bash
# 안 쓰는 시뮬레이터 삭제
$ xcrun simctl delete unavailable

# iOS 16 이하 전부 삭제 (솔직히 iOS 17 이하도 지원 안 해도 됨)
$ xcrun simctl delete "iPhone 14"
$ xcrun simctl delete "iPhone SE (2nd generation)"

# visionOS 시뮬레이터 삭제 (Vision Pro 개발 안 하면)
$ xcrun simctl delete "Apple Vision Pro"

# 파생 데이터 청소
$ rm -rf ~/Library/Developer/Xcode/DerivedData/*

# AI 캐시 청소 (신규!)
$ rm -rf ~/Library/Developer/Xcode/AICache/*

# 이것만으로도 30GB+ 확보 가능
```

### 5. 베타는 정말 건들지 마라

Xcode 베타는 2026년에도 여전히 지뢰밭이다.

**2025년 실제 경험담**

```
Xcode 16.0 Beta 5 설치
→ "Swift 6 체험해보자" 하고 회사 프로젝트 열기
→ "Swift 6으로 업데이트하시겠습니까?" 실수로 Yes
→ 프로젝트 전체에 에러 1,247개
→ Git에 푸시 (커밋 메시지: "WIP: Swift 6 migration")
→ CI/CD 깨짐
→ 팀원들 출근해서 빌드 안 됨
→ 긴급 롤백
→ 프로젝트 파일 충돌
→ 하루 종일 복구
→ 팀장한테 혼남
→ 퇴근 후 이력서 업데이트
```

베타는 개인 맥북에서, 개인 프로젝트로, 혼자 놀아라.

### 6. Swift 5.10 모드 유지하기

Swift 6의 strict concurrency는 아직 이르다. 2026년에도 대부분 프로젝트는 Swift 5 모드다.

```swift
// 프로젝트 설정에서
Swift Language Version: Swift 5
Strict Concurrency Checking: Minimal

// 점진적으로 마이그레이션
// 새 파일만 Swift 6 문법 사용
// 기존 파일은 천천히
```

### 7. 업데이트 후 체크리스트 (2026년 버전)

```markdown
- [ ] Xcode 실행되는지 확인
- [ ] AI 어시스턴트 끄기
- [ ] Command Line Tools 버전 확인
- [ ] Swift 버전 확인 (swift --version)
- [ ] 프로젝트 열기 (업데이트 NO)
- [ ] Clean Build Folder
- [ ] Swift 6 마이그레이션 거부
- [ ] 빌드 테스트
- [ ] 시뮬레이터 테스트 (iOS 18.0 이상)
- [ ] 실제 기기 테스트
- [ ] Git 상태 확인
- [ ] 의존성 라이브러리 호환성 확인
```

---

## 다른 플랫폼 개발자들은 어떨까?

2026년에도 여전히 Android 개발자들이 부럽다.

**Android Studio 업데이트 (2026년)**
- 크기: 2GB (AI 포함해도 3GB)
- 델타 업데이트 지원
- 윈도우/맥/리눅스 다 됨
- Kotlin 2.0 마이그레이션 도구 완벽
- Gemini AI 통합 (구글 것이라 빠름)

**VS Code + Copilot (웹 개발)**
- 크기: 300MB
- AI: GitHub Copilot (Xcode AI보다 훨씬 나음)
- 업데이트: 자동, 백그라운드, 5분
- 하위 호환성: 완벽

**Flutter**
- Xcode는 어차피 필요함 (iOS 빌드)
- 근데 Flutter SDK만 업데이트하면 됨 (1GB 이하)
- Hot Reload 덕분에 시뮬레이터 재시작 불필요

그에 비해 Xcode는...

```
개발자: 간단한 UI 수정하려고 했는데요
Xcode: 16GB 먼저 받으세요
개발자: 아니 5분이면 끝날 건데...
Xcode: 2시간 30분 기다리세요
개발자: AI 어시스턴트는 필요 없는데
Xcode: 선택권 없습니다
개발자: (╯°□°）╯︵ ┻━┻
```

---

## 그래도 Xcode를 써야 하는 이유

불평을 늘어놨지만, Xcode는 여전히 iOS 개발의 유일한 선택지다. 그리고 2026년의 Xcode는 솔직히 좋아졌다.

**Xcode 16의 장점**

1. **SwiftUI 프리뷰**: 여전히 최고. 실시간 프리뷰가 정말 빠르다.
2. **Instruments**: 성능 프로파일링은 타의 추종을 불허한다.
3. **Swift Testing**: XCTest를 대체. 훨씬 직관적이고 강력하다.
4. **Reality Composer Pro**: visionOS 개발할 때 필수.
5. **통합 환경**: 디자인-코딩-테스트-배포가 한 곳에서.
6. **AI 어시스턴트**: 끄고 쓰긴 하지만, 가끔 유용하다.
7. **Metal 3**: 게임 개발할 때 정말 강력.

Flutter나 React Native 쓰더라도 결국 Xcode는 필요하다. iOS 빌드할 때는 어차피 Xcode를 거쳐야 하니까.

---

## 마무리: 2026년에도 여전한 업데이트 지옥

Xcode 업데이트는 iOS 개발자의 숙명이다. 2026년에도, 아마 2030년에도 마찬가지일 것이다.

**핵심 정리**

1. **업데이트는 필수지만 타이밍이 중요하다** - 바쁠 때는 미루자
2. **여러 버전을 유지하라** - xcodes 도구는 필수
3. **Swift 6는 천천히** - 급하게 마이그레이션하지 마라
4. **AI는 선택** - 끄고 써도 된다
5. **용량 관리를 하라** - 외장 SSD 필수
6. **베타는 위험** - 절대 회사 프로젝트에 쓰지 마라

**현실적인 조언 (2026년 버전)**

Xcode 업데이트 알림이 뜨면:
- 급하면 무시하라 (한 달도 버틴다)
- .1 버전까지 기다려라 (16.0보다 16.1이 안정적)
- 팀원들과 타이밍 맞춰라 (버전 차이는 재앙)
- 업데이트 중에는 Vision Pro로 놀아라
- 끝나면 체크리스트 돌려라

그리고 가장 중요한 건:
- **외장 SSD 2TB 장만하라** (1TB는 부족하다)
- **Time Machine 끄라** (Xcode 백업 안 해도 됨)
- **AI 끄고 GitHub Copilot 쓰라** (월 $10 가치 있음)

2시간 30분짜리 업데이트가 짜증나긴 하지만, 그래도 우리는 오늘도 맥북을 켜고 Xcode를 실행한다. 왜냐고?

iOS 개발이 좋으니까.

SwiftUI가 재밌으니까.

그리고 솔직히, 맥북이 멋지니까.

...그리고 업데이트 중에 쓸 글거리가 또 생겼으니까.

---

**P.S.** 이 글은 Xcode 16.2 업데이트를 기다리면서 썼습니다. 아직도 "AI 모델 다운로드 중... 남은 시간: 1시간 15분"이라고 뜨네요. 거짓말입니다. 분명 2시간은 더 걸릴 겁니다.

**P.P.S.** 업데이트 끝나고 보니 AI 어시스턴트가 한국어를 지원 안 합니다. 16GB를 뭐 하러 받은 거죠?
