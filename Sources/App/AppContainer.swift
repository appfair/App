import FairApp
import FairKit
import AVKit
import TabularData

public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        WindowGroup {
            ContentView()
                .windowToolbarUnified(compact: true, showsTitle: true)
                .environmentObject(store)
                .task {
                    //await store.createStatusItems()
                    //await store.setDockMenu()
                    do {
                        #if os(iOS)
                        try AVAudioSession.sharedInstance().setCategory(.playback)
                        try AVAudioSession.sharedInstance().setActive(true)
                        #endif
                    } catch {
                        dbg("error setting up session:", error)
                    }
                }
            // iOS only
            // .onReceive(NotificationCenter.default.publisher(for: UXApplication.didEnterBackgroundNotification)) { _ in
            //      dbg("didEnterBackgroundNotification")
            //            AVAudioSession.sharedInstance
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                // only permit a single window
            }
        }
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

@available(macOS 12.0, iOS 15.0, *)
public struct ContentView: View {
    @EnvironmentObject var store: Store

    public var body: some View {
        TuneOutView()
    }
}

@available(macOS 12.0, iOS 15.0, *)
public struct AppSettingsView : View {
    @EnvironmentObject var store: Store
    @AppStorage("searchCount") var searchCount: Int = 250

    public var body: some View {
        Form {
            Toggle(isOn: $store.autoplayStation) {
                Text("Auto-play stations when selected", bundle: .module, comment: "preferences toggle for auto-playing stations")
            }
            .help(Text("Whether to automatically start playing selected stations.", bundle: .module, comment: "help text for preferences toggle for auto-playing stations"))
        }
        .padding()
    }
}

// MARK: Package-Specific Utilities

/// Intercept `LocalizedStringKey` constructor and forward it to ``SwiftUI.Text/init(_:bundle)``
@usableFromInline internal func Text(_ string: LocalizedStringKey) -> SwiftUI.Text {
    SwiftUI.Text(string, bundle: .module)
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

extension String {
    static func localizedString(for key: String, locale: Locale = .current, comment: StaticString = "") -> String {
        NSLocalizedString(key, bundle: Bundle.module.path(forResource: locale.languageCode, ofType: "lproj").flatMap(Bundle.init(path:)) ?? Bundle.module, comment: comment.description)
    }
}

