import FairApp

/// The AppFacets for this app. These will be represented by a top-level tab view in mobile apps and as outline view elements on desktop apps.
extension Store {
    /// The facets for this app, which declares the logical sections of the user interface. The initial element must be a welcome/onboarding view, and the final element must be the settings element.
    public enum AppFacets : String, Facet, CaseIterable, View {
        case welcome
        case places
        case weather
        case forecast
        case settings

        public var facetInfo: FacetInfo {
            switch self {
            case .welcome:
                return info(title: Text("Welcome", bundle: .module, comment: "welcome facet title"), symbol: .house, tint: .orange)
            case .places:
                return info(title: Text("Places", bundle: .module, comment: "places facet title"), symbol: .mappin_and_ellipse, tint: .green)
            case .weather:
                return info(title: Text("Weather", bundle: .module, comment: "weather facet title"), symbol: .sun_and_horizon, tint: .yellow)
            case .forecast:
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
}

