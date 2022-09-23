import FairApp

/// The settings view for app.
public struct SettingsView : View {
    @State var selectedSetting: WeatherSetting?

    public var body: some View {
        FacetBrowserView(selection: $selectedSetting)
    }
}

public enum WeatherSetting : String, Facet, View {
    case preferences // app-specific settings
    case appearance // text/colors
    case language // language selector
    case icon // icon variant picker: background, foreground, alternate paths, squircle corner radius
    case pods // extension manager: add, remove, browse, and configure JackPods
    case support // links to support resources: issues, discussions, source code, "fork this app", "Report this App (to the App Fair Council)"), log accessor, and software BOM
    case about // initial setting nav menu on iOS, about window on macOS: author, entitlements

    public var facetInfo: FacetInfo {
        switch self {
        case .preferences:
            return info(title: Text("Preferences", bundle: .module, comment: "preferences settings facet title"), symbol: .gear, tint: .yellow)
        case .appearance:
            return info(title: Text("Appearance", bundle: .module, comment: "appearance settings facet title"), symbol: .paintpalette, tint: .red)
        case .language:
            return info(title: Text("Language", bundle: .module, comment: "language settings facet title"), symbol: .captions_bubble, tint: .blue)
        case .icon:
            return info(title: Text("Icon", bundle: .module, comment: "icon settings facet title"), symbol: .app, tint: .orange)
        case .pods:
            return info(title: Text("Pods", bundle: .module, comment: "pods settings facet title"), symbol: .cylinder_split_1x2, tint: .teal)
        case .support:
            return info(title: Text("Support", bundle: .module, comment: "support settings facet title"), symbol: .questionmark_app, tint: .cyan)
        case .about:
            return info(title: Text("About", bundle: .module, comment: "about settings facet title"), symbol: .face_smiling, tint: .mint)
        }
    }

    public var body: some View {
        switch self {
        case .about: AboutSettingsView()
        case .preferences: PreferencesSettingsView()
        case .appearance: AppearanceSettingsView()
        case .language: LanguageSettingsView()
        case .icon: IconSettingsView()
        case .pods: PodsSettingsView()
        case .support: SupportSettingsView()
        }
    }
}

private struct AboutSettingsView : View {
    @EnvironmentObject var store: Store

    var body: some View {
        Text("About", bundle: .module, comment: "about settings title")
            .font(.largeTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct AppearanceSettingsView : View {
    @EnvironmentObject var store: Store

    var body: some View {
        Text("Appearance", bundle: .module, comment: "appearance settings title")
            .font(.largeTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct LanguageSettingsView : View {
    @EnvironmentObject var store: Store

    var body: some View {
        Text("Language", bundle: .module, comment: "language settings title")
            .font(.largeTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct IconSettingsView : View {
    @EnvironmentObject var store: Store

    var body: some View {
        Text("Icon", bundle: .module, comment: "icon settings title")
            .font(.largeTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct PodsSettingsView : View {
    @EnvironmentObject var store: Store

    var body: some View {
        Text("Pods", bundle: .module, comment: "pods settings title")
            .font(.largeTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct SupportSettingsView : View {
    @EnvironmentObject var store: Store

    var body: some View {
        Text("Support", bundle: .module, comment: "support settings title")
            .font(.largeTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct PreferencesSettingsView : View {
    @EnvironmentObject var store: Store

    var body: some View {
        Form {
            Toggle(isOn: $store.fahrenheit) {
                Text("Fahrenheit Units", bundle: .module, comment: "setting title for temperature units")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
