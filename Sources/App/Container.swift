import FairApp

/// The entry point to creating a scene and settings.
public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        WindowGroup { // or DocumentGroup
            HostingView().environmentObject(store)
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

    struct HostingView : View {
        @EnvironmentObject var store: Store
        @Environment(\.scenePhase) var scenePhase

        public var body: some View {
            ScriptNavigatorView()
            // FacetHostingView(store: store)
            //     .onChange(of: scenePhase, perform: scenePhaseChanged)
        }
    }
}

extension View {
    /// Uses the `refreshable` action on supported platforms
    func refreshableIfSupported(_ block: @Sendable @escaping () async -> ()) -> some View {
        #if targetEnvironment(macCatalyst)
        // else: “SwiftUI.UIKitRefreshControl is not supported when running Catalyst apps in the Mac idiom. See UIBehavioralStyle for possible alternatives. Consider using a Refresh menu item bound to ⌘-R”
        self
        #else
        refreshable(action: block)
        #endif
    }
}
