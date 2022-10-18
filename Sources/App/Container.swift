import FairApp
import AVKit

/// The entry point to creating a scene and settings.
public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        rootSceneFacet(store: store)
        //rootSceneClassic(store: store)
    }

    @SceneBuilder static func rootSceneFacet(store: Store) -> some SwiftUI.Scene {
        WindowGroup { // or DocumentGroup
            FacetHostingView(store: store).environmentObject(store)
        }
        .commands {
            SidebarCommands()
            FacetCommands(store: store)
        }
    }

    @SceneBuilder static func rootSceneClassic(store: Store) -> some SwiftUI.Scene {
        WindowGroup {
            ContentView()
                .windowToolbarUnified(compact: true, showsTitle: true)
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
            // iOS only
            // .onReceive(NotificationCenter.default.publisher(for: UXApplication.didEnterBackgroundNotification)) { _ in
            //      dbg("didEnterBackgroundNotification")
            //            AVAudioSession.sharedInstance
        }
        .commands {
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

