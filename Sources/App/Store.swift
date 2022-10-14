import FairApp

/// The global app environment containing configuration metadata and shared defaults.
///
/// The shared instance of Store is available throughout the app with:
///
/// ``@EnvironmentObject var store: Store``
open class Store: SceneManager {
    /// The module bundle for this store, used for looking up embedded resources
    public var bundle: Bundle { Bundle.module }

    /// The configuration metadata for the app from the `App.yml` file.
    public static let config: JSum = configuration(for: .module)

    /// Mutable persistent global state for the app using ``SwiftUI/AppStorage``.
    @AppStorage("currencyScore") public var currencyScore = false

    /// The high score that will be displayed.
    /// The high score that will be displayed.
    @AppStorage("highScore") public var highScore = 0

    /// The current game ID
    @Published var gameID = UUID()

    public required init() {
    }

    func resetGame() {
        self.gameID = UUID()
    }

    /// AppFacets describes the top-level app, expressed as tabs on a mobile device and outline items on desktops.
    public enum AppFacets : String, Facet, CaseIterable, View {
        case welcome
        case content
        case settings

        public var facetInfo: FacetInfo {
            switch self {
            case .welcome:
                return FacetInfo(title: Text("Welcome", bundle: .module, comment: "welcome facet title"), symbol: "house", tint: nil)
            case .content:
                return FacetInfo(title: Text("Play", bundle: .module, comment: "content facet title"), symbol: "gamecontroller", tint: nil)
            case .settings:
                return FacetInfo(title: Text("Settings", bundle: .module, comment: "settings facet title"), symbol: "gearshape", tint: nil)
            }
        }

        @ViewBuilder public var body: some View {
            switch self {
            case .welcome: WelcomeView()
            case .content: ContentView()
            case .settings: SettingsView()
            }
        }
    }

    /// A ``Facets`` that describes the app's configuration settings
    public enum ConfigFacets : String, Facet, CaseIterable, View {
        case preferences

        public var facetInfo: FacetInfo {
            switch self {
            case .preferences:
                return FacetInfo(title: Text("Preferences", bundle: .module, comment: "preferences title"), symbol: .init(rawValue: "gearshape"), tint: nil)
            }
        }

        @ViewBuilder public var body: some View {
            switch self {
            case .preferences: PreferencesView()
            }
        }
    }
}
