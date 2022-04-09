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
    @AppStorage("themeStyle") public var themeStyle = ThemeStyle.system

    @Published var config: WKWebViewConfiguration = WKWebViewConfiguration()
}

extension FocusedValues {
    var browserState: BrowserState? {
        get { self[BrowserStateKey.self] }
        set { self[BrowserStateKey.self] = newValue }
    }

    struct BrowserStateKey: FocusedValueKey {
        typealias Value = BrowserState
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
    @FocusedValue(\.browserState) var state

    var body: some Commands {
        searchBarCommands

        SidebarCommands()
        ToolbarCommands()

        CommandGroup(after: .sidebar) {
            BrowserState.readerViewCommand(state, brief: false)
                .keyboardShortcut("r", modifiers: [.command, .shift])
            Divider()
            BrowserState.stopCommand(state, brief: false)
                .keyboardShortcut(".", modifiers: [.command])
            BrowserState.reloadCommand(state, brief: false)
                .keyboardShortcut("r", modifiers: [.command])
            Divider()

            BrowserState.zoomCommand(state, brief: false, amount: nil)
                .keyboardShortcut("0", modifiers: [.command])
            BrowserState.zoomCommand(state, brief: false, amount: 1.2)
                .keyboardShortcut("+", modifiers: [.command])
            BrowserState.zoomCommand(state, brief: false, amount: 0.8)
                .keyboardShortcut("-", modifiers: [.command])

            Divider()
        }

        #if os(macOS)
        CommandGroup(after: .newItem) {
            Text("New Tab", bundle: .module, comment: "label for new tab menu command")
                .button {
                    guard let win = NSApp.keyWindow ?? NSApp.mainWindow,
                          let winc = win.windowController else {
                        return
                    }
                    winc.newWindowForTab(nil)
                    guard let newWindow = NSApp.keyWindow, win != newWindow else {
                        return
                    }
                    win.addTabbedWindow(newWindow, ordered: .above)
                }
                .keyboardShortcut("t")

            Text("Open Location", bundle: .module, comment: "label for open location menu command")
                .button {
                    guard let win = NSApp.keyWindow ?? NSApp.mainWindow,
                        let content = win.contentView else {
                        return
                    }
                    // the toolbar view will be a child of the content view's parent that is not the content view itself
                    let toolbarView = content.superview?.subviews.filter({ $0 != content }) ?? []

                    // we can't really
                    for field in toolbarView
                        .flatMap(\.subviewsDepthFirst)
                        .compactMap({ $0 as? NSTextField }) {
                        if field.isEditable && field.placeholderString != nil {
                            // probaby the URLTextField
                            if win.makeFirstResponder(field) {
                                break
                            }
                        }
                    }
                }
                .keyboardShortcut("l")
        }
        #endif
    }

    var searchBarCommands: some Commands {
        CommandGroup(after: CommandGroupPlacement.textEditing) {
            Menu {
                #if os(macOS)
                Text("Find…", bundle: .module, comment: "find command text").button {
                    state?.finder.performAction(.showFindInterface)
                }
                .keyboardShortcut("F")
                Text("Find Next", bundle: .module, comment: "find next command text").button {
                    state?.finder.performAction(.nextMatch)
                }
                .keyboardShortcut("G", modifiers: [.command])
                Text("Find Previous", bundle: .module, comment: "find previous command text").button {
                    state?.finder.performAction(.previousMatch)
                }
                .keyboardShortcut("G", modifiers: [.command, .shift])
                Divider()
                Text("Hide Find Banner", bundle: .module, comment: "hide find banner command text").button {
                    // state?.finder.performAction(.hideFindInterface) // doesn't work
                    // state?.finder.cancelFindIndicator() // also doesn't work
                }
                .keyboardShortcut("F", modifiers: [.command, .shift])
                #endif
            } label: {
                Text("Find", bundle: .module, comment: "menu title for find menu")
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
                    Text("General", bundle: .module, comment: "general preferences tab title")
                        .label(image: FairSymbol.switch_2)
                        .symbolVariant(.fill)
                }
                .tag(Tabs.general)
            AdvancedSettingsView()
                .padding(20)
                .tabItem {
                    Text("Advanced", bundle: .module, comment: "advanced preferences tab title")
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

    var body: some View {
        Form {
            TextField(text: $store.homePage) {
                Text("Home Page", bundle: .module, comment: "label for general preference text field for the home page")
            }

            ThemeStylePicker(style: store.$themeStyle)
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
        case .system: return Text("System", bundle: .module, comment: "theme style preference radio label for using the system theme")
        case .light: return Text("Light", bundle: .module, comment: "theme style preference radio label for using the light theme")
        case .dark: return Text("Dark", bundle: .module, comment: "theme style preference radio label for using the dark theme")
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
            Text("Theme:", bundle: .module, comment: "label for general preferences picker for choosing the theme style")
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

extension View {
    /// Alert if the list of errors in not blank
    func alertingError<L: LocalizedError>(_ errorBinding: Binding<[L]>) -> some View {
        alert(isPresented: Binding { !errorBinding.wrappedValue.isEmpty } set: { if $0 == false { errorBinding.wrappedValue.removeLast() } }, error: errorBinding.wrappedValue.last, actions: { _ in
            // TODO: extra actions, like “Report”?
        }, message: { _ in
            // TODO: extra message?
        })

    }
}

/// Is this wise?
extension NSError : LocalizedError {
    public var errorDescription: String? { self.localizedDescription }
    public var failureReason: String? { self.localizedFailureReason }
    public var recoverySuggestion: String? { self.localizedRecoverySuggestion }
}

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
@available(*, deprecated, message: "use localized bundle/comment initializer instead")
@usableFromInline internal func Text(_ string: LocalizedStringKey, comment: StaticString? = nil) -> SwiftUI.Text {
    SwiftUI.Text(string, bundle: .module, comment: comment)
}
