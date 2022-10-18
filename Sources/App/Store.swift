import FairApp

/// The global app environment containing configuration metadata and shared defaults.
///
/// The shared instance of Store is available throughout the app with:
///
/// ``@EnvironmentObject var store: Store``
@MainActor public final class Store: SceneManager {
    /// The module bundle for this store, used for looking up embedded resources

    /// The configuration metadata for the app from the `App.yml` file.
    public static let config: JSum = configuration(for: .module)

    @AppStorage("autoplayStation") public var autoplayStation = true

    /// App-wide preference using ``SwiftUI/AppStorage``.
    @AppStorage("togglePreference") public var togglePreference = false

    /// App-wide preference using ``SwiftUI/AppStorage``.
    @AppStorage("numberPreference") public var numberPreference = 0.0

    #if os(macOS)
    public var statusItem: NSStatusItem? = nil
    #endif

    // @Published var queryString: String = ""
    // @Published var stations: DataFrame? = wip(nil)

    public init() {
//        /// The gloal quick actions for the App Fair
//        self.quickActions = [
//            QuickAction(id: "play-action", localizedTitle: loc("Play"), iconSymbol: "play") { completion in
//                dbg("play-action")
//                completion(true)
//            }
//        ]
    }

    @objc public func menuItemTapped(_ sender: Any?) {
        dbg()
    }

    /// AppFacets describes the top-level app, expressed as tabs on a mobile device and outline items on desktops.
    public enum AppFacets : String, Facet, CaseIterable, View {
        /// The initial facet, which typically shows a welcome / onboarding experience
        case welcome
        /// The main content of the app.
        case stations
        /// The setting for the app, which contains app-specific preferences as well as other standard settings
        case settings

        public var facetInfo: FacetInfo {
            switch self {
            case .welcome:
                return FacetInfo(title: Text("Welcome", bundle: .module, comment: "welcome facet title"), symbol: "house", tint: nil)
            case .stations:
                return FacetInfo(title: Text("Stations", bundle: .module, comment: "stations facet title"), symbol: "music.note.house", tint: nil)
            case .settings:
                return FacetInfo(title: Text("Settings", bundle: .module, comment: "settings facet title"), symbol: "gearshape", tint: nil)
            }
        }

        @ViewBuilder public var body: some View {
            switch self {
            case .welcome: WelcomeView()
            case .stations: ContentView()
            case .settings: SettingsView()
            }
        }
    }

    /// A ``Facets`` that describes the app's configuration settings.
    public enum ConfigFacets : String, Facet, CaseIterable, View {
        case preferences

        public var facetInfo: FacetInfo {
            switch self {
            case .preferences:
                return FacetInfo(title: Text("Preferences", bundle: .module, comment: "preferences title"), symbol: "gearshape", tint: nil)
            }
        }

        @ViewBuilder public var body: some View {
            switch self {
            case .preferences: PreferencesView()
            }
        }
    }
}

extension Store {
    public var bundle: Bundle { Bundle.module }
}

extension Store {

    func setDockMenu() {
        #if os(macOS)
        let clockView = ClockView()
        NSApp.dockTile.contentView = NSHostingView(rootView: clockView)
        NSApp.dockTile.display()
        NSApp.dockTile.badgeLabel = "ABC"
        NSApp.dockTile.showsApplicationBadge = true
        #endif
    }

    /// Creates the status and dock menus for this application on macOS
    func createStatusItems() {
        #if os(macOS)
        if self.statusItem == nil {
            let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            if let button = statusItem.button {
                button.appearsDisabled = false

                if let img = NSImage(systemSymbolName: "infinity.circle.fill", accessibilityDescription: "Tune-Out icon") {
                    if let tinted = img.withSymbolConfiguration(.init(paletteColors: [.controlAccentColor])) {
                        tinted.isTemplate = true

                        button.image = tinted
                        // button.title = wip("Tune Out") // overlaps the icon!

                        let menu = NSMenu(title: "Tune Out Menu")
                        let menuItem = NSMenuItem(title: "Menu Item", action: #selector(Store.menuItemTapped), keyEquivalent: ";")
                        menuItem.target = self
                        menu.addItem(menuItem)

                        statusItem.menu = menu
                    }
                }
            }
            self.statusItem = statusItem
        }
        #else // os(macOS)
        dbg("skipping status item on iOS")
        #endif
    }
}

