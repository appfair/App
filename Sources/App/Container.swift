import FairApp

///// The entry point to creating a scene and settings.
//public extension AppContainer {
//    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
//        WindowGroup { // or DocumentGroup
//            FacetHostingView(store: store).environmentObject(store)
//        }
//        .commands {
//            //SidebarCommands()
//            FacetCommands(store: store)
//        }
//    }
//
//    static func settingsView(store: Store) -> some SwiftUI.View {
//        Store.AppFacets.settings.environmentObject(store)
//    }
//}

@available(macOS 12.0, iOS 15.0, *)
public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        MotionScene()
    }

    static func settingsView(store: Store) -> some SwiftUI.View {
        Store.AppFacets.settings
            .facetView(for: store)
            .environmentObject(store)
    }
}
