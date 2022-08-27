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
import FairKit

/// The shared app environment
@MainActor public final class Store: SceneManager {
    /// The configuration metadata for the app from the `App.yml` file.
    public static let config: JSum = configuration(for: .module)

    @AppStorage("homePage") public var homePage = "https://start.duckduckgo.com"
    @AppStorage("searchHost") public var searchHost = "duckduckgo.com"
    @AppStorage("themeStyle") public var themeStyle = ThemeStyle.system

    @Published var config: WKWebViewConfiguration = WKWebViewConfiguration()

    public init() {
    }
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
            browserView(store: store)
        }
        .commands(content: { BrowserCommands() })
        .windowToolbarStyle(UnifiedWindowToolbarStyle(showsTitle: false))
#elseif os(iOS)
        WindowGroup {
            NavigationView {
                browserView(store: store)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .commands(content: { BrowserCommands() })
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

struct BrowserCommands : Commands {
    @FocusedValue(\.browserState) var state

    var body: some Commands {
        searchBarCommands

        SidebarCommands()
        ToolbarCommands()

        CommandMenu(Text("History", bundle: .module, comment: "title for the History command menu")) {
            state?.observing { state in
                state.navigateAction(amount: -1).keyboardShortcut("[")
                state.navigateAction(amount: +1).keyboardShortcut("]")

                // TODO: "Go Home"
            }
        }

        CommandGroup(after: .sidebar) {
            state?.observing { state in
                state.readerAction().keyboardShortcut("r", modifiers: [.command, .shift])

                Divider()

                state.stopAction().keyboardShortcut(".")
                state.reloadAction().keyboardShortcut("r")

                Divider()

                state.zoomAction(amount: nil).keyboardShortcut("0")
                state.zoomAction(amount: 1.2).keyboardShortcut("+")
                state.zoomAction(amount: 0.8).keyboardShortcut("-")

                Divider()
            }
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
                    // this will probably be an array of [NSVisualEffectView, NSTitlebarContainerView]
                    let nonContentViews = content.superview?.subviews.filter({ $0 != content }) ?? []
                    // we just have to guess what the URL field is
                    for field in nonContentViews.reversed()
                        .flatMap(\.subviewsBreadthFirst)
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


extension ObservableObject {
    /// Create a view based on changes to this `ObservableObject`.
    /// Ths is typically unnecessary when the instance itself if being observed,
    /// but when an observed object is being tracked by a `.focusedSceneVaule`,
    /// changes in the view's properties do not trigger a state refresh, which can result in
    /// command properties (e.g., disabled) not being updated until the scene itself re-evaluates.
    public func observing<V: View>(@ViewBuilder builder: @escaping (Self) -> V) -> some View {
        ObservedStateView(state: self, builder: builder)
    }
}

/// A pass-through view builder that tracks the given `ObservableObject`.
/// This is needed for creating `SwiftUI.Command` instances based on a `FocusedValue`,
/// because while the focused value will be updated when the instance itself changes (e.g.,
/// when a scene vanges the focused scene value), the value itself will not trigger a change.
private struct ObservedStateView<O: ObservableObject, V : View> : View {
    @ObservedObject var state: O
    var builder: (O) -> V

    public var body: some View {
        builder(state)
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
