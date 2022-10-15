import FairApp
import Foundation

extension URL {
    static func jackscript(appName: String) -> URL? {
        // e.g., https://world-fair.github.io/World-Fair.JackScript/jackscripts.json
        URL(string: "https://\(appName.lowercased()).github.io/\(appName).JackScript/jackscripts.json")
    }
}

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

    /// App-wide preference using ``SwiftUI/AppStorage``.
    @AppStorage("togglePreference") public var togglePreference = false

    /// App-wide preference using ``SwiftUI/AppStorage``.
    @AppStorage("numberPreference") public var numberPreference = 0.0

    @AppStorage("catalogURL") public var catalogURL = URL.jackscript(appName: "World-Fair")?.absoluteString ?? ""

    @Published var catalog: AppCatalog?
    @Published var fileStore: AppCatalog?
    @Published var errors: [Error] = []

    public required init() {
    }

    func loadFileStore(reload: Bool = false) async {
        dbg("loading file store")

        let driveURL = FileManager.default.url(forUbiquityContainerIdentifier:
               nil)?.appendingPathComponent("Documents")
                       if driveURL != nil {
                               dbg("iCloud available")
                               let fileURL = driveURL!.appendingPathComponent("test.txt")
                               try? "Hello word".data(using: .utf8)?.write(to: fileURL)
                           } else {
                               dbg("iCloud not available")
                           }

    }

    /// Loads the online forks of the app from the app's fork list
    func loadCatalog(reload: Bool = false) async {
        do {
            guard let url = URL(string: catalogURL) else {
                return dbg("unable to parse URL:", catalogURL)
            }

            let (data, _) = try await URLSession.shared.fetch(request: URLRequest(url: url, cachePolicy: reload ? .reloadIgnoringLocalAndRemoteCacheData : .useProtocolCachePolicy))
            let catalog = try AppCatalog(json: data)
            dbg("loaded catalog with", catalog.apps.count, "apps", data.count)
            self.catalog = catalog
        } catch {
            addError(error)
        }
    }

    func addError(_ error: Error) {
        dbg("adding error:", error)
        errors.append(error)
    }

    /// AppFacets describes the top-level app, expressed as tabs on a mobile device and outline items on desktops.
    public enum AppFacets : String, Facet, CaseIterable, View {
        /// The initial facet, which typically shows a welcome / onboarding experience
        case welcome
        /// The main content of the app.
        case content
        /// The setting for the app, which contains app-specific preferences as well as other standard settings
        case settings

        public var facetInfo: FacetInfo {
            switch self {
            case .welcome:
                return FacetInfo(title: Text("Welcome", bundle: .module, comment: "welcome facet title"), symbol: "house", tint: nil)
            case .content:
                return FacetInfo(title: Text("Content", bundle: .module, comment: "content facet title"), symbol: "puzzlepiece", tint: nil)
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
