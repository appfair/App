import FairApp

/// The entry point to creating a scene and settings.
public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        WindowGroup { // or DocumentGroup
            FacetHostingView(store: store)
                .environmentObject(store)
                .showingErrorDialog(store)
        }
        .commands {
            //SidebarCommands()
            FacetCommands(store: store)
        }
    }

    static func settingsView(store: Store) -> some SwiftUI.View {
        Store.AppFacets.settings
            .facetView(for: store)
            .environmentObject(store)
    }
}

extension View {
    /// Display an error dialog if any of the store errors exist.
    @MainActor func showingErrorDialog(_ store: Store) -> some View {
        self.alert(isPresented: Binding(get: {
            store.errors.isEmpty == false
        }, set: { presented in
            if presented == false {
                store.errors.removeFirst()
            }
        }), error: store.errors.first) {
            // additional actions (in addition to "OK")
        }
    }
}

/// Needed to convert NSError to something LocalizedError can use.
extension NSError : LocalizedError {

}
