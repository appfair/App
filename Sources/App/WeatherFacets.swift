import FairKit
import Jack
import WeatherTiq
import LocationTiq

struct WeatherAnalysisView : View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var pod: SunBowPod

    public var body: some View {
        Text(atx: pod.msg)
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
        WeatherResultView(coords: $coords)
    }
}


struct WeatherFormView : View {
    @Binding var coords: Coords
    
    var body: some View {
        //bodyForm // doesn't render the labels on iOS
        bodyStack
    }

    var bodyForm: some View {
        VStack { // Form doesn't render in iOS for some reason
                Slider(value: $coords.latitude, in: -90...90) {
                    Text("Latitude:", bundle: .module, comment: "latitude form field label")//.frame(width: 90, alignment: .trailing)
//                    EmptyView()
                }
//                TextField(value: $coords.latitude, format: .number, prompt: Text("lat", bundle: .module, comment: "latitude form field placeholder")) {
//                    EmptyView()
//                }
//                .frame(width: 100)
//            }
//            HStack {
                Slider(value: $coords.longitude, in: -180...180) {
                    Text("Longitude:", bundle: .module, comment: "longitude form field label")//.frame(width: 90, alignment: .trailing)
//                    EmptyView()
//                }
//                TextField(value: $coords.longitude, format: .number, prompt: Text("lon", bundle: .module, comment: "longitude form field placeholder")) {
//                    EmptyView()
//                }
//                .frame(width: 100)
            }
//            HStack {
                Slider(value: $coords.altitude[default: 0.0].pvalue, in: 0...8_000) {
                    Text("Altitude:", bundle: .module, comment: "altitude form field label")//.frame(width: 90, alignment: .trailing)
//                    EmptyView()
                }
//                TextField(value: $coords.altitude, format: .number, prompt: Text("alt", bundle: .module, comment: "altitude form fiel placeholder")) {
//                    EmptyView()
//                }
//                .frame(width: 100)
//            }
        }
        .lineLimit(1)
        .truncationMode(.tail)
        .textFieldStyle(.roundedBorder)
#if os(iOS)
        .keyboardType(.decimalPad)
#endif
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var bodyStack: some View {
        VStack { // Form doesn't render in iOS for some reason
            HStack {
                Text("Latitude:", bundle: .module, comment: "latitude form field label").frame(width: 90, alignment: .trailing)
                Slider(value: $coords.latitude, in: -90...90) {
                    EmptyView()
                }
                TextField(value: $coords.latitude, format: .number, prompt: Text("lat", bundle: .module, comment: "latitude form field placeholder")) {
//                TextField(value: $coords.latitude, format: .locationDegrees(format: .decimalDegrees, symbolStyle: .simple), prompt: Text("lat", bundle: .module, comment: "latitude form field placeholder")) {
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
//               TextField(value: $coords.longitude, format: .locationDegrees(format: .decimalDegrees, symbolStyle: .simple), prompt: Text("lon", bundle: .module, comment: "longitude form field placeholder")) {
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

    /// Conversion to `LocationTiq.Coordinate`
    public var coordinate: Coordinate {
        Coordinate(latitude: latitude, longitude: longitude)
    }
}

extension Coords : Identifiable {
    public var id: Self { self }
}

public struct WeatherResultView: View {
    @Binding var coords: Coords
    @State private var weatherResult: Result<Weather, Error>? = .none
    @EnvironmentObject var store: Store
    @EnvironmentObject var pod: SunBowPod

    public var body: some View {
        VStack(alignment: .leading) {
            switch self.weatherResult {
            case .none:
                WeatherSummaryView(weather: nil, placeholder: Text("Loading…", bundle: .module, comment: "loading placeholder text"))
            case .failure(let error):
                WeatherSummaryView(weather: nil, placeholder: error.isCancellation ? Text(verbatim: "") : Text("Error: \(error.localizedDescription)", bundle: .module, comment: "error text"))
            case .success(let weather):
                WeatherSummaryView(weather: weather.currentWeather, placeholder: Text(verbatim: ""))
            }
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: coords, priority: .userInitiated) {
            await store.trying {
                try Task.checkCancellation()
                await refreshWeather()
                try Task.checkCancellation()
                try await pod.updateHotTake(weatherResult?.successValue)
            }
        }
    }
    
    func refreshWeather() async {
        self.weatherResult = await Result {
            try await SunBowPod.service.weather(for: .init(latitude: coords.latitude, longitude: coords.longitude, altitude: coords.altitude ?? .nan))
        }
    }
}

struct WeatherSummaryView : View, Equatable {
    let weather: CurrentWeather?
    let placeholder: Text

    var body: some View {
        VStack {
            HStack {
                Text("Temp:", bundle: .module, comment: "temperature form label")
                    .frame(width: 80)
                    .frame(alignment: .trailing)
                if let weather = weather {
                    Text(weather.temperature, format: .measurement(width: .narrow))
                        .frame(alignment: .leading)
                } else {
                    placeholder
                }
            }
            HStack {
                Text("Wind:", bundle: .module, comment: "wind form label")
                    .frame(width: 80)
                    .frame(alignment: .trailing)
                Group {
                    if let weather = weather {
                        Text(weather.wind.speed, format: .measurement(width: .narrow))
                        let dir = Text(weather.wind.direction, format: .measurement(width: .narrow))
                        dir
                        //Text("\(weather.currentWeather.wind.compassDirection.description) (\(dir))")
                    } else {
                        placeholder
                    }
                }
                .frame(alignment: .leading)
            }
        }
    }
}

extension FormatStyle where Self == FloatingPointFormatStyle<Double> {
    public static func locationDegrees(format: CoordinateFormat = .decimalDegrees, symbolStyle: SymbolStyle = .simple) -> FloatingPointFormatStyle<Double> {

        wip(fatalError())
    }
}

//extension ParseableFormatStyle where Self == Decimal.FormatStyle {
//    public static func locationDegrees(format: CoordinateFormat = .decimalDegrees, symbolStyle: SymbolStyle = .simple) -> Self {
//        wip(fatalError())
//    }
//}


extension ParseableFormatStyle {

//    let formatter = LocationDegreesFormatter()
//    formatter.format = .decimalDegrees
//    formatter.symbolStyle = .simple
//    format.displayOptions = [.suffix]
//
//   public final class LocationDegreesFormatter: Formatter {
//

}
