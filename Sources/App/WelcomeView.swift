import FairKit

public struct WelcomeView : View {
    static let introItems = [
        Tile(id: UUID(uuidString: "98213687-6551-4B64-B9F4-E18EA9479708")!,
             title: NSLocalizedString("Welcome to **Sun Bow**", bundle: .module, comment: "tile title"),
             subtitle: NSLocalizedString("Your **forever weather buddy**. Rain or Shine, Sun Bow has got you covered.\n(not literally, of course)", bundle: .module, comment: "tile title"),
             foregroundColor: .init(.white),
             backgroundColors: [.init(.accent)],
             animation: .weatherDayBrokenClouds,
             body: NSLocalizedString("""
            Welcome to **Sun Bow**. We hope you'll like it here!
            """, bundle: .module, comment: "tile title")),
        Tile(id: UUID(uuidString: "F5121E79-2902-4068-98D0-5063A7E317C7")!,
             title: NSLocalizedString("New Features", bundle: .module, comment: "tile title"),
             subtitle: NSLocalizedString("The weather never sleeps. Neither do we! This release packs over *twenty-eight* bug fixes and performance improvements.", bundle: .module, comment: "tile title"),
             foregroundColor: .init(.white),
             backgroundColors: [.init(.blue)],
             animation: .weatherNightScatteredClouds,
             body: NSLocalizedString("""
            We are constantly making updates and improvements to Sun Bow.
            """, bundle: .module, comment: "tile title")),
        Tile(id: UUID(uuidString: "F0E7A835-E20F-44AA-9BF7-2947569179B3")!,
             title: NSLocalizedString("Global Database Updated", bundle: .module, comment: "tile title"),
             subtitle: NSLocalizedString("New cities, updated locations. Browse and search worldwide cities for up-to-the-minute weather data and forecasts. Over 25,000 locations added to the places database.", bundle: .module, comment: "tile title"),
             foregroundColor: .init(.white),
             backgroundColors: [.init(.brown)],
             animation: .weatherDaySnow,
             body: NSLocalizedString("""
            Welcome to **Sun Bow**. We hope you'll like it here!
            """, bundle: .module, comment: "tile title")),
    ]

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .center, pinnedViews: [.sectionHeaders, .sectionFooters]) {
                ForEach(Self.introItems.enumerated().array(), id: \.element.id) { index, item in
                    TileView(item: item.trailing(index % 2 == 0))
                        .padding()
                        .background(item.background)
                        .frame(minHeight: 400)
                        .cornerRadius(24)
                        .shadow(radius: 1, x: 2, y: 2)
                        .padding()
                }
            }
        }
    }
}

/// The animation resources included with this app
extension VectorAnimation {
    static let dayNight = VectorAnimation.named("32532-day-night.json", bundle: .module)
    static let weatherDayClearSky = VectorAnimation.named("35627-weather-day-clear-sky.json", bundle: .module)
    static let weatherDayFewClouds = VectorAnimation.named("35630-weather-day-few-clouds.json", bundle: .module)
    static let weatherDayScatteredClouds = VectorAnimation.named("35631-weather-day-scattered-clouds.json", bundle: .module)
    static let weatherDayBrokenClouds = VectorAnimation.named("35690-weather-day-broken-clouds.json", bundle: .module)
    static let weatherDayShowerRains = VectorAnimation.named("35707-weather-day-shower-rains.json", bundle: .module)
    static let weatherDayRain = VectorAnimation.named("35724-weather-day-rain.json", bundle: .module)
    static let weatherDayThunderstorm = VectorAnimation.named("35733-weather-day-thunderstorm.json", bundle: .module)
    static let weatherDaySnow = VectorAnimation.named("35743-weather-day-snow.json", bundle: .module)
    static let weatherDayMist = VectorAnimation.named("35749-weather-day-mist.json", bundle: .module)
    static let weatherNightMist = VectorAnimation.named("35750-weather-night-mist.json", bundle: .module)
    static let weatherNightSnow = VectorAnimation.named("35752-weather-night-snow.json", bundle: .module)
    static let weatherNightThunderstorm = VectorAnimation.named("35755-weather-night-thunderstorm.json", bundle: .module)
    static let weatherNightRain = VectorAnimation.named("35772-weather-night-rain.json", bundle: .module)
    static let weatherNightShowerRains = VectorAnimation.named("35774-weather-night-shower-rains.json", bundle: .module)
    static let weatherNightBrokenClouds = VectorAnimation.named("35775-weather-night-broken-clouds.json", bundle: .module)
    static let weatherNightScatteredClouds = VectorAnimation.named("35778-weather-night-scattered-clouds.json", bundle: .module)
    static let weatherNightFewClouds = VectorAnimation.named("35779-weather-night-few-clouds.json", bundle: .module)
    static let weatherNightClearSky = VectorAnimation.named("35781-weather-night-clear-sky.json", bundle: .module)
}
