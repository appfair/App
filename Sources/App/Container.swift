import FairApp

/// The `FairApp.FairContainer` that acts as a factory for the content and settings view.
public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
#if os(macOS)
        WindowGroup {
            browserView(store: store)
        }
        .commands(content: { BrowserCommands() })
        .windowToolbarStyle(UnifiedWindowToolbarStyle(showsTitle: false))
#elseif os(iOS)
        WindowGroup {
            NavigationView {
                browserView(store: store)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .commands(content: { BrowserCommands() })
#endif
    }

    static func browserView(store: Store) -> some View {
        BrowserView()
            .environmentObject(store)
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store: Store) -> some SwiftUI.View {
        SettingsView().environmentObject(store)
    }
}
