import FairApp

/// The `FairApp.FairContainer` that acts as a factory for the content and settings view.
public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        WindowGroup {
            FacetHostingView(store: store)
        }
    }
}

extension AppContainer {
    #warning("FIXME: should be done in base protocol extension")

    /// The app-wide settings view, which, by convention, is the final element of the app's facets.
    @ViewBuilder public static func settingsView(store: Store) -> some View {
        AppStore.AppFacets.facets(for: store).last.unsafelyUnwrapped
            .environmentObject(store)
    }
}

