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

public struct PlacesView : View {
    @State var places: Array<Place> = [
        wip(Place(name: "Boston", coordinates: Coords(latitude: 42.35843, longitude: -71.05977)))
    ]

    public var body: some View {
        VStack {
            List {
                ForEach($places) { $place in
                    //TextField("Title", text: $place.title)
                    Text(place.name)
                }
                .onMove { indexSet, offset in
                    places.move(fromOffsets: indexSet, toOffset: offset)
                }
                .onDelete { indexSet in
                    places.remove(atOffsets: indexSet)
                }
            }
        }
        #if os(iOS)
        .toolbar { EditButton() }
        #endif
    }
}

public struct TodayView : View {
    public var body: some View {
        WeatherSectionView()
    }
}

public struct ForecastView : View {
    public var body: some View {
        Text("Forecast", bundle: .module, comment: "view body text")
    }
}

