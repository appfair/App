import FairApp

/// The settings view for app, which includes the preferences along with standard settings.
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

/// A form that presents controls for manipualting the app's preferences.
public struct PreferencesView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Form {
            Toggle(isOn: store.$togglePreference) {
                Text("Boolean Preference", bundle: .module, comment: "togglePreference preference title")
            }
            Section {
                Slider(value: store.$numberPreference, in: 0...100, onEditingChanged: { _ in })
            } header: {
                HStack {
                    Text("Numeric Preference", bundle: .module, comment: "numberPreference preference title")
                    Spacer()
                    Text(round(store.numberPreference), format: .number)
                        .font(.body.monospacedDigit())
                }
            }
        }
    }
}
