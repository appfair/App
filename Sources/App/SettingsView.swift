import FairApp

/// The settings view for app, which includes the preferences along with standed settings.
public struct SettingsView : View {
    typealias StoreSettings = Store.ConfigFacets.WithStandardSettings
    @State var selectedSetting: StoreSettings?

    public var body: some View {
        FacetBrowserView<Store, StoreSettings>(selection: $selectedSetting)
        #if os(macOS)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(width: 600, height: 300)
        #endif
    }
}

/// The app preferences.
public struct PreferencesView : View {
    @EnvironmentObject var store: Store
    @Environment(\.locale) var locale

    public var body: some View {
        Form {
            Toggle(isOn: $store.currencyScore) {
                Text("Currency Score", bundle: .module, comment: "preferences for displaying the score as currency in the settings view")
            }
            Spacer()

            Button {
                store.resetGame()
            } label: {
                HStack {
                    Text("Reset Game", bundle: .module, comment: "reset game button title")
                }
            }

            Button {
                store.highScore = 0 // will also trigger a game reset
            } label: {
                HStack {
                    Text("Reset High Score", bundle: .module, comment: "reset high score button title")
                    Spacer()
                    Text(score: .init(store.highScore), locale: store.currencyScore ? locale : nil)
                        .font(.body.monospacedDigit())
                }
            }

        }
    }
}
