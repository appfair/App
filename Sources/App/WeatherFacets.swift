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
        //.navigationTitle(Text("🌞 Sun Bow 🎁", bundle: .module, comment: "app name"))
        .refreshable {
            do {
                store.updateWeatherMessage(try await Store.service.weather(for: .init(latitude: coords.latitude, longitude: coords.longitude, altitude: coords.altitude ?? 0)))
            } catch {
                print(wip("### error:"), error)
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
                Slider(value: $coords.altitude[default: 0.0].pvalue, in: 0...8_000) {
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
    var altitude: Double?
    
    public init(latitude: Double, longitude: Double, altitude: Double? = nil) {
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
            try await Store.service.weather(for: .init(latitude: coords.latitude, longitude: coords.longitude, altitude: coords.altitude ?? .nan))
        }
    }
}


struct Place : Identifiable {
    var id = UUID()
    var name: String
    var coordinates: Coords
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

