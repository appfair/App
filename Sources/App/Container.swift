import FairApp

/// The `FairApp.FairContainer` that acts as a factory for the content and settings view.
public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(SunBowPod.shared)
        }
        .commands {
            SidebarCommands()
            ToolbarCommands()
            FacetCommands<WeatherFacets>()
        }
        #if os(macOS)
        .windowToolbarStyle(.unified(showsTitle: true))
        #endif
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store: Store) -> some SwiftUI.View {
        WeatherFacets.allCases.last.unsafelyUnwrapped
            .environmentObject(store)
            .environmentObject(SunBowPod.shared)
    }
}

