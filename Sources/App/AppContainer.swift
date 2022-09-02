import FairApp
import WeatherTiq


//@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
//let service = WeatherService.weatherKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
let service = WeatherService.shared

/// The main content view for the app.
public struct ContentView: View {
    @EnvironmentObject var store: Store
    @State var coords = Coords(latitude: 42.35843, longitude: -71.05977, altitude: 0) // Boston

    public var body: some View {
        VStack {
            Text(Bundle.main.bundleName!)
                .font(.headline)
            Spacer()
            Form {
                Section {
                    TextField("Latitude:", value: $coords.latitude, format: .number, prompt: Text("Latitude"))
                    TextField("Longitude:", value: $coords.longitude, format: .number, prompt: Text("Longitude"))
                    TextField("Altitude:", value: $coords.altitude, format: .number, prompt: Text("Altitude"))
                } header: {
                    WeatherView(coords: coords)
                        .font(.title)
                }

            }
            .keyboardType(.decimalPad)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct Coords : Hashable, Identifiable {
    var latitude: Double
    var longitude: Double
    var altitude: Double

    var id: Self { self }
}

public struct WeatherView: View {
    let coords: Coords
    @State private var weather: Weather? = nil
    @State private var error: Error? = nil

    public var body: some View {
        VStack {
            if let error = error {
                HStack {
                    Text("Error:")
                    Text(error.localizedDescription)
                }
            } else if let weather = weather {
                HStack {
                    Text("Temperature:")
                    Text(weather.currentWeather.temperature.description)
                }
                HStack {
                    Text("Wind:")
                    Text(weather.currentWeather.wind.speed.description)
                    Text(weather.currentWeather.wind.compassDirection.description)
                }

            } else {
                Text("Loading…")
            }
        }
        .task(id: coords, priority: .userInitiated) {
            await fetchWeather(for: coords)
        }
    }

    private func fetchWeather(for coords: Coords) async {
        self.weather = nil
        self.error = nil

        do {
            self.weather = try await service.weather(for: .init(latitude: coords.latitude, longitude: coords.longitude, altitude: coords.altitude))
            dbg("fetched weather:", weather)
        } catch {
            dbg("error fetching weather:", error)
            self.error = error
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

    public required init() {
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
        Toggle(isOn: $store.someToggle) {
            Text("Toggle")
        }
        .padding()
    }
}
