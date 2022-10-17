import FairApp

/// The entry point to creating a scene and settings.
public extension AppContainer {
    @SceneBuilder static func rootScene(store fairManager: FairManager) -> some SwiftUI.Scene {
        WindowGroup {
            RootView()
                .initialViewSize(CGSize(width: 1200, height: 700)) // The default size of the window; this will only be set the first time the app is launched, and then restore whatever the user resizes to
                .environmentObject(fairManager)
                .preferredColorScheme(fairManager.themeStyle.colorScheme)
        }
        .commands {
            AppFairCommands(fairManager: fairManager)
        }
        .commands {
            SidebarCommands()
            SearchBarCommands()
            ToolbarCommands()
        }
        .commands {
            CommandGroup(after: .pasteboard) {
                Group {
                    CopyAppURLCommand()
                }
                .environmentObject(fairManager)
            }
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                // only permit a single window; this hides the "New" menu option
            }
        }
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store fairManager: FairManager) -> some SwiftUI.View {
        AppSettingsView()
            .preferredColorScheme(fairManager.themeStyle.colorScheme)
            .environmentObject(fairManager)
    }

}

