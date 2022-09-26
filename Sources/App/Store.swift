import FairApp
import WeatherTiq
import Jack

/// The global app environment containing configuration metadata and shared defaults.
///
/// The shared instance of Store is available throughout the app with:
///
/// ``@EnvironmentObject var store: Store``
public final class Store: SceneManager, ObservableObject {
    /// The configuration metadata for the app from the `App.yml` file.
    public static let config: JSum = configuration(for: .module)

    /// Mutable persistent global state for the app using ``SwiftUI/AppStorage``.
    @AppStorage("fahrenheit") public var fahrenheit = true

    @AppStorage("themeStyle") var themeStyle = ThemeStyle.system

    public let appName = Bundle.localizedAppName


    public required init() {
    }

    static var defaultCoords: Coords = {
        let defloc = Store.config["weather"]?["default_location"] ?? [:]
        let lat = defloc["latitude"]?.num
        let lon = defloc["longitude"]?.num
        let alt = defloc["altitude"]?.num
        return wip(Coords(latitude: lat ?? 42.35843, longitude: lon ?? -71.05977, altitude: alt ?? 0))
    }()

}

@MainActor open class SunBowPod : JackedObject {
    public static let shared = SunBowPod()

    public static let service = WeatherService(serviceURL: defaultWeatherServer)

    static var defaultWeatherServer: URL = {
        Store.config["weather"]?["server"]?.str.flatMap(URL.init(string:)) ?? WeatherService.shared.serviceURL
    }()


    // The shared script context for executing adjuncts
    public static let ctx = JXKit.JXContext()

    @Jacked(queue: .main) var msg = ""

    /// The script context to use for this app
    lazy var ctx = jack()

    private init() {
    }

    func updateWeatherMessage(_ weather: Weather?) async {
        do {
            guard var temp = weather?.currentWeather.temperature else {
                try ctx.env.eval("msg = '🫥 `analyzing…`'")
                return
            }

            temp.convert(to: .fahrenheit)

            try ctx.env.global.setProperty("temperature", ctx.env.number(temp.value))

            try ctx.env.eval("""
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
        } catch {
            dbg("error evaluating script:", error)
        }
    }

}
