import FairApp
import AVKit

/// The entry point to creating a scene and settings.
public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        rootSceneFacet(store: store)
    }

    @SceneBuilder static func rootSceneFacet(store: Store) -> some SwiftUI.Scene {
        WindowGroup { // or DocumentGroup
            FacetHostingView(store: store)
                .environmentObject(store)
                .task {
                    //await store.createStatusItems()
                    //await store.setDockMenu()
                    do {
#if os(iOS)
                        try AVAudioSession.sharedInstance().setCategory(.playback)
                        try AVAudioSession.sharedInstance().setActive(true)
#endif
                    } catch {
                        dbg("error setting up session:", error)
                    }
                }
        }
        .commands {
            SidebarCommands()
            FacetCommands(store: store)
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                // only permit a single window
            }
        }
    }

    static func settingsView(store: Store) -> some SwiftUI.View {
        //Store.AppFacets.settings.environmentObject(store)
        SettingsView().environmentObject(store)
    }
}

