import FairApp
import FairKit
import Foundation
import WebKit

/// The global app environment containing configuration metadata and shared defaults.
///
/// The shared instance of Store is available throughout the app with:
///
/// ``@EnvironmentObject var store: Store``
open class Store: SceneManager {
    public let appName = Bundle.localizedAppName
    /// The configuration metadata for the app from the `App.yml` file.
    public static let config: JSum = configuration(for: .module)

    @AppStorage("homePage") public var homePage = "https://start.duckduckgo.com"
    @AppStorage("searchHost") public var searchHost = "duckduckgo.com"
    @AppStorage("themeStyle") public var themeStyle = ThemeStyle.system

    @Published var config: WKWebViewConfiguration = WKWebViewConfiguration()

    public required init() {
    }
}
