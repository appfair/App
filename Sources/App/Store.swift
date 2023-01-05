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
    public static let config: JSum = try! configuration(name: "App", for: .module)

    /// Whether development-specific features should be enabled
    @AppStorage("developmentMode") public var developmentMode = false

    /// Whether to enable strict script evaluation.
    @AppStorage("strictMode") public var strictMode = false

    /// App-wide preference using ``SwiftUI/AppStorage``.
    @AppStorage("numberPreference") public var numberPreference = 0.0

    @Published var errors: [Error] = []

    public required init() {
    }

    /// AppFacets describes the top-level app, expressed as tabs on a mobile device and outline items on desktops.
    public enum AppFacets : String, FacetView, CaseIterable {
        /// The initial facet, which typically shows a welcome / onboarding experience
        case welcome
        /// The main content of the app.
        case content
        /// The setting for the app, which contains app-specific preferences as well as other standard settings
        case settings

        public var facetInfo: FacetInfo {
            switch self {
            case .welcome:
                return FacetInfo(title: Text("Welcome", bundle: .module, comment: "tab title for top-level “Welcome” facet"), symbol: "house", tint: nil)
            case .content:
                return FacetInfo(title: Text("Showcase", bundle: .module, comment: "tab title for top-level “Showcase” facet"), symbol: "loupe", tint: nil)
            case .settings:
                return FacetInfo(title: Text("Settings", bundle: .module, comment: "tab title for top-level “Settings” facet"), symbol: "gearshape", tint: nil)
            }
        }

        @ViewBuilder public func facetView(for store: Store) -> some View {
            switch self {
            case .welcome: WelcomeView()
            case .content: ContentView()
            case .settings: SettingsView()
            }
        }
    }

    /// A ``Facets`` that describes the app's configuration settings.
    ///
    /// Adding `WithStandardSettings` to the type will add standard configuration facets like "Appearance", "Language", and "Support"
    public typealias ConfigFacets = StoreSettings.WithStandardSettings<Store>

    /// A ``Facets`` that describes the app's preferences sections.
    public enum StoreSettings : String, FacetView, CaseIterable {
        /// The main preferences for the app
        case preferences

        public var facetInfo: FacetInfo {
            switch self {
            case .preferences:
                return FacetInfo(title: Text("Preferences", bundle: .module, comment: "preferences title"), symbol: "gearshape", tint: nil)
            }
        }

        @ViewBuilder public func facetView(for store: Store) -> some View {
            switch self {
            case .preferences: PreferencesView()
            }
        }
    }

    /// Register that an error occurred with the app manager
    @MainActor open func reportError(_ error: Error) {
        dbg("error:", error)
        errors.append(error as NSError)
    }

    /// Attempts to perform the given action and adds any errors to the error list if they fail.
    @discardableResult func trying<T>(block: () throws -> (T)) -> T? {
        do {
            return try block()
        } catch {
            reportError(error)
            return nil
        }
    }

    /// Attempts to perform the given action and adds any errors to the error list if they fail.
    open func trying<T>(block: () async throws -> (T)) async -> T? {
        do {
            return try await block()
        } catch {
            reportError(error)
            return nil
        }
    }
}
