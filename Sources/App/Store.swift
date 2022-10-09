import FairApp
import WeatherTiq
import Jack

/// The global app environment containing configuration metadata and shared defaults.
///
/// The shared instance of Store is available throughout the app with:
///
/// ``@EnvironmentObject var store: Store``
public final class Store: SceneManager, ObservableObject {
    public let bundle = Bundle.module

    //public typealias AppFacets = Never
    // public typealias AppFacets = WeatherFacets

    /// The app-wide settings view consists of the weather-specific settings along with some standard utilities
    public typealias ConfigFacets = WeatherSetting.WithStandardSettings

    /// The configuration metadata for the app from the `App.yml` file.
    public static let config: JSum = configuration(for: .module)

    /// Mutable persistent global state for the app using ``SwiftUI/AppStorage``.
    @AppStorage("fahrenheit") public var fahrenheit = true

    /// The minimum population before a city will show up
    @AppStorage("populationMinimum") var populationMinimum = 666_666.0

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


