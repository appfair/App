import FairKit
import WeatherTiq
import Jack

/// The main content view for the app.
public struct ContentView: View {
    public var body: some View {
        FacetHostingView<WeatherFacets>()
    }
}


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
open class Store: SceneManager, ObservableObject, JackedObject {
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

public enum WeatherFacets : String, AppFacets {
    /// Tab on iOS, unselected outline view on macOS: onboarding and overview
    case welcome
    public static let welcomeTitle = Text("Welcome", bundle: .module, comment: "welcome facet title")
    public static let welcomeSymbol = FairSymbol.seal

    /// Add/remove places
    case places
    public static let placesTitle = Text("Places", bundle: .module, comment: "places facet title")
    public static let placesSymbol = FairSymbol.pin

    // Center tab
    case today
    public static let todayTitle = Text("Today", bundle: .module, comment: "today facet title")
    public static let todaySymbol = FairSymbol.sun_max

    /// Forecast view
    case forecast
    public static let forecastTitle = Text("Forecast", bundle: .module, comment: "forecast facet title")
    public static let forecastSymbol = FairSymbol.calendar

    // Tab on iOS, "Preferences" window on macOS
    case settings
    public static let settingsTitle = Text("Settings", bundle: .module, comment: "settings facet title")
    public static let settingsSymbol = FairSymbol.gear

    public var title: Text {
        switch self {
        case .welcome: return Self.welcomeTitle
        case .places: return Self.placesTitle
        case .today: return Self.todayTitle
        case .forecast: return Self.forecastTitle
        case .settings: return Self.settingsTitle
        }
    }

    public var symbol: FairSymbol {
        switch self {
        case .welcome: return Self.welcomeSymbol
        case .places: return Self.placesSymbol
        case .today: return Self.todaySymbol
        case .forecast: return Self.forecastSymbol
        case .settings: return Self.settingsSymbol
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
        Text(wip("WelcomeView"))
    }
}

public struct PlacesView : View {
    public var body: some View {
        Text(wip("PlacesView"))
    }
}

public struct TodayView : View {
    public var body: some View {
        WeatherSectionView()
    }
}

public struct ForecastView : View {
    public var body: some View {
        Text(wip("ForecastView"))
    }
}

public enum WeatherSetting : String, SettingsFacets {
    case about // initial setting nav menu on iOS, about window on macOS: author, entitlements
    public static let aboutTitle = Text("About", bundle: .module, comment: "about settings facet title")
    public static let aboutSymbol = FairSymbol.info

    case preferences // app-specific settings
    public static let preferencesTitle = Text("Preferences", bundle: .module, comment: "preferences settings facet title")
    public static let preferencesSymbol = FairSymbol.gearshape_2

    case appearance // text/colors
    public static let appearanceTitle = Text("Appearance", bundle: .module, comment: "appearance settings facet title")
    public static let appearanceSymbol = FairSymbol.paintpalette

    case language // language selector
    public static let languageTitle = Text("Language", bundle: .module, comment: "language settings facet title")
    public static let languageSymbol = FairSymbol.captions_bubble

    case icon // icon variant picker: background, foreground, alternate paths, squircle corner radius
    public static let iconTitle = Text("Icon", bundle: .module, comment: "icon settings facet title")
    public static let iconSymbol = FairSymbol.app

    case pods // extension manager: add, remove, browse, and configure JackPods
    public static let podsTitle = Text("Pods", bundle: .module, comment: "pods settings facet title")
    public static let podsSymbol = FairSymbol.cylinder_split_1x2

    case support // links to support resources: issues, discussions, source code, "fork this app", "Report this App (to the App Fair Council)"), log accessor, and software BOM
    public static let supportTitle = Text("Support", bundle: .module, comment: "support settings facet title")
    public static let supportSymbol = FairSymbol.questionmark_app



    public var title: Text {
        switch self {
        case .about: return Self.aboutTitle
        case .preferences: return Self.preferencesTitle
        case .appearance: return Self.appearanceTitle
        case .language: return Self.languageTitle
        case .icon: return Self.iconTitle
        case .pods: return Self.podsTitle
        case .support: return Self.supportTitle
        }
    }

    public var symbol: FairSymbol {
        switch self {
        case .about: return Self.aboutSymbol
        case .preferences: return Self.preferencesSymbol
        case .appearance: return Self.appearanceSymbol
        case .language: return Self.languageSymbol
        case .icon: return Self.iconSymbol
        case .pods: return Self.podsSymbol
        case .support: return Self.supportSymbol
        }
    }

    public var body: some View {
        switch self {
        case .about: AboutSettingsView()
        case .preferences: AppSettingsView()
        case .appearance: AppearanceSettingsView()
        case .language: LanguageSettingsView()
        case .icon: IconSettingsView()
        case .pods: PodsSettingsView()
        case .support: SupportSettingsView()
        }
    }
}

public struct AboutSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Text(wip("DESC"))
    }
}

public struct AppearanceSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Text(wip("DESC"))
    }
}

public struct LanguageSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Text(wip("DESC"))
    }
}

public struct IconSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Text(wip("DESC"))
    }
}

public struct PodsSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Text(wip("DESC"))
    }
}

public struct SupportSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Text(wip("DESC"))
    }
}

public struct AppSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Toggle(isOn: $store.fahrenheit) {
            Text("Fahrenheit Units", bundle: .module, comment: "setting title for temperature units")
        }
        .padding()
    }
}
