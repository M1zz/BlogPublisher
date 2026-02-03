import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSettings = false

    private var needsSetup: Bool {
        appState.selectedProject?.platforms.isEmpty ?? true
    }

    var body: some View {
        VStack(spacing: 0) {
            // API 설정 안내 배너
            if needsSetup {
                SetupBanner(showSettings: $showSettings)
            }

            NavigationSplitView {
                VStack(spacing: 0) {
                    PostListView()

                    Divider()

                    // Growth Tools Section
                    GrowthToolsBar()
                }
                .frame(minWidth: 260)
            } detail: {
                if appState.selectedPost != nil {
                    MainEditorView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    EmptyStateView()
                }
            }
            .navigationSplitViewStyle(.balanced)
        }
        .sheet(isPresented: $appState.showNewProjectSheet) {
            NewProjectSheet()
        }
        .sheet(isPresented: $appState.showNewPlatformSheet) {
            NewPlatformSheet()
        }
        .sheet(isPresented: $appState.showPublishSheet) {
            PublishSheet()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.showIdeasSheet) {
            IdeasView()
        }
        .sheet(isPresented: $appState.showTemplatesSheet) {
            TemplatesView()
        }
        .sheet(isPresented: $appState.showDashboardSheet) {
            DashboardView()
        }
        .sheet(isPresented: $appState.showPomodoroSheet) {
            PomodoroTimerView()
        }
        .sheet(isPresented: $appState.showSEOSheet) {
            SEOAnalysisView()
        }
        .sheet(isPresented: $appState.showAITitleSheet) {
            AITitleSuggestionsView()
        }
        .sheet(isPresented: $appState.showSeriesSheet) {
            SeriesManagementView()
        }
        .sheet(isPresented: $appState.showScheduleSheet) {
            SchedulePublishView()
        }
        .alert("오류", isPresented: .init(
            get: { appState.errorMessage != nil },
            set: { if !$0 { appState.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) {
                appState.errorMessage = nil
            }
        } message: {
            Text(appState.errorMessage ?? "")
        }
    }
}

// MARK: - Growth Tools Bar
struct GrowthToolsBar: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 8) {
            // Streak Display
            MiniStreakView()

            // Tool Buttons
            HStack(spacing: 4) {
                ToolButton(icon: "lightbulb.fill", label: "아이디어", color: .yellow) {
                    appState.showIdeasSheet = true
                }
                ToolButton(icon: "doc.text.fill", label: "템플릿", color: .blue) {
                    appState.showTemplatesSheet = true
                }
                ToolButton(icon: "chart.bar.fill", label: "대시보드", color: .green) {
                    appState.showDashboardSheet = true
                }
                ToolButton(icon: "timer", label: "포모도로", color: .red) {
                    appState.showPomodoroSheet = true
                }
            }
        }
        .padding(8)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct ToolButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Setup Banner
struct SetupBanner: View {
    @EnvironmentObject var appState: AppState
    @Binding var showSettings: Bool
    @State private var isExpanded = true

    var body: some View {
        if isExpanded {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("설정이 필요합니다")
                            .font(.headline)
                        Text("글을 발행하려면 플랫폼을 추가하세요")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("플랫폼 추가") {
                        appState.showNewPlatformSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button {
                        withAnimation {
                            isExpanded = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color.orange.opacity(0.3)),
                alignment: .bottom
            )
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
            
            Text("글을 선택하거나 새 글을 작성하세요")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Button {
                appState.createNewPost()
            } label: {
                Label("새 글 작성", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
