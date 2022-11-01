import FairApp

/// The settings view for app, which includes the preferences along with standed settings.
public struct SettingsView : View {
    @SceneStorage("selectedSetting") private var selectedSetting = OptionalStringStorage<Store.ConfigFacets>(value: nil)
    private let fixedSetting: Store.ConfigFacets?

    init(fixedSetting: Store.ConfigFacets? = nil) {
        self.fixedSetting = fixedSetting
    }

    public var body: some View {
        FacetBrowserView<Store, Store.ConfigFacets>(nested: true, selection: fixedSetting != nil ? .constant(fixedSetting) : $selectedSetting.value)
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
            Section {
                Toggle(isOn: $store.currencyScore) {
                    Text("Currency Score", bundle: .module, comment: "preferences for displaying the score as currency in the settings view")
                }
            } footer: {
                Text("Currency score represents points as local currency units.", bundle: .module, comment: "footer text describing currency score mode")
            }

            GroupBox {
                Button {
                    store.resetGame()
                } label: {
                    HStack {
                        Spacer()
                        Text("Reset Game", bundle: .module, comment: "reset game button title")
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)

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
                .buttonStyle(.bordered)
                .disabled(store.highScore <= 0)
            } label: {
                Text("Manage Game", bundle: .module, comment: "preferences group setting for reset game buttons")
            }
        }



    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(fixedSetting: Store.ConfigFacets.allCases.first)
            .environmentObject(Store())
    }
}
