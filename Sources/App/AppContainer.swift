import FairApp
import WeatherTiq
import JXKit


//@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
//let service = WeatherService.weatherKit

/// The main content view for the app.
public struct ContentView: View {
    @EnvironmentObject var store: Store
    @State var coords = Store.defaultCoords

    public var body: some View {
        WeatherFormView(coords: $coords)
            .padding()
    }
}

struct WeatherFormView : View {
    @Binding var coords: Coords

    var body: some View {
        VStack {
            Text(Bundle.main.bundleName!)
                .font(.headline)
            Spacer()
            GroupBox("Current Weather") {
                WeatherView(coords: coords)
            }
            .font(.title)
            .padding()
            Spacer()

            Form {
                Section {
                    TextField("Latitude:", value: $coords.latitude, format: .number, prompt: Text("Latitude"))
                    TextField("Longitude:", value: $coords.longitude, format: .number, prompt: Text("Longitude"))
                    TextField("Altitude:", value: $coords.altitude, format: .number, prompt: Text("Altitude"))
                }

            }
            #if os(iOS)
            .keyboardType(.decimalPad)
            #endif
        }
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

    public var body: some View {
        VStack {
            switch self.weatherResult {
            case .none:
                Text("Loading…")
            case .failure(let error):
                if error is CancellationError { // FIXME: this is only throws from Task.checkCancellation(), not from the URLSession task being cancelled
                    // expected; happens when the user cancels the fetch
                    Rectangle().fill(Color.cyan)
                } else {
                    HStack {
                        Text("Error:")
                        Text(error.localizedDescription)
                    }
                }
            case .success(let weather):
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: coords, priority: .userInitiated) {
            self.weatherResult = await Result {
                try await Store.service.weather(for: .init(latitude: coords.latitude, longitude: coords.longitude, altitude: coords.altitude))
            }
        }
    }
}

/// The global app environment containing configuration metadata and shared defaults.
///
/// The shared instance of Store is available throughout the app with:
/// ``@EnvironmentObject var store: Store``
open class Store: SceneManager {
    /// The configuration metadata for the app from the `App.yml` file.
    public static let config: JSum = configuration(for: .module)

    /// Mutable persistent global state for the app using ``SwiftUI/AppStorage``.
    @AppStorage("someToggle") public var someToggle = false


    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public static let service = WeatherService(serviceURL: defaultWeatherServer)

    // The shared script context for executing adjuncts
    public static let ctx = JXKit.JXContext()

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
        Toggle(isOn: $store.someToggle) {
            Text("Toggle")
        }
        .padding()
    }
}
