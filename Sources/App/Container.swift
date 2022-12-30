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
            FacetHostingView(store: store)
                .onChange(of: scenePhase, perform: scenePhaseChanged)
        }

        func scenePhaseChanged(_ phase: ScenePhase) {
            dbg(phase)
            do {
                let root = try loadSourceRoot()
                dbg("root:", root)
            } catch {
                dbg(error)
            }

        }

        func loadSourceRoot() throws -> URL {
            let env = ProcessInfo.processInfo.environment // "DYLD_LIBRARY_PATH": "/Users/marc/Library/Developer/Xcode/DerivedData/App-eyahphpvsfdoezahxmpgdlrnhwxg/Build/Products/Debug-iphonesimulator:/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/usr/lib/system/introspection"

            guard let dyld = env["DYLD_LIBRARY_PATH"]?.split(separator: ":").first else { // e.g. /Users/marc/Library/Developer/Xcode/DerivedData/App-eyahphpvsfdoezahxmpgdlrnhwxg/Build/Products/Debug-iphonesimulator
                throw CocoaError(.fileNoSuchFile)
            }


            // we have a bunch of potential places to guess here, but this is one of them…
            let workspaceInfo = URL(fileURLWithPath: "../../../info.plist", isDirectory: false, relativeTo: URL(fileURLWithPath: String(dyld), isDirectory: true))
            let plist = try PropertyListSerialization.propertyList(from: Data(contentsOf: workspaceInfo), options: [], format: nil)

            guard let workspacePath = (plist as? NSDictionary)?["WorkspacePath"] as? String else {
                // I don't know what this will contain if it isn't launched from a workspace
                throw CocoaError(.fileNoSuchFile)
            }

            // workspacePath will be something like: /opt/src/appfair/World-Fair/App.xcworkspace
            return URL(fileURLWithPath: workspacePath).deletingLastPathComponent() // /opt/src/appfair/World-Fair
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
