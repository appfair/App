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
    public static let config: JSum = try! configuration(name: "App", for: .module)

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
    open func trying(block: () async throws -> ()) async {
        do {
            try await block()
        } catch {
            await reportError(error)
        }
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
    public enum AppFacets : String, FacetView, CaseIterable {
        /// The initial facet, which typically shows a welcome / onboarding experience
        case welcome
        /// The script preview editor
        case scriptEditor
        /// The UI Playground
        case playgroundUI
        /// The setting for the app, which contains app-specific preferences as well as other standard settings
        case settings

        public var facetInfo: FacetInfo {
            switch self {
            case .welcome:
                return FacetInfo(title: Text("Welcome", bundle: .module, comment: "tab title for top-level “Welcome” facet"), symbol: "house", tint: nil)
            case .scriptEditor:
                return FacetInfo(title: Text("Script Editor", bundle: .module, comment: "tab title for top-level “Script Editor” facet"), symbol: "squareshape.dashed.squareshape", tint: nil)
            case .playgroundUI:
                return FacetInfo(title: Text("UI Playground", bundle: .module, comment: "tab title for top-level “UI Playground” facet"), symbol: "puzzlepiece", tint: nil)
            case .settings:
                return FacetInfo(title: Text("Settings", bundle: .module, comment: "tab title for top-level “Settings” facet"), symbol: "gearshape", tint: nil)
            }
        }

        @ViewBuilder public func facetView(for store: Store) -> some View {
            switch self {
            case .welcome:
                WelcomeView()
            case .scriptEditor:
                ScriptNavigatorView()
            case .playgroundUI:
                #if canImport(JXSwiftUI)
                JXSwiftUINavView()
                #else
                JackScriptNavView()
                #endif
            case .settings:
                SettingsView()
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
}
