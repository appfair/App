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
            Toggle(isOn: $store.fahrenheit) {
                Text("Fahrenheit Units", bundle: .module, comment: "setting title for temperature units")
            }
            Section {
                Slider(value: $store.populationMinimum, in: 0...10_000_000) {
                    Text("City Population Filter", bundle: .module, comment: "setting title for population filter")
                }
                .labelsHidden() // label in header; text left in for accessibility purposes
            } header: {
                HStack {
                    Text("City Population Filter", bundle: .module, comment: "setting title for population filter")
                    Spacer()
                    Text(Int64(store.populationMinimum), format: .number)
                        .font(.caption.monospacedDigit())
                }
            }
        }
    }
}
