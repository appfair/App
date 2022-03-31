import FairApp

/// The shared app environment
@MainActor public final class Store: SceneManager {
    @AppStorage("searchHost") public var searchHost = "duckduckgo.com"
}

public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
#if os(macOS)
        WindowGroup {
            browserView(store: store)
        }
        .windowToolbarStyle(UnifiedWindowToolbarStyle(showsTitle: false))
#elseif os(iOS)
        WindowGroup {
            NavigationView {
                browserView(store: store)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
#endif
    }

    static func browserView(store: Store) -> some View {
        BrowserView()
            .environmentObject(store)
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store: Store) -> some SwiftUI.View {
        AppSettingsView().environmentObject(store)
    }
}

public struct AppSettingsView : View {
    public enum Tabs: Hashable {
        case general
        case advanced
    }

    public var body: some View {
        TabView {
            GeneralSettingsView()
                .padding(20)
                .tabItem {
                    Text("General", comment: "General preferences tab title")
                        .label(image: FairSymbol.switch_2)
                        .symbolVariant(.fill)
                }
                .tag(Tabs.general)
            AdvancedSettingsView()
                .padding(20)
                .tabItem {
                    Text("Advanced", comment: "Advanced preferences tab title")
                        .label(image: FairSymbol.gearshape)
                        .symbolVariant(.fill)
                }
                .tag(Tabs.advanced)
        }
        .padding(20)
        .frame(width: 600)
    }
}

struct GeneralSettingsView : View {
    @AppStorage("themeStyle") private var themeStyle = ThemeStyle.system

    var body: some View {
        Form {
            ThemeStylePicker(style: $themeStyle)
        }
    }
}

/// The preferred theme style for the app
public enum ThemeStyle: String, CaseIterable {
    case system
    case light
    case dark
}

extension ThemeStyle : Identifiable {
    public var id: Self { self }

    public var label: Text {
        switch self {
        case .system: return Text("System")
        case .light: return Text("Light")
        case .dark: return Text("Dark")
        }
    }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}


@available(macOS 12.0, iOS 15.0, *)
struct ThemeStylePicker: View {
    @Binding var style: ThemeStyle

    var body: some View {
        Picker(selection: $style) {
            ForEach(ThemeStyle.allCases) { themeStyle in
                themeStyle.label
            }
        } label: {
            Text("Theme:")
        }
        .radioPickerStyle()
    }
}

extension Picker {
    /// On macOS, sets the style as a radio picker style.
    /// On other platforms, has no effect.
    func radioPickerStyle() -> some View {
        #if os(macOS)
        self.pickerStyle(RadioGroupPickerStyle())
        #else
        self
        #endif
    }
}


struct AdvancedSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Form {
            TextField(text:$store.searchHost) {
                Text("Search Provider")
            }
        }
        .padding()
    }
}


// MARK: Parochial (package-local) Utilities

/// Returns the localized string for the current module.
///
/// - Note: This is boilerplate package-local code that could be copied
///  to any Swift package with localized strings.
internal func loc(_ key: String, tableName: String? = nil, comment: String? = nil) -> String {
    // TODO: use StringLocalizationKey
    NSLocalizedString(key, tableName: tableName, bundle: .module, comment: comment ?? "")
}

/// Work-in-Progress marker
@available(*, deprecated, message: "work in progress")
internal func wip<T>(_ value: T) -> T { value }

/// Intercept `LocalizedStringKey` constructor and forward it to ``SwiftUI.Text/init(_:bundle)``
/// Otherwise it will default to the main bundle's strings, which is always empty.
@usableFromInline internal func Text(_ string: LocalizedStringKey, comment: StaticString? = nil) -> SwiftUI.Text {
    SwiftUI.Text(string, bundle: .module, comment: comment)
}
