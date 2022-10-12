import FairApp

/// The default welcome shows a series of introductory "cards" using a ``CardBoard``.
///
/// The card markdown text is defined in the `Localizable.strings` files for each supproted language.
struct WelcomeView : View {
    @EnvironmentObject var store: Store
    @Environment(\.locale) var locale
    typealias SymbolCard = Card<String>

    var body: some View {
        CardBoard(cards: localizedCards) { symbolName in
            if let symbolName = symbolName {
                Image(systemName: symbolName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
            }
        }
            .background(.regularMaterial)
    }

    var localizedCards: [SymbolCard] {
        (1...20).compactMap(createCard)
    }

    func createCard(index: Int) -> SymbolCard? {
        switch index {
        case 1:
            return makeCard(1,
                            title: NSLocalizedString("card-01-banner", bundle: .module, value: "Welcome", comment: "app intro card #1 banner markdown"),
                            subtitle: NSLocalizedString("card-01-caption", bundle: .module, value: "This to your App Fair App!", comment: "app intro card #1 caption markdown"),
                            body: NSLocalizedString("card-01-content", bundle: .module, value: "This is your app. There are many like it, but this one is yours.", comment: "app intro card #1 content markdown"),
                            graphic: NSLocalizedString("card-01-graphic", bundle: .module, value: "checkmark.seal", comment: "app intro card #1 graphic symbol name"))
        case 2:
            return makeCard(2,
                            title: NSLocalizedString("card-02-banner", bundle: .module, value: "Get Started", comment: "app intro card #2 banner markdown"),
                            subtitle: NSLocalizedString("card-02-caption", bundle: .module, value: "Start developing your app.", comment: "app intro card #2 caption markdown"),
                            body: NSLocalizedString("card-02-content", bundle: .module, value: "My app is my best friend. It is my life. I must master it as I must master my life.", comment: "app intro card #2 content markdown"),
                            graphic: NSLocalizedString("card-02-graphic", bundle: .module, value: "camera.macro", comment: "app intro card #2 graphic symbol name"))
        case 3:
            return makeCard(3,
                            title: NSLocalizedString("card-03-banner", bundle: .module, value: "Internationalize", comment: "app intro card #3 banner markdown"),
                            subtitle: NSLocalizedString("card-03-caption", bundle: .module, value: "App Fair Apps are International", comment: "app intro card #3 caption markdown"),
                            body: NSLocalizedString("card-03-content", bundle: .module, value: "Describe how to use the app by editing the localized `.strings` file and updating the `card-03-content` key.", comment: "app intro card #3 content markdown"),
                            graphic: NSLocalizedString("card-03-graphic", bundle: .module, value: "globe.europe.africa", comment: "app intro card #3 graphic symbol name"))
        case 4:
            return makeCard(4,
                            title: NSLocalizedString("card-04-banner", bundle: .module, value: "Enjoy", comment: "app intro card #4 banner markdown"),
                            subtitle: NSLocalizedString("card-04-caption", bundle: .module, value: "Have fun making your app!", comment: "app intro card #4 caption markdown"),
                            body: NSLocalizedString("card-04-content", bundle: .module, value: "Make something wonderful for yourself, your community, and your world.", comment: "app intro card #4 content markdown"),
                            graphic: NSLocalizedString("card-04-graphic", bundle: .module, value: "figure.wave", comment: "app intro card #4 graphic symbol name"))
        // more cards can be added here
        default:
            return nil
        }

        func makeCard(_ index: Int, title: String, subtitle: String, body: String, graphic: String) -> SymbolCard? {
            func checkLocalized(_ value: String) -> String? {
                // only show cards that have a localization set
                if value.hasPrefix("card-") { return nil }
                return value
            }
            guard let title = checkLocalized(title) else {
                return nil
            }

            let colors: [SymbolCard.BannerColor.SystemColor] = [
                .accent, .orange, .teal, .brown, .cyan, .blue, .green, .red, .indigo, .purple, .mint, .yellow, .pink
            ]
            let color = colors[((index - 1) % colors.count)]
            return Card(title: title, subtitle: checkLocalized(subtitle), body: checkLocalized(body), backgroundColors: [.init(color)], graphic: .init(stringLiteral: graphic))
        }
    }
}

