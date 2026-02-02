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
                PostListView()
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
