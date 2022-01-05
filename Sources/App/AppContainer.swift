import FairApp

public extension AppContainer {
    @SceneBuilder static func rootScene(store fairManager: FairManager) -> some SwiftUI.Scene {
        WindowGroup {
            RootView(fairManager: fairManager)
                .preferredColorScheme(fairManager.themeStyle.colorScheme)
        }
        .commands {
            AppFairCommands(appManager: fairManager.appManager)
        }
        .commands {
            SidebarCommands()
            SearchCommands()
            ToolbarCommands()
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                // only permit a single window
            }
        }
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store fairManager: FairManager) -> some SwiftUI.View {
        AppSettingsView()
            .environmentObject(fairManager)
            .preferredColorScheme(fairManager.themeStyle.colorScheme)
    }
}
