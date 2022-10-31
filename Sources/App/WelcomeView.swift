import FairKit

public struct WelcomeView : View {
    @State var selection: UUID? = nil

    static let introItems: [Card<VectorAnimation>] = [
        Card(
            title: NSLocalizedString("Welcome to **Sun Bow**", bundle: .module, comment: "card title"),
            subtitle: NSLocalizedString("Your **forever weather buddy**!", bundle: .module, comment: "card title"),
            body: NSLocalizedString("""
            Welcome to **Sun Bow**. We hope you'll like it here! Rain or Shine, Sun Bow has got you covered.
            """, bundle: .module, comment: "card title"),
            foreground: .init(.white),
            background: [.init(.accent)],
            flair: try? .weatherDayBrokenClouds.get()
        ),
        Card(
            title: NSLocalizedString("New Features", bundle: .module, comment: "card title"),
            subtitle: NSLocalizedString("The weather never sleeps.\n*Neither do we*.", bundle: .module, comment: "card title"),
            body: NSLocalizedString("""
            We are constantly making updates and improvements to Sun Bow. This release packs over *twenty-eight* bug fixes and performance improvements.

            We are constantly making updates and improvements to Sun Bow. This release packs over *twenty-eight* bug fixes and performance improvements.

            We are constantly making updates and improvements to Sun Bow. This release packs over *twenty-eight* bug fixes and performance improvements.


            We are constantly making updates and improvements to Sun Bow. This release packs over *twenty-eight* bug fixes and performance improvements.

            We are constantly making updates and improvements to Sun Bow. This release packs over *twenty-eight* bug fixes and performance improvements.

            We are constantly making updates and improvements to Sun Bow. This release packs over *twenty-eight* bug fixes and performance improvements.


            We are constantly making updates and improvements to Sun Bow. This release packs over *twenty-eight* bug fixes and performance improvements.

            We are constantly making updates and improvements to Sun Bow. This release packs over *twenty-eight* bug fixes and performance improvements.

            We are constantly making updates and improvements to Sun Bow. This release packs over *twenty-eight* bug fixes and performance improvements.
            """, bundle: .module, comment: "card title"),
            foreground: .init(.white),
            background: [.init(.blue)],
            flair: try? .weatherNightScatteredClouds.get()
        ),
        Card(
            title: NSLocalizedString("Global Database Updated", bundle: .module, comment: "card title"),
            subtitle: NSLocalizedString("New cities, updated locations.", bundle: .module, comment: "card title"),
            body: NSLocalizedString("""
            Browse and search worldwide cities for up-to-the-minute weather data and forecasts. Over 25,000 locations added to the places database.
            """, bundle: .module, comment: "card title"),
            foreground: .init(.white),
            background: [.init(.brown)],
            flair: try? .weatherDaySnow.get()
        ),
    ]

    public var body: some View {
        CardBoard(selection: $selection, cards: Self.introItems) { (graphic: VectorAnimation?, selected: Bool) in
            if let graphic = graphic {
                VectorAnimationView(animation: graphic)
            }
        }
    }
}

/// The animation resources included with this app
extension VectorAnimation {
    static let dayNight = Result { try VectorAnimation.load("32532-day-night.json", bundle: .module) }
    static let weatherDayClearSky = Result { try VectorAnimation.load("35627-weather-day-clear-sky.json", bundle: .module) }
    static let weatherDayFewClouds = Result { try VectorAnimation.load("35630-weather-day-few-clouds.json", bundle: .module) }
    static let weatherDayScatteredClouds = Result { try VectorAnimation.load("35631-weather-day-scattered-clouds.json", bundle: .module) }
    static let weatherDayBrokenClouds = Result { try VectorAnimation.load("35690-weather-day-broken-clouds.json", bundle: .module) }
    static let weatherDayShowerRains = Result { try VectorAnimation.load("35707-weather-day-shower-rains.json", bundle: .module) }
    static let weatherDayRain = Result { try VectorAnimation.load("35724-weather-day-rain.json", bundle: .module) }
    static let weatherDayThunderstorm = Result { try VectorAnimation.load("35733-weather-day-thunderstorm.json", bundle: .module) }
    static let weatherDaySnow = Result { try VectorAnimation.load("35743-weather-day-snow.json", bundle: .module) }
    static let weatherDayMist = Result { try VectorAnimation.load("35749-weather-day-mist.json", bundle: .module) }
    static let weatherNightMist = Result { try VectorAnimation.load("35750-weather-night-mist.json", bundle: .module) }
    static let weatherNightSnow = Result { try VectorAnimation.load("35752-weather-night-snow.json", bundle: .module) }
    static let weatherNightThunderstorm = Result { try VectorAnimation.load("35755-weather-night-thunderstorm.json", bundle: .module) }
    static let weatherNightRain = Result { try VectorAnimation.load("35772-weather-night-rain.json", bundle: .module) }
    static let weatherNightShowerRains = Result { try VectorAnimation.load("35774-weather-night-shower-rains.json", bundle: .module) }
    static let weatherNightBrokenClouds = Result { try VectorAnimation.load("35775-weather-night-broken-clouds.json", bundle: .module) }
    static let weatherNightScatteredClouds = Result { try VectorAnimation.load("35778-weather-night-scattered-clouds.json", bundle: .module) }
    static let weatherNightFewClouds = Result { try VectorAnimation.load("35779-weather-night-few-clouds.json", bundle: .module) }
    static let weatherNightClearSky = Result { try VectorAnimation.load("35781-weather-night-clear-sky.json", bundle: .module) }
}
