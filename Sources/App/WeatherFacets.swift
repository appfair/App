import FairKit
import Jack
import WeatherTiq

public struct WeatherSectionView: View {
    @EnvironmentObject var store: Store
    @State var coords = Store.defaultCoords

    public var body: some View {
        List {
            Section {
                CurrentWeatherView(coords: $coords)
                    .font(.callout)
                    .padding(.horizontal)
            } header: {
                Text("Current Weather", bundle: .module, comment: "section header for weather section")
            }

            Section {
                WeatherAnalysisView()
            } header: {
                Text("Plug-In: Hot Take", bundle: .module, comment: "plug-in title")
            }

            Section {
                WeatherFormView(coords: $coords)
            }

            // TODO: show Fahrenheit/Celsius units
            //Toggle("Fahrenheit Units", isOn: store.$fahrenheit)
        }
        .navigationTitle(Text("🌞 Sun Bow 🎁", bundle: .module, comment: "app name"))
        .refreshable {
            do {
                store.updateWeatherMessage(try await Store.service.weather(for: .init(latitude: coords.latitude, longitude: coords.longitude, altitude: coords.altitude)))
            } catch {
                print("### error:", error)
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
                Text("Latitude:", bundle: .module, comment: "latitude form field label").frame(width: 90, alignment: .trailing)
                Slider(value: $coords.latitude, in: -90...90) {
                    EmptyView()
                }
                TextField(value: $coords.latitude, format: .number, prompt: Text("lat", bundle: .module, comment: "latitude form field placeholder")) {
                    EmptyView()
                }
                .frame(width: 100)
            }
            HStack {
                Text("Longitude:", bundle: .module, comment: "longitude form field label").frame(width: 90, alignment: .trailing)
                Slider(value: $coords.longitude, in: -180...180) {
                    EmptyView()
                }
                TextField(value: $coords.longitude, format: .number, prompt: Text("lon", bundle: .module, comment: "longitude form field placeholder")) {
                    EmptyView()
                }
                .frame(width: 100)
            }
            HStack {
                Text("Altitude:", bundle: .module, comment: "altitude form field label").frame(width: 90, alignment: .trailing)
                Slider(value: $coords.altitude, in: 0...8_000) {
                    EmptyView()
                }
                TextField(value: $coords.altitude, format: .number, prompt: Text("alt", bundle: .module, comment: "altitude form fiel placeholder")) {
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
                Text("Loading…", bundle: .module, comment: "loading placeholder text")
            case .failure(let error):
                if error is CancellationError { // FIXME: this is only throws from Task.checkCancellation(), not from the URLSession task being cancelled
                    // expected; happens when the user cancels the fetch
                    Rectangle().fill(Color.cyan)
                } else if (error as NSError).domain == "NSURLErrorDomain" && (error as NSError).code == URLError.cancelled.rawValue {
                    // URL cancellation throws a different error
                    //Rectangle().fill(Color.gray.opacity(0.1))
                } else {
                    HStack {
                        Text("Error:", bundle: .module, comment: "error section title")
                        Text(error.localizedDescription)
                    }
                }
            case .success(let weather):
                HStack {
                    Text("Temp:", bundle: .module, comment: "temperature form label")
                        .frame(width: 80)
                        .frame(alignment: .trailing)
                    Text(weather.currentWeather.temperature, format: .measurement(width: .narrow))
                        .frame(alignment: .leading)
                }
                HStack {
                    Text("Wind:", bundle: .module, comment: "wind form label")
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
public final class Store: SceneManager, ObservableObject, JackedObject {
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

public enum WeatherFacets : String, Facet, View {
    case welcome
    case places
    case today
    case forecast
    case settings

    public var facetInfo: FacetInfo {
        switch self {
        case .welcome:
            return info(title: Text("Welcome", bundle: .module, comment: "welcome facet title"), symbol: .seal, tint: .gray)
        case .places:
            return info(title: Text("Places", bundle: .module, comment: "places facet title"), symbol: .pin, tint: .green)
        case .today:
            return info(title: Text("Today", bundle: .module, comment: "today facet title"), symbol: .sun_max, tint: .yellow)
        case .forecast:
            return info(title: Text("Forecast", bundle: .module, comment: "forecast facet title"), symbol: .calendar, tint: .teal)
        case .settings:
            return info(title: Text("Settings", bundle: .module, comment: "settings facet title"), symbol: .gear, tint: .brown)
        }
    }

    public var body: some View {
        switch self {
        case .welcome: WelcomeView()
        case .places: PlacesView()
        case .today: TodayView()
        case .forecast: ForecastView()
        case .settings: AppSettingsView()
        }
    }
}

public struct WelcomeView : View {
    public var body: some View {
        Text("WelcomeView")
    }
}

public struct PlacesView : View {
    public var body: some View {
        Text("PlacesView")
    }
}

public struct TodayView : View {
    public var body: some View {
        WeatherSectionView()
    }
}

public struct ForecastView : View {
    public var body: some View {
        Text("ForecastView")
    }
}

public extension Facet {

    /// Facet metadata convenience builder.
    ///
    /// - Parameters:
    ///   - title: the localized title of the facet
    ///   - symbol: the symbol to represent the facet
    ///   - tint: the tint of the facet
    /// - Returns: a tuple with the metadata needed to show the facet
    func info(title: Text, symbol: FairSymbol? = nil, tint: Color? = nil) -> FacetInfo {
        (title, symbol, tint)
    }
}

public enum WeatherSetting : String, Facet, View {
    case preferences // app-specific settings
    case appearance // text/colors
    case language // language selector
    case icon // icon variant picker: background, foreground, alternate paths, squircle corner radius
    case pods // extension manager: add, remove, browse, and configure JackPods
    case support // links to support resources: issues, discussions, source code, "fork this app", "Report this App (to the App Fair Council)"), log accessor, and software BOM
    case about // initial setting nav menu on iOS, about window on macOS: author, entitlements

    public var facetInfo: FacetInfo {
        switch self {
        case .preferences:
            return info(title: Text("Preferences", bundle: .module, comment: "preferences settings facet title"), symbol: .gear, tint: .yellow)
        case .appearance:
            return info(title: Text("Appearance", bundle: .module, comment: "appearance settings facet title"), symbol: .paintpalette, tint: .red)
        case .language:
            return info(title: Text("Language", bundle: .module, comment: "language settings facet title"), symbol: .captions_bubble, tint: .blue)
        case .icon:
            return info(title: Text("Icon", bundle: .module, comment: "icon settings facet title"), symbol: .app, tint: .orange)
        case .pods:
            return info(title: Text("Pods", bundle: .module, comment: "pods settings facet title"), symbol: .cylinder_split_1x2, tint: .teal)
        case .support:
            return info(title: Text("Support", bundle: .module, comment: "support settings facet title"), symbol: .questionmark_app, tint: .cyan)
        case .about:
            return info(title: Text("About", bundle: .module, comment: "about settings facet title"), symbol: .face_smiling, tint: .mint)
        }
    }

    public var body: some View {
        switch self {
        case .about: AboutSettingsView()
        case .preferences: PreferencesSettingsView()
        case .appearance: AppearanceSettingsView()
        case .language: LanguageSettingsView()
        case .icon: IconSettingsView()
        case .pods: PodsSettingsView()
        case .support: SupportSettingsView()
        }
    }
}

public struct AppSettingsView : View {
    @State var selectedSetting: WeatherSetting?

    public var body: some View {
        FacetBrowserView(selection: $selectedSetting)
    }
}


public struct AboutSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Text("About")
            .font(.largeTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct AppearanceSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Text("Appearance")
            .font(.largeTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct LanguageSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Text("Language")
            .font(.largeTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct IconSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Text("Icon")
            .font(.largeTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct PodsSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Text("Pods")
            .font(.largeTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct SupportSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Text("Support")
            .font(.largeTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct PreferencesSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Form {
            Toggle(isOn: $store.fahrenheit) {
                Text("Fahrenheit Units", bundle: .module, comment: "setting title for temperature units")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
