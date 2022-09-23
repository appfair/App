import FairApp
import AVKit

/// The `FairApp.FairContainer` that acts as a factory for the content and settings view.
public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
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

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store: Store) -> some SwiftUI.View {
        SettingsView().environmentObject(store)
    }
}
