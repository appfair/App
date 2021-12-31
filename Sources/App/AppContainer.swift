import FairApp

public extension AppContainer {
    @SceneBuilder static func rootScene(store appManager: AppManager) -> some SwiftUI.Scene {
        WindowGroup {
            NavigationRootView()
                // .edgesIgnoringSafeArea(.all) // doesn't affect iPhone landscape catalog info header 
                .environmentObject(appManager)
                .preferredColorScheme(appManager.themeStyle.colorScheme)
                .task({ appManager.scanInstalledApps() })
        }
        .commands {
            SidebarCommands()
            SearchCommands()
            AppFairCommands(appManager: appManager)
            ToolbarCommands()
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                // only permit a single window
            }
        }
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store appManager: AppManager) -> some SwiftUI.View {
        AppSettingsView()
            .environmentObject(appManager)
            .preferredColorScheme(appManager.themeStyle.colorScheme)
    }
}
