import FairApp

import Foundation

/// The global app environment containing configuration metadata and shared defaults.
///
/// The shared instance of Store is available throughout the app with:
///
/// ``@EnvironmentObject var store: Store``
open class Store: SceneManager {
    /// The module bundle for this store, used for looking up embedded resources
    public let bundle: Bundle = Bundle.module

    /// The configuration metadata for the app from the `App.yml` file.
    public static let config: JSum = configuration(for: .module)

    /// Mutable persistent global state for the app using ``SwiftUI/AppStorage``.
    @AppStorage("showScore") public var showScore = true

    /// The high score that will be displayed.
    @AppStorage("highScore") public var highScore = 0

    public required init() {
    }

    /// AppFacets describes the top-level app, expressed as tabs on a mobile device and outline items on desktops.
    public enum AppFacets : String, Facet, CaseIterable, View {
        case about
        case content
        case settings

        public var facetInfo: FacetInfo {
            switch self {
            case .about:
                return FacetInfo(title: Text("Welcome", bundle: .module, comment: "welcome facet title"), symbol: .init(rawValue: "house"), tint: nil)
            case .content:
                return FacetInfo(title: Text("Play!", bundle: .module, comment: "content facet title"), symbol: .init(rawValue: "command"), tint: nil)
            case .settings:
                return FacetInfo(title: Text("Settings", bundle: .module, comment: "settings facet title"), symbol: .init(rawValue: "gearshape"), tint: nil)
            }
        }

        @ViewBuilder public var body: some View {
            switch self {
            case .about: AboutView()
            case .content: ContentView()
            case .settings: StandardSettingsView()
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
            case .preferences: SettingsView()
            }
        }
    }
}

struct AboutView : View {
    @EnvironmentObject var store: Store
    //@EnvironmentObject var facetManaer: FacetManager

    var body: some View {
        VStack {
            Text("""
            Welcome to
            **Cloud Cuckoo Land**

            Here you will find excitement and delight!

            There is a cuckoo bird hiding amongst the dots. Tap it!

            Keep it in motion to maximize your points!
            """, bundle: .module, comment: "welcome text")
            .font(.system(size: 30, weight: .ultraLight, design: .rounded))
            .multilineTextAlignment(.center)
            .padding()

//            Button {
//                store
//            } label: {
//                Text("Play!", bundle: .module, comment: "play game button")
//            }

            Text("High Score\n\(store.highScore, format: .number)", bundle: .module, comment: "welcome screen title for high score")
                .font(.largeTitle.monospacedDigit().bold())
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

/// The settings view for app, which includes the stores .
public struct StandardSettingsView : View {
    typealias StoreSettings = Store.ConfigFacets.WithStandardSettings
    @State var selectedSetting: StoreSettings?

    public var body: some View {
        FacetBrowserView<Store, StoreSettings>(selection: $selectedSetting)
        #if os(macOS)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(width: 600, height: 300)
        #endif
    }
}
