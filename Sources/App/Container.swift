import FairApp

/// The entry point to creating a scene and settings.
public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        WindowGroup { // or DocumentGroup
            FacetHostingView(store: store).environmentObject(store)
                .environmentObject(SunBowPod.shared)
        }
        .commands {
            SidebarCommands()
            FacetCommands(store: store)
        }
        .commands {
            SidebarCommands()
            ToolbarCommands()
            FacetCommands(store: store)
        }
        #if os(macOS)
        .windowToolbarStyle(.unified(showsTitle: true))
        #endif
    }

    /// The app-wide settings view, which, by convention, is the final element of the app facets
    static func settingsView(store: Store) -> some SwiftUI.View {
        Store.AppFacets.settings.environmentObject(store)
            .environmentObject(SunBowPod.shared)
    }
}

