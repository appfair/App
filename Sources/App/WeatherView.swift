import FairApp

public struct WeatherView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var pod: SunBowPod
    @State var coords = Store.defaultCoords

    public var body: some View {
        Form {
            Section {
                CurrentWeatherView(coords: $coords)
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
//        .refreshable {
//            do {
//                await pod.updateHotTake(try await SunBowPod.service.weather(for: .init(latitude: coords.latitude, longitude: coords.longitude, altitude: coords.altitude ?? 0)))
//            } catch {
//                print(wip("### error:"), error)
//            }
//        }
    }
}

