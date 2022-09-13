import FairApp
import WeatherTiq
import Jack

//@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
//let service = WeatherService.weatherKit

/// The main content view for the app.
public struct ContentView: View {
    @EnvironmentObject var store: Store
    @State var coords = Store.defaultCoords

    public var body: some View {
        NavigationView {
            List {
                Section {
                    CurrentWeatherView(coords: $coords)
                        .font(.callout)
                        .padding(.horizontal)
                } header: {
                    Text("Current Weather")
                }

                Section {
                    WeatherAnalysisView()
                } header: {
                    Text("Plug-In: Hot Take")
                }

                Section {

                    WeatherFormView(coords: $coords)
                }

                // TODO: show Fahrenheit/Celsius units
                //Toggle("Fahrenheit Units", isOn: store.$fahrenheit)
            }
            .navigationTitle(Text("🌞 Sun Bow 🎁"))
            .refreshable {
                do {
                    store.updateWeatherMessage(try await Store.service.weather(for: .init(latitude: coords.latitude, longitude: coords.longitude, altitude: coords.altitude)))
                } catch {
                    print("### error:", error)
                }
            }
        }
    }
}

struct WeatherAnalysisView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Text(atx: store.msg)
            .font(.title)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(1)
            .truncationMode(.tail)
    }
}

struct CurrentWeatherView : View {
    @Binding var coords: Coords

    public var body: some View {
        WeatherView(coords: coords)
            .textSelection(.enabled)
            .frame(minHeight: 100)
    }
}

struct WeatherFormView : View {
    @Binding var coords: Coords

    var body: some View {
        VStack { // Form doesn't render in iOS for some reason
            HStack {
                Text("Latitude:").frame(width: 90, alignment: .trailing)
                Slider(value: $coords.latitude, in: -90...90) {
                    EmptyView()
                }
                TextField(value: $coords.latitude, format: .number, prompt: Text("lat")) {
                    EmptyView()
                }
                .frame(width: 100)
            }
            HStack {
                Text("Longitude:").frame(width: 90, alignment: .trailing)
                Slider(value: $coords.longitude, in: -180...180) {
                    EmptyView()
                }
                TextField(value: $coords.longitude, format: .number, prompt: Text("lon")) {
                    EmptyView()
                }
                .frame(width: 100)
            }
            HStack {
                Text("Altitude:").frame(width: 90, alignment: .trailing)
                Slider(value: $coords.altitude, in: 0...8_000) {
                    EmptyView()
                }
                TextField(value: $coords.altitude, format: .number, prompt: Text("alt")) {
                    EmptyView()
                }
                .frame(width: 100)
            }
        }
        .lineLimit(1)
        .truncationMode(.tail)
        .textFieldStyle(.roundedBorder)
        #if os(iOS)
        .keyboardType(.decimalPad)
        #endif
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct Coords : Hashable, Codable {
    var latitude: Double
    var longitude: Double
    var altitude: Double

    public init(latitude: Double, longitude: Double, altitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
    }

}

extension Coords : Identifiable {
    public var id: Self { self }
}

public struct WeatherView: View {
    let coords: Coords
    @State private var weatherResult: Result<Weather, Error>? = .none
    @EnvironmentObject var store: Store

    public var body: some View {
        VStack(alignment: .leading) {
            switch self.weatherResult {
            case .none:
                Text("Loading…")
            case .failure(let error):
                if error is CancellationError { // FIXME: this is only throws from Task.checkCancellation(), not from the URLSession task being cancelled
                    // expected; happens when the user cancels the fetch
                    Rectangle().fill(Color.cyan)
                } else if (error as NSError).domain == "NSURLErrorDomain" && (error as NSError).code == URLError.cancelled.rawValue {
                    // URL cancellation throws a different error
                    //Rectangle().fill(Color.gray.opacity(0.1))
                } else {
                    HStack {
                        Text("Error:")
                        Text(error.localizedDescription)
                    }
                }
            case .success(let weather):
                HStack {
                    Text("Temp:")
                        .frame(width: 80)
                        .frame(alignment: .trailing)
                    Text(weather.currentWeather.temperature, format: .measurement(width: .narrow))
                        .frame(alignment: .leading)
                }
                HStack {
                    Text("Wind:")
                        .frame(width: 80)
                        .frame(alignment: .trailing)
                    Group {
                        Text(weather.currentWeather.wind.speed, format: .measurement(width: .narrow))
                        let dir = Text(weather.currentWeather.wind.direction, format: .measurement(width: .narrow))
                        dir
                        //Text("\(weather.currentWeather.wind.compassDirection.description) (\(dir))")
                    }
                    .frame(alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: coords, priority: .userInitiated) {
            await refreshWeather()
        }
        .onChange(of: weatherResult?.successValue) { weather in
            store.updateWeatherMessage(weather)
        }
    }

    func refreshWeather() async {
        self.weatherResult = await Result {
            try await Store.service.weather(for: .init(latitude: coords.latitude, longitude: coords.longitude, altitude: coords.altitude))
        }
    }
}

/// The global app environment containing configuration metadata and shared defaults.
///
/// The shared instance of Store is available throughout the app with:
/// ``@EnvironmentObject var store: Store``
open class Store: SceneManager, JackedObject {
    /// The configuration metadata for the app from the `App.yml` file.
    public static let config: JSum = configuration(for: .module)

    /// Mutable persistent global state for the app using ``SwiftUI/AppStorage``.
    @AppStorage("fahrenheit") public var fahrenheit = true


    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public static let service = WeatherService(serviceURL: defaultWeatherServer)

    // The shared script context for executing adjuncts
    public static let ctx = JXKit.JXContext()

    @Jacked var msg = ""

    /// The script context to use for this app
    lazy var ctx = jack()

    public required init() {
    }

    static var defaultWeatherServer: URL = {
        Store.config["weather"]?["server"]?.str.flatMap(URL.init(string:)) ?? WeatherService.shared.serviceURL
    }()

    static var defaultCoords: Coords = {
        let defloc = Store.config["weather"]?["default_location"] ?? [:]
        let lat = defloc["latitude"]?.num
        let lon = defloc["longitude"]?.num
        let alt = defloc["altitude"]?.num
        return Coords(latitude: lat ?? 42.35843, longitude: lon ?? -71.05977, altitude: alt ?? 0)
    }()

    func updateWeatherMessage(_ weather: Weather?) {
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

public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        WindowGroup {
            ContentView().environmentObject(store)
        }
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store: Store) -> some SwiftUI.View {
        AppSettingsView().environmentObject(store)
    }
}

public struct AppSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Toggle(isOn: $store.fahrenheit) {
            Text("Fahrenheit Units")
        }
        .padding()
    }
}
