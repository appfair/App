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

    private static var cardColors = ([.accentColor] + CodableColor.nominalColors).makeIterator()

    static let localizedCards = [
        Card(title: "Welcome to World Fair", subtitle: "A playground for code", body: """
        World Fair enables you to experiment with JavaScript to create and manage a user interface.
        """, background: [cardColors.next()].compacted(), flair: "globe"),
//        Card(title: "TITLE", subtitle: "SUBTITLE", body: "BODY", background: [cardColors.next()].compacted(), flair: "checkmark"),
//        Card(title: "TITLE", subtitle: "SUBTITLE", body: "BODY", background: [cardColors.next()].compacted(), flair: "checkmark"),
//        Card(title: "TITLE", subtitle: "SUBTITLE", body: "BODY", background: [cardColors.next()].compacted(), flair: "checkmark"),
//        Card(title: "TITLE", subtitle: "SUBTITLE", body: "BODY", background: [cardColors.next()].compacted(), flair: "checkmark"),
//        Card(title: "TITLE", subtitle: "SUBTITLE", body: "BODY", background: [cardColors.next()].compacted(), flair: "checkmark"),
    ]
}

