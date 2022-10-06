import FairApp
import Combine
import SQLEnclave
import WeatherTiq
import LocationTiq

public struct PlacesView : View {
    @Query(PlacesRequest(ordering: .byName)) private var places: [Place]
    @EnvironmentObject var store: Store

    public var body: some View {
        NavigationView {
            List {
                ForEach(places.filter({ .init($0.population) > store.populationMinimum })) { place in
                    PlaceListItemView(place: place)
                }
            }
        }
        #if os(iOS)
        .toolbar { EditButton() }
        #endif
        .environment(\.appDatabase, .shared)
    }
}

struct PlaceListItemView : View {
    let place: Place

    @State private var weatherResult: Result<Weather, Error>? = .none

    var body: some View {
        //TextField("Title", text: $place.title)
        NavigationLink {
            switch weatherResult {
            case .success(let weather):
                WeatherSummaryView(weather: weather.currentWeather, placeholder: Text("Loading…", bundle: .module, comment: "loading placeholder text"))
                    .navigationTitle(Text(place.name))
            case .failure(let error):
                Text("Error loading: \(place.name): \(error.localizedDescription)", bundle: .module, comment: "error message")
            case .none:
                Text("Loading: \(place.name)…", bundle: .module, comment: "loading")
            }
        } label: {
            HStack {
                Group {
                    if let weather = weatherResult?.successValue {
                        Image(systemName: weather.currentWeather.symbolName)
                            //.symbolVariant(.circle)
                            //.symbolRenderingMode(.multicolor) // clouds are white on white
                            //.symbolRenderingMode(.palette)
                            .foregroundStyle(Color.yellow, Color.cyan)
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                            .tint(.yellow) // matches the weather symbol multicolor tint
                    }
                }
                .frame(width: 25)

                VStack(alignment: .leading) {
                    HStack {
                        Text(place.name) // TODO: localized place databases
                        //Text(place.admincode3)
                        //Text(place.admincode2)
                        //Text(place.admincode1) // state in US, just a number in many other countries
                        Text(place.countrycode)
                        //Text(place.formattedAddress) // ?? Text("Unknown Location", bundle: .module, comment: "placeholder label for no address")
                    }
                    .lineLimit(1)
                    HStack {
                        Text(place.population, format: .number)
                            .font(.caption2.monospacedDigit())

                        let fmt = LocationCoordinateFormatter.degreesMinutesSecondsFormatter.string(from: place.coords.coordinate) ?? ""
                        Text(fmt)
                            .font(.caption2.monospacedDigit())
                    }
                    .font(.subheadline)
                    .lineLimit(1)
                }

                Spacer()

                switch weatherResult {
                case .success(let weather):
                    VStack(alignment: .trailing) {
                        Text(weather.currentWeather.temperature, format: .measurement(width: .narrow))
                            .font(.headline.monospacedDigit())
                            .lineLimit(1)
                        Text(weather.currentWeather.condition.localizedDescription)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                case .failure:
                    // TODO: if error is cancellation, don't show
                    EmptyView()
//                    FairSymbol.exclamationmark_octagon
//                        .help(Text("Error: \(error.localizedDescription)", bundle: .module, comment: "error tooltip prefix"))
//                        .symbolRenderingMode(.multicolor)
                case .none:
                    EmptyView()
                }
            }
        }
        .task(id: place.coords, priority: .userInitiated) {
            self.weatherResult = await Result {
                try await SunBowPod.service.weather(for: Location(latitude: place.coords.latitude, longitude: place.coords.longitude, altitude: .nan))
            }
        }
    }
}


/// Testing laziness
//public struct LazyThingView : View {
//    struct Thing : Identifiable {
//        var index: Int
//        var id: Int { dump(index, name: "id") }
//        var property: UUID { dump(UUID(), name: "property") }
//    }
//
//    struct ThingsCollection : RandomAccessCollection {
//        let startIndex = 0
//        let endIndex = 9_999
//        subscript(index: Int) -> Thing {
//            dump(Thing(index: index), name: "subscript")
//        }
//        func index(after i: Int) -> Int { i + 1 }
//    }
//
//    let things = ThingsCollection()
//
//    public var body: some View {
//        //bodyList
//        bodyLazyVStack
//    }
//
//    public var bodyLazyVStack: some View {
//        ScrollView {
//            LazyVStack {
//                ForEach(things) { thing in
//                    Text("Thing: \(thing.property)")
//                }
//            }
//        }
//    }
//
//    public var bodyList: some View {
//        List {
//            ForEach(things) { thing in
//                Text("Thing: \(thing.property)")
//            }
//        }
//    }
//
//}

