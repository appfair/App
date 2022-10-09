import FairApp

/// The `FairApp.FairContainer` that acts as a factory for the content and settings view.
public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        WindowGroup {
            // create a top-level facet host (tabs on iOS, outline view on macOS) with the app's facets
            FacetHostingView(store: store)
                .environmentObject(SunBowPod.shared)
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
    @ViewBuilder static func settingsView(store: Store) -> some SwiftUI.View {
        Store.AppFacets.facets(for: store).last.unsafelyUnwrapped
            .environmentObject(store)
            .environmentObject(SunBowPod.shared)
    }
}

