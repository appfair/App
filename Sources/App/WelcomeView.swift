import FairApp

struct WelcomeView : View {
    @EnvironmentObject var store: Store
    @Environment(\.locale) var locale

    var body: some View {
        CardBoard(cards: localizedCards)
            .background(.regularMaterial)
    }

    var localizedCards: [Card] {
        (1...20).compactMap(createCard)
    }

    func createCard(index: Int) -> Card? {
        switch index {
        case 1:
            return makeCard(1,
                            title: NSLocalizedString("card-title-1", bundle: .module, value: "Hi There", comment: "intro card #1 title"),
                            subtitle: NSLocalizedString("card-subtitle-1", bundle: .module, value: "Welcome to your App Fair App!", comment: "intro card #1 title"),
                            body: NSLocalizedString("card-body-1", bundle: .module, value: "Describe how to use the app by editing the localized `.strings` file and updating the `card-body-1` key.", comment: "intro card #1 body"),
                            symbol: .init(rawValue: "figure.wave")
            )
        case 2:
            return makeCard(2,
                            title: NSLocalizedString("card-title-2", bundle: .module, comment: "intro card #2 title"),
                            subtitle: NSLocalizedString("card-subtitle-2", bundle: .module, comment: "intro card #2 title"),
                            body: NSLocalizedString("card-body-2", bundle: .module, comment: "intro card #2 body"),
                            symbol: .init(rawValue: "camera.macro")
            )
        case 3:
            return makeCard(3,
                            title: NSLocalizedString("card-title-3", bundle: .module, comment: "intro card #3 title"),
                            subtitle: NSLocalizedString("card-subtitle-3", bundle: .module, comment: "intro card #3 title"),
                            body: NSLocalizedString("card-body-3", bundle: .module, comment: "intro card #3 body"),
                            symbol: .init(rawValue: "globe.europe.africa")
            )
        // more cards can be added here
        default:
            return nil
        }

        func makeCard(_ index: Int, title: String, subtitle: String, body: String, symbol: FairSymbol) -> Card? {
            func localized(_ value: String) -> String? {
                // only show cards that have a localization set
                if value.hasPrefix("card-") { return nil }
                return value
            }
            guard let title = localized(title) else {
                return nil
            }

            let colors: [Card.BannerColor.SystemColor] = [
                .accent, .brown, .orange, .green, .teal, .cyan, .blue, .red, .indigo, .purple, .mint, .yellow, .pink
            ]
            let color = colors[((index - 1) % colors.count)]
            return Card(title: title, subtitle: localized(subtitle), body: localized(body), backgroundColors: [.init(color)], graphic: .init(symbol))
        }
    }
}

