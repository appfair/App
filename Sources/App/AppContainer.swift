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

// The entry point to creating your app is the `AppContainer` type,
// which is a stateless enum declared in `AppMain.swift` and may not be changed.
// 
// App customization is done via extensions in `AppContainer.swift`,
// which enables customization of the root scene, app settings, and
// other features of the app.

@available(macOS 12.0, iOS 15.0, *)
public extension AppContainer {
    /// The body of your scene is provided by `AppContainer.scene`
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .task {
                    //await store.createStatusItems()
                    //await store.setDockMenu()
                }
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                // only permit a single window
            }
        }
        //.windowToolbarStyle(.automatic) // macOS only
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store: Store) -> some SwiftUI.View {
        AppSettingsView().environmentObject(store)
    }
}

@available(macOS 12.0, iOS 15.0, *)
extension Store {
    func setDockMenu() {
        #if os(macOS)
        let clockView = ClockView()
        NSApp.dockTile.contentView = NSHostingView(rootView: clockView)
        NSApp.dockTile.display()
        NSApp.dockTile.badgeLabel = "ABC"
        NSApp.dockTile.showsApplicationBadge = true
        #endif
    }

    /// Creates the status and dock menus for this application on macOS
    func createStatusItems() {
        #if os(macOS)
        if self.statusItem == nil {
            let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            if let button = statusItem.button {
                button.appearsDisabled = false

                if let img = NSImage(systemSymbolName: "infinity.circle.fill", accessibilityDescription: "Tune-Out icon") {
                    if let tinted = img.withSymbolConfiguration(.init(paletteColors: [.controlAccentColor])) {
                        tinted.isTemplate = true

                        button.image = tinted
                        // button.title = wip("Tune Out") // overlaps the icon!

                        let menu = NSMenu(title: "Tune Out Menu")
                        let menuItem = NSMenuItem(title: "Menu Item", action: #selector(Store.menuItemTapped), keyEquivalent: ";")
                        menuItem.target = self
                        menu.addItem(menuItem)

                        statusItem.menu = menu
                    }
                }
            }
            self.statusItem = statusItem
        }
        #else // os(macOS)
        dbg("skipping status item on iOS")
        #endif
    }
}

struct ClockView: View {
    @State var currentTime: (hour: String, minute: String) = ("", "")
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    let backgroundColor = Color.accentColor
    let clockColor = Color.red

    var body: some View {
        GeometryReader { parent in
            let fontSize = parent.size.height * 0.4
            let clockFont = Font.system(size: fontSize)
            let hSpacing = fontSize * 0.25

            VStack {
                Text(currentTime.hour)
                    .padding(.bottom, -hSpacing)
                Text(currentTime.minute)
                    .padding(.top, -hSpacing)
            }
            .font(clockFont)
            .frame(width: parent.size.width, height: parent.size.height)
            .foregroundColor(clockColor)
            .background(backgroundColor)
            .cornerRadius(parent.size.height * 0.2)
            .shadow(radius: 3)
        }
        .onReceive(timer) { currentDate in
            let components = Calendar.current.dateComponents([.hour, .minute], from: currentDate)
            let hour = components.hour ?? 0
            let minute = components.minute ?? 0

            currentTime = (String(format: "%02d", hour), String(format: "%02d", minute))
            dbg(currentTime)

        }
//        .padding(10)
    }
}


/// The shared app environment
@available(macOS 12.0, iOS 15.0, *)
@MainActor public final class Store: SceneManager {
    /// The search string the user is entering
    @Published var queryString: String = ""
    @AppStorage("someToggle")
    public var someToggle = false
    #if os(macOS)
    public var statusItem: NSStatusItem? = nil
    #endif

    @objc public func menuItemTapped(_ sender: Any?) {
        dbg()
    }
}

@available(macOS 12.0, iOS 15.0, *)
public struct ContentView: View {
    @EnvironmentObject var store: Store

    public var body: some View {
        TuneOutView()
            .searchable(text: $store.queryString, placement: .automatic, prompt: Text("Search"))
            .toolbar {
                Button {
                    dbg(wip("shuffle"))
                } label: {
                    Label("Shuffle", systemImage: "shuffle")
                }
                .help(Text("Shuffle the current selection"))
                .symbolRenderingMode(.multicolor)
                //.symbolVariant(.circle)
                //.symbolVariant(.fill)
                //.symbolVariant(.slash)
            }
    }
}

@available(macOS 12.0, iOS 15.0, *)
public struct AppSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        EmptyView()
    }
}

/// Work-in-Progress marker
@available(*, deprecated, message: "work in progress")
internal func wip<T>(_ value: T) -> T { value }

/// Intercept `LocalizedStringKey` constructor and forward it to ``SwiftUI.Text/init(_:bundle)``
@usableFromInline internal func Text(_ string: LocalizedStringKey) -> SwiftUI.Text {
    SwiftUI.Text(string, bundle: .module)
}
