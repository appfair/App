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
        ScrollView {
            Section {
                CurrentWeatherView(coords: $coords)
                    .font(.callout)
                    .frame(minHeight: 100)
                    .padding()
                WeatherAnalysisView()
                    .font(.headline)
                    .frame(minHeight: 100)
                    .padding()
                Divider()
                WeatherFormView(coords: $coords)
                    .padding()

                // TODO: show Fahrenheit/Celsius units
                //Toggle("Fahrenheit Units", isOn: store.$fahrenheit)

            } header: {
                Text(Bundle.main.bundleName!)
                    .font(.body)
            }
        }
    }
}

struct WeatherAnalysisView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        GroupBox("Weather Analysis:") {
            Text(store.msg)
                .textSelection(.enabled)
                .padding()
                .task {
                    store.setWelcomeMessage()
                }
                .frame(maxWidth: .infinity)
        }
    }
}

struct CurrentWeatherView : View {
    @Binding var coords: Coords

    public var body: some View {
        GroupBox("Current Weather") {
            WeatherView(coords: coords)
                .textSelection(.enabled)
        }
    }
}

struct WeatherFormView : View {
    @Binding var coords: Coords

    var body: some View {
        VStack { // Form doesn't render in iOS for some reason
            HStack {
                Slider(value: $coords.latitude, in: -90...90) {
                    Text("Latitude:")
                }
                TextField(value: $coords.latitude, format: .number, prompt: Text("lat")) {
                    EmptyView()
                }
                .frame(width: 100)
            }
            HStack {
                Slider(value: $coords.longitude, in: -180...180) {
                    Text("Longitude:")
                }
                TextField(value: $coords.longitude, format: .number, prompt: Text("lon")) {
                    EmptyView()
                }
                .frame(width: 100)
            }
            HStack {
                Slider(value: $coords.altitude, in: 0...8_000) {
                    Text("Altitude:")
                }
                TextField(value: $coords.altitude, format: .number, prompt: Text("alt")) {
                    EmptyView()
                }
                .frame(width: 100)
            }
        }
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

public struct WeatherView: View, Equatable {
    let coords: Coords

    public var body: some View {
        WeatherFetcherView(coords: coords)
    }
}

private struct WeatherFetcherView: View {
    let coords: Coords
    @State private var weatherResult: Result<Weather, Error>? = .none
    @EnvironmentObject var store: Store

    public var body: some View {
        VStack {
            switch self.weatherResult {
            case .none:
                Text("Loading…")
            case .failure(let error):
                if error is CancellationError { // FIXME: this is only throws from Task.checkCancellation(), not from the URLSession task being cancelled
                    // expected; happens when the user cancels the fetch
                    Rectangle().fill(Color.cyan)
                } else if (error as NSError).domain == "NSURLErrorDomain" && (error as NSError).code == URLError.cancelled.rawValue {
                    // URL cancellation throws a different error
                    Rectangle().fill(Color.gray.opacity(0.1))
                } else {
                    HStack {
                        Text("Error:")
                        Text(error.localizedDescription)
                    }
                }
            case .success(let weather):
                VStack {
//                    TextField("Temperature:", value: .constant(weather.currentWeather.temperature), format: .measurement(width: .wide), prompt: Text("updating temperature…"))
                    HStack {
                        Text("Temperature:")
                        Text(weather.currentWeather.temperature, format: .measurement(width: .wide))
                    }
                    HStack {
                        Text("Wind:")
                        Text(weather.currentWeather.wind.speed, format: .measurement(width: .narrow))
                        let dir = Text(weather.currentWeather.wind.direction, format: .measurement(width: .abbreviated))
                        Text("\(weather.currentWeather.wind.compassDirection.description) (\(dir))")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: coords, priority: .userInitiated) {
            self.weatherResult = await Result {
                try await Store.service.weather(for: .init(latitude: coords.latitude, longitude: coords.longitude, altitude: coords.altitude))
            }
        }
        .onChange(of: weatherResult?.successValue) { weather in
            store.updateWeatherMessage(weather)
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

    func setWelcomeMessage() {
        do {
            try ctx.env.eval("msg = 'Welcome to Sun Bow!'")
        } catch {
            dbg("error evaluating script:", error)
        }
    }

    func updateWeatherMessage(_ weather: Weather?) {
        do {
            guard var temp = weather?.currentWeather.temperature else {
                try ctx.env.eval("msg = '🟡'")
                return
            }

            temp.convert(to: self.fahrenheit ? .fahrenheit : .celsius)

            switch temp.value {
            case ...0:
                try ctx.env.eval("msg = 'It is very very cold!'")
            case 0...33:
                try ctx.env.eval("msg = 'It is cold.'")
            case 33...50:
                try ctx.env.eval("msg = 'It is chilly.'")
            case 51...80:
                try ctx.env.eval("msg = 'It is nice'")
            case 80...90:
                try ctx.env.eval("msg = 'It is hot'")
            case 90...100:
                try ctx.env.eval("msg = 'It is very hot'")
            case 100...:
                try ctx.env.eval("msg = 'It is very very hot!'")
            default:
                break
            }
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
