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
        card("loupe", color: cardColors.next(),
             title: "Welcome",
             subtitle: "to Magic Loupe!",
             body: "This is a showcase of native app components written in JavaScript."),
        card("hammer", color: cardColors.next(),
             title: "Develop",
             subtitle: "Live Reload and Hot Fixes",
             body: "Server-driven user-interfaces meet native SwiftUI components. JavaScript without the WebView overhead."),
        card("rosette", color: cardColors.next(),
             title: "Deploy",
             subtitle: "Dynamic Server-driven User Interfaces",
             body: "Use you favorite git provider to host versions and control development workflows. Push development builds to beta users and control the development cycle with semantic version tagging."),
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

