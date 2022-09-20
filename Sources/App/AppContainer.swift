import FairApp

public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        WindowGroup {
            FacetHostingView<WeatherFacets>()
                .environmentObject(store)
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
        WeatherFacets.allCases.last!
            .environmentObject(store)
    }
}

