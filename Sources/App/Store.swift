import FairApp

import Foundation

/// The global app environment containing configuration metadata and shared defaults.
///
/// The shared instance of Store is available throughout the app with:
///
/// ``@EnvironmentObject var store: Store``
@MainActor public final class Store: SceneManager {
    /// The configuration metadata for the app from the `App.yml` file.
    public static let config: JSum = configuration(for: .module)

    @AppStorage("autoplayStation") public var autoplayStation = true

    #if os(macOS)
    public var statusItem: NSStatusItem? = nil
    #endif

    // @Published var queryString: String = ""
    // @Published var stations: DataFrame? = wip(nil)

    public init() {
//        /// The gloal quick actions for the App Fair
//        self.quickActions = [
//            QuickAction(id: "play-action", localizedTitle: loc("Play"), iconSymbol: "play") { completion in
//                dbg("play-action")
//                completion(true)
//            }
//        ]
    }

    @objc public func menuItemTapped(_ sender: Any?) {
        dbg()
    }
}

extension Store {
    public var bundle: Bundle { .module }

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

