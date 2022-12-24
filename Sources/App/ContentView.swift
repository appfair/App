import FairApp

#if os(iOS)
public typealias Store = FairManager

extension FairManager {
    /// AppFacets describes the top-level app, expressed as tabs on a mobile device and outline items on desktops.
    public enum AppFacets : String, FacetView, CaseIterable {
        /// The initial facet, which typically shows a welcome / onboarding experience
        case welcome
        case projects
        case settings

        public var facetInfo: FacetInfo {
            switch self {
            case .welcome:
                return FacetInfo(title: Text("Welcome", bundle: .module, comment: "tab title for top-level “Welcome” facet"), symbol: "house", tint: nil)
            case .projects:
                return FacetInfo(title: Text("Projects", bundle: .module, comment: "content facet title"), symbol: "circle.grid.2x2", tint: nil)
            case .settings:
                return FacetInfo(title: Text("Settings", bundle: .module, comment: "tab title for top-level “Settings” facet"), symbol: "gearshape", tint: nil)
            }
        }

        @ViewBuilder public func facetView(for store: Store) -> some View {
            switch self {
            case .welcome: WelcomeView()
            case .projects: ProjectsView()
            case .settings: SettingsView()
            }
        }
    }

    /// A ``Facets`` that describes the app's configuration settings.
    ///
    /// Adding `WithStandardSettings` to the type will add standard configuration facets like "Appearance", "Language", and "Support"
    public typealias ConfigFacets = StoreSettings.WithStandardSettings<Store>

    /// A ``Facets`` that describes the app's preferences sections.
    public enum StoreSettings : String, FacetView, CaseIterable {
        /// The main preferences for the app
        case preferences

        public var facetInfo: FacetInfo {
            switch self {
            case .preferences:
                return FacetInfo(title: Text("Preferences", bundle: .module, comment: "preferences title"), symbol: .init(rawValue: "gearshape"), tint: nil)
            }
        }

        @ViewBuilder public func facetView(for store: Store) -> some View {
            switch self {
            case .preferences: PreferencesView()
            }
        }
    }
}

struct ProjectsView : View {
    var body: some View {
        Text(wip("Project List"))
    }
}

/// The settings view for app, which includes the preferences along with standed settings.
public struct SettingsView : View {
    @SceneStorage("selectedSetting") private var selectedSetting = OptionalStringStorage<Store.ConfigFacets>(value: nil)

    public var body: some View {
        FacetBrowserView<Store, Store.ConfigFacets>(nested: true, selection: $selectedSetting.value)
        #if os(macOS)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(width: 600, height: 300)
        #endif
    }
}

/// A form that presents controls for manipualting the app's preferences.
public struct PreferencesView : View {
    @EnvironmentObject var store: Store
    @Environment(\.locale) var locale

    public var body: some View {
        Form {
//            Section {
//                Toggle(isOn: $store.currencyScore) {
//                    Text("Currency Score", bundle: .module, comment: "preferences for displaying the score as currency in the settings view")
//                }
//            } footer: {
//                Text("Currency score represents points as local currency units.", bundle: .module, comment: "footer text describing currency score mode")
//            }
//
//            GroupBox {
//                Button {
//                    store.resetGame()
//                } label: {
//                    HStack {
//                        Spacer()
//                        Text("Reset Game", bundle: .module, comment: "reset game button title")
//                        Spacer()
//                    }
//                }
//                .buttonStyle(.borderedProminent)
//
//                Button {
//                    store.highScore = 0 // will also trigger a game reset
//                } label: {
//                    HStack {
//                        Text("Reset High Score", bundle: .module, comment: "reset high score button title")
//                        Spacer()
//                        Text(score: .init(store.highScore), locale: store.currencyScore ? locale : nil)
//                            .font(.body.monospacedDigit())
//                    }
//                }
//                .buttonStyle(.bordered)
//                .disabled(store.highScore <= 0)
//            } label: {
//                Text("Manage Game", bundle: .module, comment: "preferences group setting for reset game buttons")
//            }
        }

    }
}



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
        card("heart", color: cardColors.next(),
             title: NSLocalizedString("about-card-01-banner", bundle: .module, value: "Welcome", comment: "app intro card #1 banner markdown"),
             subtitle: NSLocalizedString("about-card-01-caption", bundle: .module, value: "to the App Fair Project", comment: "app intro card #1 caption markdown"),
             body: NSLocalizedString("about-card-01-content", bundle: .module, value: "The App Fair Project is a non-profit organization dedicated to creating digital public goods for a global audience.", comment: "app intro card #1 content markdown")),

        card("magnifyingglass", color: cardColors.next(),
             title: NSLocalizedString("about-card-02-banner", bundle: .module, value: wip("TODO"), comment: "app intro card #2 banner markdown"),
             subtitle: NSLocalizedString("about-card-02-caption", bundle: .module, value: "Interesting Projects", comment: "app intro card #2 caption markdown"),
             body: NSLocalizedString("about-card-02-content", bundle: .module, value: wip("TODO"), comment: "app intro card #2 content markdown")),

        card("app.gift", color: cardColors.next(),
             title: NSLocalizedString("about-card-03-banner", bundle: .module, value: wip("TODO"), comment: "app intro card #3 banner markdown"),
             subtitle: NSLocalizedString("about-card-03-caption", bundle: .module, value: "", comment: "app intro card #3 caption markdown"),
             body: NSLocalizedString("about-card-03-content", bundle: .module, value: wip("TODO"), comment: "app intro card #3 content markdown")),
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


#endif

