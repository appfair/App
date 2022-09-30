import FairApp

/// The main content view for the app. This is the starting point for customizing you app's behavior.
public struct ContentView: View {
    @EnvironmentObject var store: Store

    public var body: some View {
        FacetHostingView<WeatherFacets>()
    }
}

public enum WeatherFacets : String, Facet, View {
    case welcome
    case places
    case weather
    case forecast
    case settings

    public var facetInfo: FacetInfo {
        switch self {
        case .welcome:
            return info(title: Text("Welcome", bundle: .module, comment: "welcome facet title"), symbol: .figure_wave, tint: .orange)
        case .places:
            return info(title: Text("Places", bundle: .module, comment: "places facet title"), symbol: .mappin_and_ellipse, tint: .green)
        case .weather:
            return info(title: Text("Weather", bundle: .module, comment: "weather facet title"), symbol: .sun_and_horizon, tint: .yellow)
        case .forecast:
            return info(title: Text("Script", bundle: .module, comment: "script facet title"), symbol: .calendar_day_timeline_right, tint: .purple)
            return info(title: Text("Forecast", bundle: .module, comment: "forecast facet title"), symbol: .calendar_day_timeline_right, tint: .purple)
        case .settings:
            return info(title: Text("Settings", bundle: .module, comment: "settings facet title"), symbol: .gear, tint: .brown)
        }
    }

    public var body: some View {
        switch self {
        case .welcome: WelcomeView()
        case .places: PlacesView()
        case .weather: WeatherView()
        case .forecast: ForecastView()
        case .settings: SettingsView()
        }
    }
}

public struct WelcomeView : View {
    let news = wip([
        "Welcome to **Sun Bow**",
        //"DEF",
        //"GHI",
    ])

    public var body: some View {
        List {
            ForEach(news, id: \.self) { item in
                Text(atx: item)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.pink.cornerRadius(30))
            }
        }
        .listStyle(.plain)
    }
}

