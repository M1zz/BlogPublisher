import SwiftUI

@main
struct BlogPublisherApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("새 글") {
                    appState.createNewPost()
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("템플릿에서 새 글") {
                    appState.showTemplatesSheet = true
                }
                .keyboardShortcut("n", modifiers: [.command, .option])

                Button("새 프로젝트") {
                    appState.showNewProjectSheet = true
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])

                Divider()

                Button("빠른 아이디어 추가") {
                    appState.showIdeasSheet = true
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            }

            CommandMenu("발행") {
                Button("선택한 플랫폼에 발행") {
                    appState.publishToSelectedPlatforms()
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])

                Button("모든 플랫폼에 발행") {
                    appState.publishToAllPlatforms()
                }
                .keyboardShortcut("p", modifiers: [.command, .option])

                Divider()

                Button("발행 예약") {
                    appState.showScheduleSheet = true
                }
                .keyboardShortcut("p", modifiers: [.command, .control])
            }

            CommandMenu("도구") {
                Button("AI 제목 추천") {
                    appState.showAITitleSheet = true
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])

                Button("SEO 분석") {
                    appState.showSEOSheet = true
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Divider()

                Button("아이디어 저장소") {
                    appState.showIdeasSheet = true
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])

                Button("템플릿") {
                    appState.showTemplatesSheet = true
                }

                Button("시리즈 관리") {
                    appState.showSeriesSheet = true
                }

                Divider()

                Button("대시보드") {
                    appState.showDashboardSheet = true
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])

                Button("포모도로 타이머") {
                    appState.showPomodoroSheet = true
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
