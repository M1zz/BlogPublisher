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
                
                Button("새 프로젝트") {
                    appState.showNewProjectSheet = true
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
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
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
