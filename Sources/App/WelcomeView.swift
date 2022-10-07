import FairApp
import Lottie

extension Lottie.Animation {
    static let dayNight = Animation.named("32532-day-night.json", bundle: .module)
    static let weatherDayClearSky = Animation.named("35627-weather-day-clear-sky.json", bundle: .module)
    static let weatherDayFewClouds = Animation.named("35630-weather-day-few-clouds.json", bundle: .module)
    static let weatherDayScatteredClouds = Animation.named("35631-weather-day-scattered-clouds.json", bundle: .module)
    static let weatherDayBrokenClouds = Animation.named("35690-weather-day-broken-clouds.json", bundle: .module)
    static let weatherDayShowerRains = Animation.named("35707-weather-day-shower-rains.json", bundle: .module)
    static let weatherDayRain = Animation.named("35724-weather-day-rain.json", bundle: .module)
    static let weatherDayThunderstorm = Animation.named("35733-weather-day-thunderstorm.json", bundle: .module)
    static let weatherDaySnow = Animation.named("35743-weather-day-snow.json", bundle: .module)
    static let weatherDayMist = Animation.named("35749-weather-day-mist.json", bundle: .module)
    static let weatherNightMist = Animation.named("35750-weather-night-mist.json", bundle: .module)
    static let weatherNightSnow = Animation.named("35752-weather-night-snow.json", bundle: .module)
    static let weatherNightThunderstorm = Animation.named("35755-weather-night-thunderstorm.json", bundle: .module)
    static let weatherNightRain = Animation.named("35772-weather-night-rain.json", bundle: .module)
    static let weatherNightShowerRains = Animation.named("35774-weather-night-shower-rains.json", bundle: .module)
    static let weatherNightBrokenClouds = Animation.named("35775-weather-night-broken-clouds.json", bundle: .module)
    static let weatherNightScatteredClouds = Animation.named("35778-weather-night-scattered-clouds.json", bundle: .module)
    static let weatherNightFewClouds = Animation.named("35779-weather-night-few-clouds.json", bundle: .module)
    static let weatherNightClearSky = Animation.named("35781-weather-night-clear-sky.json", bundle: .module)
}

public struct WelcomeView : View {
    static let introItems = [
        BannerItem(id: UUID(uuidString: "98213687-6551-4B64-B9F4-E18EA9479708")!, title: "Welcome to **Sun Bow**", subtitle: "Your **forever weather buddy**. Rain or Shine, Sun Bow has got you covered.\n(not literally, of course)", foregroundColor: .init(.white), backgroundColors: [.init(.pink), .init(.purple)], animation: .weatherDayBrokenClouds, body: """
            Welcome to **Sun Bow**. We hope you'll like it here!
            """),
        BannerItem(id: UUID(uuidString: "F5121E79-2902-4068-98D0-5063A7E317C7")!, title: "New Features", subtitle: "The weather never sleeps. Neither do we! This release packs over *twenty-eight* bug fixes and performance improvements.", foregroundColor: .init(.white), backgroundColors: [.init(.blue)], animation: .weatherNightScatteredClouds, body: """
            We are constantly making updates and improvements to Sun Bow.
            """),
        BannerItem(id: UUID(uuidString: "F0E7A835-E20F-44AA-9BF7-2947569179B3")!, title: "Global Database Updated", subtitle: "New cities, updated locations. Browse and search worldwide cities for up-to-the-minute weather data and forecasts. Over 25,000 locations added to the places database.", foregroundColor: .init(.white), backgroundColors: [.init(.brown)], animation: .weatherDaySnow, body: """
            Welcome to **Sun Bow**. We hope you'll like it here!
            """),
    ]

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .center, pinnedViews: [.sectionHeaders, .sectionFooters]) {
                ForEach(Self.introItems.enumerated().array(), id: \.element.id) { index, item in
                    AnimatedBannerItem(item: item.trailing(index % 2 == 0))
                        .padding()
                        .background(item.background)
                        .cornerRadius(24)
                        .shadow(radius: 1, x: 2, y: 2)
                        .padding()
                }
            }
            //.navigationTitle(Text("Welcome to Sun Bow", bundle: .module, comment: "header title"))
            //.navigationBarTitleDisplayMode(.large)
        }
        //.padding(.top)
        //.background(Material.thick)
        //.listStyle(.plain)
        //.listRowBackground(Color.clear)
        //.listItemTint(Color.red)
        //.listRowInsets(.init(top: 0, leading: 100, bottom: 0, trailing: 100))
        //#if os(iOS)
        //.listRowSeparator(.hidden)
        //.listSectionSeparator(.hidden)
        //#endif
        
    }
}
