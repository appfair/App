import FairApp

/// The default welcome shows a series of introductory "cards" using a ``CardBoard``.
///
/// The card markdown text is defined in the `Localizable.strings` files for each supported language.
struct WelcomeView : View {
    @EnvironmentObject var store: Store
    @Environment(\.locale) var locale
    @State var selectedCard: Card.ID?

    var body: some View {
        // a flexible board of welcome cards, providing the introduction and onboarding experience for the app
        CardBoard(selection: $selectedCard, cards: localizedCards) { symbolName in
            // the center image for the card; this can be any SwiftUI view, such as a Lottie VectorAnimation
            Text(Image(systemName: symbolName))
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .shadow(radius: 2)
        }
        .autocycle() // expanding each card after a delay
    }

    /// The card defintions for the welcome screen.
    ///
    /// Each card contains a system symbol name as well a title, subtitle, and body markdown that should be translated in the various `Localizable.strings` files (e.g., `Sources/App/Resources/fr.lproj/Localizable.strings`).
    var localizedCards = [
        card("checkmark.seal",
             title: NSLocalizedString("about-card-01-banner", bundle: .module, value: "Welcome", comment: "app intro card #1 banner markdown"),
             subtitle: NSLocalizedString("about-card-01-caption", bundle: .module, value: "This is your app", comment: "app intro card #1 caption markdown"),
             body: NSLocalizedString("about-card-01-content", bundle: .module, value: "This is your brand new App Fair app. There are many like it, but this one is yours.\n\nAn App Fair app is a digital public good. It is free software that is built and distributed in a transparent manner and independently verified to not contain any privacy-invasive technologies or other anti-features.", comment: "app intro card #1 content markdown")),
        card("hammer.circle",
             title: NSLocalizedString("about-card-02-banner", bundle: .module, value: "Get Started", comment: "app intro card #2 banner markdown"),
             subtitle: NSLocalizedString("about-card-02-caption", bundle: .module, value: "Start developing your app.", comment: "app intro card #2 caption markdown"),
             body: NSLocalizedString("about-card-02-content", bundle: .module, value: "My app is my best friend. It is my life. I must master it as I must master my life.", comment: "app intro card #2 content markdown")),
        card("globe",
             title: NSLocalizedString("about-card-03-banner", bundle: .module, value: "Internationalize", comment: "app intro card #3 banner markdown"),
             subtitle: NSLocalizedString("about-card-03-caption", bundle: .module, value: "Bring your app to the World", comment: "app intro card #3 caption markdown"),
             body: NSLocalizedString("about-card-03-content", bundle: .module, value: "App Fair Apps are International. Describe how to use the app by editing the localized `.strings` file and updating the `about-card-03-content` key.", comment: "app intro card #3 content markdown")),
        card("peacesign",
             title: NSLocalizedString("about-card-04-banner", bundle: .module, value: "Think Different", comment: "app intro card #4 banner markdown"),
             subtitle: NSLocalizedString("about-card-04-caption", bundle: .module, value: "Here’s to the Crazy Ones", comment: "app intro card #4 caption markdown"),
             body: NSLocalizedString("about-card-04-content", bundle: .module, value: "The misfits.\nThe rebels.\nThe troublemakers.\nThe round pegs in the square holes.\nThe ones who see things differently.\n\nThey’re not fond of rules.\nAnd they have no respect for the status quo.\nYou can praise them, disagree with them, quote them, disbelieve them, glorify or vilify them.\nAbout the only thing you can’t do is ignore them.\n\nBecause they change things.\nThey invent. They imagine. They heal.\nThey explore. They create. They inspire.\nThey push the human race forward.\n\nMaybe they have to be crazy.\nHow else can you stare at an empty canvas and see a work of art?\nOr sit in silence and hear a song that’s never been written?\nOr gaze at a red planet and see a laboratory on wheels?\nWe make tools for these kinds of people.\n\nWhile some see them as the crazy ones, we see genius.\nBecause the people who are crazy enough to think they can change the world, are the ones who do.", comment: "app intro card #4 content markdown")),
    ]
    .compactMap({ $0 })


    /// Loads the localized card string for the current locale.
    private static func card(_ graphic: String, title: String, subtitle: String, body: String) -> Card<String>? {
        func checkLocalized(_ value: String) -> String? {
            // only show cards that have a localization set in the Localized.strings file
            if value.hasPrefix("about-card-") { return nil }
            return value
        }
        guard let title = checkLocalized(title) else {
            return nil
        }

        // pseudo-random background color for the card based on the graphic name
        let colors: [CodableColor.SystemColor] = [.orange, .teal, .brown, .cyan, .blue, .green, .red, .indigo, .purple, .mint, .pink]
        let color = colors[abs(title.hashValue) % colors.count]

        return Card(title: title, subtitle: checkLocalized(subtitle), body: checkLocalized(body), background: [.init(color)], flair: .init(stringLiteral: graphic))
    }
}

