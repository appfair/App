import FairApp


/// The settings view for app.
public struct SettingsView : View {
    @State var selectedSetting: Store.ConfigFacets?

    public var body: some View {
        FacetBrowserView<Store, Store.ConfigFacets>(selection: $selectedSetting)
        #if os(macOS)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(width: 600, height: 300)
        #endif
    }
}

public enum WeatherSetting : String, Facet, CaseIterable, View {
    case about // initial setting nav menu on iOS, about window on macOS: author, entitlements
    case preferences // app-specific settings

    public var facetInfo: FacetInfo {
        switch self {
        case .about:
            return info(title: Text("About", bundle: .module, comment: "about settings facet title"), symbol: .face_smiling, tint: .mint)
        case .preferences:
            return info(title: Text("Preferences", bundle: .module, comment: "preferences settings facet title"), symbol: .gear, tint: .yellow)
        }
    }

    public var body: some View {
        switch self {
        case .about: AboutSettingsView()
        case .preferences: PreferencesSettingsView()
        }
    }
}

struct AboutSettingsView : View {
    @EnvironmentObject var store: Store

    var body: some View {
        Text("About", bundle: .module, comment: "about settings title")
            .font(.largeTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PreferencesSettingsView : View {
    @EnvironmentObject var store: Store

    var body: some View {
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
