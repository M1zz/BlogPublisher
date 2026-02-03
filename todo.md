# BlogPublisher - 기능 구현 현황

## 완료된 기능

### 1. 일관성 유지 기능
- [x] **발행 스케줄러** - SchedulePublishView에서 특정 시간에 발행 예약 가능
- [x] **글 작성 스트릭** - WritingStats에서 연속 작성 일수 추적
- [x] **초안 템플릿** - 5가지 기본 템플릿 (TIL, 튜토리얼, 회고, 기술리뷰, 문제해결)
- [x] **아이디어 저장소** - IdeasView에서 빠르게 주제 메모

### 2. 콘텐츠 최적화
- [x] **AI 제목 추천** - Claude API를 활용한 클릭율 높은 제목 5개 생성
- [x] **SEO 점수** - 키워드 밀도, 제목 길이, 메타 설명 분석
- [x] **가독성 분석** - 문장 길이, 단락 구조 피드백

### 3. 성과 추적
- [x] **통합 대시보드** - DashboardView에서 전체 통계 확인
- [x] **발행 히트맵** - GitHub 스타일 365일 히트맵
- [x] **플랫폼별 발행 통계** - 각 플랫폼별 발행 수 시각화

### 4. 콘텐츠 재활용
- [x] **트위터/스레드 변환** - 글을 280자 단위 스레드로 자동 분할
- [x] **시리즈 관리** - SeriesManagementView에서 연재물 관리

### 5. 습관 형성
- [x] **포모도로 타이머** - 15/25/45/60분 타이머
- [x] **주간 발행 목표** - WritingStats에서 목표 설정 및 추적

## 파일 구조

```
BlogPublisher/
├── Models.swift          - 데이터 모델 (Idea, PostTemplate, Series, WritingStats 등)
├── AppState.swift        - 앱 상태 관리 + 분석 로직
├── StorageService.swift  - 로컬 저장소 (아이디어, 템플릿, 통계 등)
├── ContentView.swift     - 메인 뷰 + GrowthToolsBar
├── MainEditorView.swift  - 에디터 + 콘텐츠 도구 메뉴
├── GrowthFeaturesView.swift    - 대시보드, 히트맵, 스트릭
├── ContentToolsView.swift      - AI 제목, SEO 분석, 가독성, 스레드 변환
├── ProductivityView.swift      - 아이디어, 포모도로, 예약 발행
└── TemplatesView.swift         - 템플릿, 시리즈 관리
```

## 키보드 단축키

| 단축키 | 기능 |
|--------|------|
| ⌘N | 새 글 |
| ⌘⌥N | 템플릿에서 새 글 |
| ⌘⇧N | 새 프로젝트 |
| ⌘⇧I | 아이디어 저장소 |
| ⌘⇧P | 발행 |
| ⌘⌥P | 모든 플랫폼 발행 |
| ⌘⌃P | 발행 예약 |
| ⌘⇧T | AI 제목 추천 |
| ⌘⇧E | SEO 분석 |
| ⌘⇧D | 대시보드 |
| ⌘⇧F | 포모도로 타이머 |

## 미구현/향후 개선

- [ ] 썸네일 자동 생성 (이미지 생성 API 필요)
- [ ] 데일리 리마인더 (로컬 알림)
- [ ] 주간 리포트 이메일
- [ ] 크로스포스팅 최적화 (플랫폼별 포맷 조정)
- [ ] 플랫폼별 실제 조회수/좋아요 통계 연동
