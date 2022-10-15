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
    public let appName = Bundle.localizedAppName

    /// The configuration metadata for the app from the `App.yml` file.
    public static let config: JSum = configuration(for: .module)


    /// Mutable persistent global state for the app using ``SwiftUI/AppStorage``.
    @AppStorage("someToggle") public var someToggle = false

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
}
