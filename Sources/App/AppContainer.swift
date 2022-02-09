import FairApp

public extension AppContainer {
    @SceneBuilder static func rootScene(store fairManager: FairManager) -> some SwiftUI.Scene {
        WindowGroup {
            RootView(fairManager: fairManager)
                .preferredColorScheme(fairManager.themeStyle.colorScheme)
        }
        .commands {
            AppFairCommands(fairManager: fairManager)
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
            .preferredColorScheme(fairManager.themeStyle.colorScheme)
            .environmentObject(fairManager)
            .environmentObject(fairManager.fairAppInv)
            .environmentObject(fairManager.homeBrewInv)
    }
}
