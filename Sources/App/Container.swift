import FairApp

/// The entry point to creating a scene and settings.
public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        WindowGroup { // or DocumentGroup
            FacetHostingView(store: store).environmentObject(store)
        }
    }

    static func settingsView(store: Store) -> some SwiftUI.View {
        Store.AppFacets.settings.environmentObject(store)
    }
}

