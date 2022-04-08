/**
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import FairApp
import WebKit

/// The shared app environment
@MainActor public final class Store: SceneManager {
    @AppStorage("homePage") public var homePage = "https://start.duckduckgo.com"
    @AppStorage("searchHost") public var searchHost = "duckduckgo.com"

    @Published var config: WKWebViewConfiguration = WKWebViewConfiguration()
}

struct BrowserStateKey: FocusedValueKey {
    typealias Value = BrowserState
}

extension FocusedValues {
    var browserState: BrowserState? {
        get { self[BrowserStateKey.self] }
        set { self[BrowserStateKey.self] = newValue }
    }
}

public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
#if os(macOS)
        WindowGroup {
            BrowserView()
                .environmentObject(store)
        }
        .commands(content: { BrowserCommands() })
        .windowToolbarStyle(UnifiedWindowToolbarStyle(showsTitle: false))
#elseif os(iOS)
        WindowGroup {
            NavigationView {
                BrowserView()
                    .environmentObject(store)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
#endif
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store: Store) -> some SwiftUI.View {
        AppSettingsView().environmentObject(store)
    }
}

struct BrowserCommands : Commands {
    @FocusedValue(\.browserState) var browserState

    var body: some Commands {
        SidebarCommands()

        searchBarCommands

        CommandGroup(after: .sidebar) {
            Divider()

            Text("Show Reader", bundle: .module, comment: "label for reader view menu")
                .label(image: FairSymbol.eyeglasses)
                .button {
                    dbg("loading reader view for:", browserState)
                    Task {
                        await browserState?.enterReaderView()
                    }
                }
                .keyboardShortcut("R", modifiers: [.command, .shift])
                //.disabled(browserState?.canEnterReaderView != true)
        }
    }

    var searchBarCommands: some Commands {
        CommandGroup(after: CommandGroupPlacement.textEditing) {
            Section {
                #if os(macOS)
                Text("Search", bundle: .module, comment: "search command text").button {
                    dbg("activating search field")
                    // there's no official way to do this, so search the NSToolbar for the item and make it the first responder
                    if let window = NSApp.currentEvent?.window,
                       let toolbar = window.toolbar,
                       let searchField = toolbar.visibleItems?.compactMap({ $0 as? NSSearchToolbarItem }).first {
                        // <SwiftUI.AppKitSearchToolbarItem: 0x13a8721a0> identifier = "com.apple.SwiftUI.search"]
                        dbg("searchField:", searchField)
                        window.makeFirstResponder(searchField.searchField)
                    }
                }
                .keyboardShortcut("F")
                #endif
            }
        }

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
    @EnvironmentObject var store: Store
    @AppStorage("themeStyle") private var themeStyle = ThemeStyle.system

    var body: some View {
        Form {
            TextField(text: $store.homePage) {
                Text("Home Page", bundle: .module, comment: "label for general preference text field for the home page")
            }

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
            TextField(text: $store.searchHost) {
                Text("Search Provider", bundle: .module, comment: "label for advanced preference text field for the search provider")
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
