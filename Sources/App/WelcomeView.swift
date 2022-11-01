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

    ///
    private static var cardColors = ([.accentColor] + CodableColor.nominalColors).makeIterator()

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
        card("checkmark", color: cardColors.next(),
             title: Locale.appName(),
             subtitle: Locale.appSubtitle(),
             body: Locale.appSummary()),
        card("hammer", color: cardColors.next(),
             title: NSLocalizedString("welcome-02-banner", bundle: .module, value: "Get Started", comment: "app intro card #2 banner markdown"),
             subtitle: NSLocalizedString("welcome-02-caption", bundle: .module, value: "Start developing your app.", comment: "app intro card #2 caption markdown"),
             body: NSLocalizedString("welcome-02-content", bundle: .module, value: "My app is my best friend. It is my life. I must master it as I must master my life.", comment: "app intro card #2 content markdown")),
        card("flag", color: cardColors.next(),
             title: NSLocalizedString("welcome-03-banner", bundle: .module, value: "Internationalize", comment: "app intro card #3 banner markdown"),
             subtitle: NSLocalizedString("welcome-03-caption", bundle: .module, value: "Bring your app to the World", comment: "app intro card #3 caption markdown"),
             body: NSLocalizedString("welcome-03-content", bundle: .module, value: "App Fair apps are global, with support for multiple languages and locales.", comment: "app intro card #3 content markdown")),
    ]
    .compactMap({ $0 })

    /// Loads the localized card string for the current locale.
    private static func card(_ symbolName: String, color: CodableColor? = nil, title: String, subtitle: String, body: String) -> Card<String>? {
        func checkLocalized(_ value: String) -> String? {
            // only show cards that have a localization set in the Localized.strings file
            if value.hasPrefix("welcome-") { return nil }
            return value
        }
        guard let title = checkLocalized(title) else {
            return nil
        }

        return Card(title: title, subtitle: checkLocalized(subtitle), body: checkLocalized(body), background: [color].compacted(), flair: symbolName)
    }
}

