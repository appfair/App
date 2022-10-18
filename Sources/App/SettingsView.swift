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
    @AppStorage("searchCount") var searchCount: Int = 250

    public var body: some View {
        Form {
            Toggle(isOn: $store.autoplayStation) {
                Text("Auto-play stations when selected", bundle: .module, comment: "preferences toggle for auto-playing stations")
            }
            .help(Text("Whether to automatically start playing selected stations.", bundle: .module, comment: "help text for preferences toggle for auto-playing stations"))
        }
    }
}

