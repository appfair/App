import FairApp

/// A welcome view that cycles through a grid of introductory "cards" using a ``CardBoard``.
///
/// You should update the contents of the cards to describe the purpose and usage of your app.
///
/// The card markdown fields are defined in the `Localizable.strings` files for each supported language,
/// and links are provided to these files from within the app to facilitate the contribution of translations.
struct WelcomeView : View {
    @EnvironmentObject var store: Store
    @Environment(\.locale) var locale
    @State var selectedCard: Card.ID?

    var body: some View {
        // a flexible board of welcome cards, providing the introduction and onboarding experience for the app
        CardBoard(selection: $selectedCard, selectedMode: .monochrome, unselectedMode: .hierarchical, selectedVariants: .circle, unselectedVariants: .fill.circle, cards: Self.localizedCards)
            .autocycle() // expand each card after a delay
    }

    /// Random card colors each time
    private static var cardColors = ([.accentColor] + CodableColor.systemColors.shuffled()).makeIterator()

    /// The card defintions for the welcome screen.
    ///
    /// Each card contains a system symbol name as well a title, subtitle, and body markdown.
    /// You are expected to add cards to describe the purpose and usage of your particular app.
    ///
    /// Internationalization is supported by updating the corresponding localization keys in the various
    /// `Localizable.strings` files (e.g., `Sources/App/Resources/fr.lproj/Localizable.strings`).
    /// Links are provided to the source repository for these files from within the app to facilitate the contribution of translations.
    /// These translation files must be kept up to date with your source code, which can be done manually or using `genstrings`.
    /// Alternatively, an app localization refresh can be done with `fairtool app localize` or the corresponding build plug-in.
    static let localizedCards = [
        card("heart", color: cardColors.next(),
             title: NSLocalizedString("about-card-01-banner", bundle: .module, value: "Welcome", comment: "app intro card #1 banner markdown"),
             subtitle: NSLocalizedString("about-card-01-caption", bundle: .module, value: "to Cloud Cuckoo Land", comment: "app intro card #1 caption markdown"),
             body: NSLocalizedString("about-card-01-content", bundle: .module, value: "This is a whimsical game of excitement and delight.", comment: "app intro card #1 content markdown")),
        card("magnifyingglass", color: cardColors.next(),
             title: NSLocalizedString("about-card-02-banner", bundle: .module, value: "Search", comment: "app intro card #2 banner markdown"),
             subtitle: NSLocalizedString("about-card-02-caption", bundle: .module, value: "for the Lost Cuckoo", comment: "app intro card #2 caption markdown"),
             body: NSLocalizedString("about-card-02-content", bundle: .module, value: "There is a cuckoo bird on the loose. You must find it and tap it. At first, it will be easy, but as your dots accrue, the difficulty of finding the cuckoo bird increases.", comment: "app intro card #2 content markdown")),
//        card("dollarsign.circle", color: cardColors.next(),
//             title: NSLocalizedString("about-card-03-banner", bundle: .module, value: "Extitement", comment: "app intro card #3 banner markdown"),
//             subtitle: NSLocalizedString("about-card-03-caption", bundle: .module, value: "Bring your app to the World", comment: "app intro card #3 caption markdown"),
//             body: NSLocalizedString("about-card-03-content", bundle: .module, value: "App Fair apps are global, with support for multiple languages and locales.", comment: "app intro card #3 content markdown")),
//        card("star", color: cardColors.next(),
//             title: NSLocalizedString("about-card-04-banner", bundle: .module, value: "Think Different", comment: "app intro card #4 banner markdown"),
//             subtitle: NSLocalizedString("about-card-04-caption", bundle: .module, value: "Here’s to the Crazy Ones", comment: "app intro card #4 caption markdown"),
//             body: NSLocalizedString("about-card-04-content", bundle: .module, value: "The misfits.\nThe rebels.\nThe troublemakers.\nThe round pegs in the square holes.\nThe ones who see things differently.\n\nThey’re not fond of rules.\nAnd they have no respect for the status quo.\nYou can praise them, disagree with them, quote them, disbelieve them, glorify or vilify them.\nAbout the only thing you can’t do is ignore them.\n\nBecause they change things.\nThey invent. They imagine. They heal.\nThey explore. They create. They inspire.\nThey push the human race forward.\n\nMaybe they have to be crazy.\nHow else can you stare at an empty canvas and see a work of art?\nOr sit in silence and hear a song that’s never been written?\nOr gaze at a red planet and see a laboratory on wheels?\nWe make tools for these kinds of people.\n\nWhile some see them as the crazy ones, we see genius.\nBecause the people who are crazy enough to think they can change the world, are the ones who do.", comment: "app intro card #4 content markdown")),
    ]
    .compactMap({ $0 })

    /// Loads the localized card string for the current locale.
    private static func card(_ symbolName: String, color: CodableColor? = nil, title: String, subtitle: String, body: String) -> Card<String>? {
        func checkLocalized(_ value: String) -> String? {
            // only show cards that have a localization set in the Localized.strings file
            if value.hasPrefix("about-card-") { return nil }
            return value
        }
        guard let title = checkLocalized(title) else {
            return nil
        }

        return Card(title: title, subtitle: checkLocalized(subtitle), body: checkLocalized(body), background: [color].compacted(), flair: symbolName)
    }
}

