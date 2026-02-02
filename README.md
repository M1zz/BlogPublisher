# Blog Publisher

Claude와 함께 블로그 글을 작성하고 여러 플랫폼에 발행하는 macOS 앱입니다.

## 기능

### ✍️ Claude 연동 글 작성
- 앱 내에서 Claude와 대화하며 글 작성
- "글 작성해줘", "개선해줘", "SEO 최적화" 등 빠른 액션 버튼
- AI가 작성한 내용을 원클릭으로 에디터에 적용

### 📝 WYSIWYG 마크다운 에디터
- Notion 스타일의 실시간 마크다운 렌더링
- 제목, 부제목, 태그 관리
- 글 상태 관리 (초안, 발행 준비, 발행됨)

### 📤 멀티 플랫폼 발행
- Hashnode (완전 자동)
- Substack (클립보드 복사)
- DEV.to (완전 자동)
- Medium (완전 자동)
- Tistory (완전 자동)
- Custom API (사용자 정의)

### 📁 프로젝트 관리
- 블로그별 프로젝트 분리 (개발 블로그, 성장 뉴스레터 등)
- 프로젝트별 플랫폼 설정
- 글 내보내기/가져오기

## 설치

### 요구사항
- macOS 14.0 (Sonoma) 이상
- Xcode 15.0 이상

### 빌드 방법

1. `BlogPublisher.swiftpm` 폴더를 Xcode에서 열기
   ```bash
   open BlogPublisher.swiftpm
   ```

2. Product > Run (⌘R) 로 실행

### 또는 터미널에서 빌드

```bash
cd BlogPublisher.swiftpm
swift build
swift run
```

## 초기 설정

### 1. Claude API 키 설정

1. [Anthropic Console](https://console.anthropic.com/) 에서 API 키 발급
2. 앱 설정 (⌘,) > Claude API > API Key 입력

### 2. 플랫폼 설정

각 프로젝트에서 발행할 플랫폼을 추가합니다.

#### Hashnode
1. [Hashnode Settings > Developer](https://hashnode.com/settings/developer) 에서 토큰 생성
2. Publication ID: 대시보드 URL에서 확인 (`hashnode.com/[PUBLICATION_ID]/dashboard`)

#### Substack
- 공식 API가 없어 클립보드 복사 방식으로 동작
- 발행 시 HTML이 클립보드에 복사됨 → Substack 에디터에 붙여넣기

#### DEV.to
1. [DEV.to Settings > Extensions](https://dev.to/settings/extensions) 에서 API Key 생성

#### Medium
1. [Medium Settings](https://medium.com/me/settings) > Security > Integration Tokens
2. Author ID: Settings에서 확인

#### Tistory
1. [Tistory 오픈 API](https://www.tistory.com/guide/api/manage/register) 에서 앱 등록
2. Access Token 발급

## 사용법

### 글 작성

1. 사이드바에서 프로젝트 선택
2. 새 글 생성 (⌘N)
3. 제목, 부제목, 태그 입력
4. WYSIWYG 에디터에서 마크다운으로 작성

### Claude와 함께 작성

1. 오른쪽 Claude 패널에서 대화
2. "이 주제로 블로그 글 써줘" 등 요청
3. Claude가 작성한 내용 확인
4. "글에 적용" 버튼으로 에디터에 반영

### 발행

1. 발행 버튼 (⌘⇧P) 클릭
2. 발행할 플랫폼 선택
3. "발행" 클릭
4. 결과 확인 및 발행된 URL로 이동

## 단축키

| 기능 | 단축키 |
|------|--------|
| 새 글 | ⌘N |
| 새 프로젝트 | ⌘⇧N |
| 발행 | ⌘⇧P |
| 모든 플랫폼에 발행 | ⌘⌥P |
| 설정 | ⌘, |

## 데이터 저장 위치

```
~/Library/Application Support/BlogPublisher/
├── projects.json    # 프로젝트 및 글 데이터
├── settings.json    # 앱 설정
└── Backups/         # 백업 파일
```

## 라이선스

MIT License
