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
        case .settings: SettingsView()
        }
    }
}

public struct WelcomeView : View {
    public var body: some View {
        Text("Welcome", bundle: .module, comment: "view body text")
    }
}

