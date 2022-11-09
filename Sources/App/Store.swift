import FairApp
import WeatherTiq
import Jack

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

    /// Mutable persistent global state for the app using ``SwiftUI/AppStorage``.
    @AppStorage("fahrenheit") public var fahrenheit = true

    /// The minimum population before a city will show up
    @AppStorage("populationMinimum") public var populationMinimum = 666_666.0

    /// The current errors to display to the user
    @State var errors: [Error] = []

    public let appName = Bundle.localizedAppName


    public required init() {
    }

    /// Try the given non-async action and add any thrown error to the queue
    @MainActor public func trying(action: @escaping () throws -> ()) {
        do {
            try action()
        } catch {
            if !error.isCancellation { // permit cancellation errors
                dbg("error performing action:", error)
                errors.append(error)
            }
        }
    }

    /// AppFacets describes the top-level app, expressed as tabs on a mobile device and outline items on desktops.
    public enum AppFacets : String, FacetView, CaseIterable {
        /// The initial facet, which typically shows a welcome / onboarding experience
        case welcome
        case places
        case weather
        case forecast
        case settings

        public var facetInfo: FacetInfo {
            switch self {
            case .welcome:
                return info(title: Text("Welcome", bundle: .module, comment: "welcome facet title"), symbol: .house, tint: .orange)
            case .places:
                return info(title: Text("Places", bundle: .module, comment: "places facet title"), symbol: .mappin_and_ellipse, tint: .green)
            case .weather:
                return info(title: Text("Weather", bundle: .module, comment: "weather facet title"), symbol: .sun_and_horizon, tint: .yellow)
            case .forecast:
                return info(title: Text("Forecast", bundle: .module, comment: "forecast facet title"), symbol: .calendar_badge_clock, tint: .purple)
            case .settings:
                return info(title: Text("Settings", bundle: .module, comment: "settings facet title"), symbol: .gear, tint: .brown)
            }
        }

        @ViewBuilder public func facetView(for store: Store) -> some View {
            switch self {
            case .welcome: WelcomeView()
            case .places: PlacesView()
            case .weather: WeatherView()
            case .forecast: ForecastView()
            case .settings: SettingsView()
            }
        }
    }

    /// Try the given async action and add any thrown error to the queue
    @MainActor public func trying(action: @escaping () async throws -> ()) async {
        do {
            try await action()
        } catch {
            if !error.isCancellation { // permit cancellation errors
                dbg("error performing action:", error)
                errors.append(error)
            }
        }
    }

    static var defaultCoords: Coords = {
        let defloc = Store.config["weather"]?["default_location"] ?? [:]
        let lat = defloc["latitude"]?.num
        let lon = defloc["longitude"]?.num
        let alt = defloc["altitude"]?.num
        return wip(Coords(latitude: lat ?? 42.35843, longitude: lon ?? -71.05977, altitude: alt ?? 0))
    }()


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

extension Error {
    /// Returns true if this is a routing cancellation-related error that should not be handled as a normal error
    var isCancellation: Bool {
        if self is CancellationError { // thrown from Task.checkCancellation()
            return true
        }

        if (self as NSError).domain == "NSURLErrorDomain" && (self as NSError).code == URLError.cancelled.rawValue {
            return true
        }

        return false
    }
}

@MainActor open class SunBowPod : JackedObject {
    public static let shared = SunBowPod()

    public static let service = WeatherService(serviceURL: defaultWeatherServer)

    static var defaultWeatherServer: URL = {
        Store.config["weather"]?["server"]?.str.flatMap(URL.init(string:)) ?? WeatherService.shared.serviceURL
    }()

    lazy var jacked = Result { try jack() }

    @Stack(queue: .main) var msg = ""

    private init() {
    }

    func updateHotTake(_ weather: Weather?) async throws {
        let ctx = try jacked.get().context

        guard var temp = weather?.currentWeather.temperature else {
            try ctx.eval("msg = '🫥 `analyzing…`'")
            return
        }

        // temp.convert(to: store.fahrenheit ? .fahrenheit : .celsius) // TODO
        temp.convert(to: .fahrenheit)

        try ctx.global.setProperty("temperature", ctx.number(temp.value))

        try ctx.eval("""
        var temp = Math.round(temperature);
        if (temp < 0) {
            msg = `🥶 ${temp}° is **very** ***cold***!!`;
        } else if (temp < 33) {
            msg = `😶‍🌫️ ${temp}° is **cold**!`;
        } else if (temp < 50) {
            msg = `😨 ${temp}° is *chilly*.`;
        } else if (temp < 80) {
            msg = `🤗 ${temp}° is nice.`;
        } else if (temp < 90) {
            msg = `😡 ${temp}° is *warm*.`;
        } else if (temp < 100) {
            msg = `🥵 ${temp}° is **hot**!`;
        } else if (temp < 200) {
            msg = `🤯 ${temp}° is **very** ***hot***!!`;
        } else {
            msg = `It is surprising temperature (${temp}°)!`;
        }
        """)
    }

}


