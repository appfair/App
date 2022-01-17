import FairApp
import SwiftUI

/// The source of the apps
public enum AppSource: String, CaseIterable {
    case fairapps
    case homebrew
}

extension AppSource : Identifiable {
    public var id: Self { self }
}

@available(macOS 12.0, iOS 15.0, *)
public extension AppSource {
    var label: Label<Text, Image> {
        switch self {
        case .fairapps:
            return Label { Text("Fairground") } icon: { symbol.image }
        case .homebrew:
            return Label { Text("Homebrew") } icon: { symbol.image }
        }
    }

    var symbol: FairSymbol {
        switch self {
        case .fairapps:
            return .ticket_fill
        case .homebrew:
            return .shippingbox
        }
    }
}

//@available(macOS 12.0, iOS 15.0, *)
//public struct AppSourcePicker: View {
//    @Binding var source: AppSource
//
//    public init(source: Binding<AppSource>) {
//        self._source = source
//    }
//
//    public var body: some View {
//        // only display the picker if there is more than one element (i.e., on macOS)
//        if AppSource.allCases.count > 1 {
//            Picker(selection: $source) {
//                ForEach(AppSource.allCases) { viewMode in
//                    viewMode.label.labelStyle(.titleOnly)
//                        //.badge(appUpdatedCount())
//                }
//            } label: {
//                Text("App Source")
//            }
//            .pickerStyle(SegmentedPickerStyle())
//        }
//    }
//}


struct AppInfo : Identifiable, Equatable {
    /// The fairapp catalog item
    var release: AppCatalogItem
    /// The associated cash, if any
    var cask: CaskItem?
    var installedPlist: Plist?

    /// We are idenfitied as a cask item if we have no version date (which casks don't include in their metadata)
    var isCask: Bool {
        cask != nil
    }

    /// The bundle ID of the selected app (e.g., "app.App-Name")
    var id: AppCatalogItem.ID {
        release.id
    }

    /// The released version of this app
    /// TODO: @available(*, deprecated, message: "homebrew cask versions do not conform")
    var releasedVersion: AppVersion? {
        release.version.flatMap({ AppVersion(string: $0, prerelease: release.beta == true) })
    }

    /// The installed version of this app, which will always be indicated as a non-prerelease
    /// TODO: @available(*, deprecated, message: "homebrew cask versions do not conform")
    var installedVersion: AppVersion? {
        installedVersionString.flatMap({ AppVersion(string: $0, prerelease: false) })
    }

    /// The installed version of this app
    var installedVersionString: String? {
        installedPlist?.versionString
    }

    /// The app is updated if its installed version is less than the released version
    var appUpdated: Bool {
        //installedVersion != nil && (installedVersion ?? .max) < (releasedVersion ?? .min)
        installedVersionString != nil && installedVersionString != release.version
    }
}

extension Plist {
    /// The value of the `CFBundleIdentifier` key
    var bundleID: String? {
        self.CFBundleIdentifier
    }

    /// The value of the `CFBundleShortVersionString` key
    var versionString: String? {
        self.CFBundleShortVersionString
    }

    /// The value of the `CFBundleVersion` key
    var buildNumber: String? {
        self.CFBundleVersion
    }

    /// The semantic version for the `CFBundleShortVersionString` key.
    var appVersion: AppVersion? {
        versionString.flatMap({ AppVersion.init(string: $0, prerelease: false) })
    }
}


public typealias AppIdentifier = BundleIdentifier

// TODO: potentially separate these into separate types
// typealias AppIdentifier = XOr<BundleIdentifier>.Or<CaskIdentifier>

extension AppCatalogItem : Identifiable {
    public var id: AppIdentifier { bundleIdentifier }

    /// The hyphenated form of this app's name
    var appNameHyphenated: String {
        self.name.rehyphenated()
    }

    /// Returns the URL to this app's home page
    var baseURL: URL? {
        URL(string: "https://github.com/\(appNameHyphenated)/App")
    }

    /// The e-mail address for contacting the developer
    var developerEmail: String {
        developerName // TODO: parse out
    }

    /// Returns the URL to this app's home page
    var sourceURL: URL? {
        baseURL?.appendingPathExtension("git")
    }

    var issuesURL: URL? {
        baseURL?.appendingPathComponent("issues")
    }

    var discussionsURL: URL? {
        baseURL?.appendingPathComponent("discussions")
    }

    var developerURL: URL? {
        queryURL(type: "users", term: developerEmail)
    }

    var fairsealURL: URL? {
        queryURL(type: "issues", term: sha256 ?? "")
    }

    /// Builds a general query
    private func queryURL(type: String, term: String) -> URL! {
        URL(string: "https://github.com/search?type=" + type.escapedURLTerm + "&q=" + term.escapedURLTerm)
    }

    var fileSize: Int? {
        size
    }

    var appCategories: [AppCategory] {
        self.categories?.compactMap(AppCategory.init(metadataID:)) ?? []
    }
}


#if os(macOS)
@available(macOS 12.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct SimpleTableView : View {
    struct TableRowValue : Identifiable {
        var id = UUID()
        var num = Int.random(in: 0...100)
        var str = UUID().uuidString
    }

    @State var selection: TableRowValue.ID? = nil
    @State var items: [TableRowValue] = (1...100).map({ SimpleTableView.TableRowValue(num: $0) })
    @State var sortOrder = [KeyPathComparator(\TableRowValue.num)]

    var body: some View {
        Table(items, selection: $selection, sortOrder: $sortOrder, columns: {
            TableColumn("String", value: \.str)
        })
    }
}
#endif

/// The current selected instance, which can either be a release or a workflow run
@available(macOS 12.0, iOS 15.0, *)
enum Selection {
    case app(AppInfo)
}

@available(macOS 12.0, iOS 15.0, *)
struct SearchCommands: Commands {
    var body: some Commands {
        CommandGroup(after: CommandGroupPlacement.textEditing) {
            Section {
                #if os(macOS)
                Text("Search").button {
                    if let window = NSApp.currentEvent?.window,
                       let toolbar = window.toolbar {
                        // <SwiftUI.AppKitSearchToolbarItem: 0x13a8721a0> identifier = "com.apple.SwiftUI.search"]
                        if let searchField = toolbar.visibleItems?.first(where: { $0.itemIdentifier.rawValue == "com.apple.SwiftUI.search" }) {
                            dbg("searchField:", searchField, searchField.view) // view is empty
                            // window.makeFirstResponder(view)
                        }
                    }
                }
                .keyboardShortcut("F")
                #endif
            }
        }
    }
}


@available(macOS 12.0, iOS 15.0, *)
struct AppFairCommands: Commands {
    @FocusedBinding(\.selection) private var selection: Selection??
//    @FocusedBinding(\.reloadCommand) private var reloadCommand: (() async -> ())?
    var fairManager: FairManager

    var body: some Commands {

//        switch selection {
//        case .app(let app):
//        case .run(let run):
//        case .none:
//        case .some(.none):
//        }

//        CommandMenu("Fair") {
//            Button("Find") {
//                appManager.activateFind()
//            }
//            .keyboardShortcut("F")
//        }

//        CommandGroup(before: .newItem) {
//            ShareAppButton()
//        }

        CommandMenu(Text("Fair")) {
            Text("Reload Apps")
                .button(action: reloadAll)
                .keyboardShortcut("R")
//                .disabled(reloadCommand == nil)
        }
    }

    func reloadAll() {
        Task {
            await fairManager.trying {
                try await fairManager.refresh()
            }
        }
    }
}

/// The reason why an action failed
public enum AppFailure {
    case reloadFailed

    var failureReason: LocalizedStringKey? {
        switch self {
        case .reloadFailed: return "Reload Failed"
        }
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

@available(macOS 12.0, iOS 15.0, *)
public struct HelpButton : View {
    let url: String
    @Environment(\.openURL) var openURL

    public var body: some View {
        Button(role: .none, action: {
            if let url = URL(string: url) {
                openURL(url)
            }
        }) {
            //FairSymbol.questionmark_circle_fill
            FairSymbol.questionmark
        }
        .buttonStyle(.bordered)
    }

}

extension View {
    /// Redacts the view when the given condition is true
    @ViewBuilder public func redacting(when condition: Bool) -> some View {
        if condition {
            self.redacted(reason: .placeholder)
        } else {
            self
        }
    }
}

public extension View {
    /// Places the given closure in a stack, either an `HStack` for `Axis.horizontal`
    /// or a `VStack` for `Axis.vertical`, with the given `proportion` granted to the view.
    @ViewBuilder func stack<V: View>(_ direction: Axis, proportion: Double, @ViewBuilder view neighbor: @escaping () -> V) -> some View {
        GeometryReader { proxy in
            switch direction {
            case .horizontal:
                HStack {
                    self
                    neighbor()
                        .frame(idealWidth: proxy.size.width * proportion)
                        .fixedSize(horizontal: true, vertical: false)
                }
            case .vertical:
                VStack {
                    self
                    neighbor()
                        .frame(idealHeight: proxy.size.height * proportion)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

extension View {
    /// Applies a modifier to the view that matches a static directive.
    /// This is used to invoke methods that may be conditionally available.
    ///
    /// Example:
    ///
    /// ```
    /// List {
    ///     ForEach(elements, content: elementView)
    /// }
    /// .conditionally {
    ///     #if os(macOS)
    ///     $0.listStyle(.bordered(alternatesRowBackgrounds: true))
    ///     #endif
    /// }
    /// ```
    public func conditionally<V: View>(content matchingStaticCondition: (Self) -> (V)) -> V {
        matchingStaticCondition(self)
    }

    /// - See: ``View/conditionally(matchingStaticCondition:)``
    public func conditionally(content notMatchingStaticCondition: (Self) -> (Void)) -> Self {
        // this is the fall-through that simply returns the view itself.
        self
    }

    /// Centers this view in an `HStack` with spacers.
    /// - Parameters:
    ///   - alignment: the alignment to apply to the stack
    ///   - minLength: the minimum size of the spacers
    /// - Returns: the view centered in an `HStack` surrounded by `Spacer` views
    public func hcenter(alignment: VerticalAlignment = .center, minLength: CoreGraphics.CGFloat? = nil) -> some View {
        HStack(alignment: alignment) {
            Spacer(minLength: minLength)
            self
            Spacer(minLength: minLength)
        }
    }

    /// Centers this view in an `VStack` with spacers.
    /// - Parameters:
    ///   - alignment: the alignment to apply to the stack
    ///   - minLength: the minimum size of the spacers
    /// - Returns: the view centered in an `VStack` surrounded by `Spacer` views
    public func vcenter(alignment: HorizontalAlignment = .center, minLength: CoreGraphics.CGFloat? = nil) -> some View {
        VStack(alignment: alignment) {
            Spacer(minLength: minLength)
            self
            Spacer(minLength: minLength)
        }
    }

}

public extension View {
    /// Returns a `Bool` binding that indicates whether another binding is `null`
    func nullifyingBoolBinding<T>(_ binding: Binding<T?>) -> Binding<Bool> {
        Binding(get: {
            binding.wrappedValue != nil
        }, set: { newValue in
            if newValue == false {
                binding.wrappedValue = .none
            }
        })
    }

    @available(macOS 12.0, iOS 15.0, *)
    func displayingFirstAlert<E: LocalizedError>(_ errorBinding: Binding<[E]>) -> some View {
        let presented: Binding<Bool> = Binding(get: {
            !errorBinding.wrappedValue.isEmpty
        }, set: { newValue in
            if newValue == false && !errorBinding.wrappedValue.isEmpty {
                errorBinding.wrappedValue.remove(at: 0)
            }
        })

        let firstError = errorBinding.wrappedValue.first
        return alert(isPresented: presented, error: firstError, actions: {
            EmptyView()
            //Button(wip("ERROR")) { dbg("XXX") }
        })
    }
}

@available(macOS 12.0, iOS 15.0, *)
extension View {
    /// Creates a button with the given optional async action.
    ///
    /// This is intended to be used with something like:
    ///
    /// ```
    /// @FocusedBinding(\.reloadCommand) private var reloadCommand: (() async -> ())?
    ///
    /// Text("Reload")
    ///     .label(symbol: "arrow.triangle.2.circlepath.circle")
    ///     .button(command: reloadCommand)
    /// ```
    ///
    /// The button will be disabled when the action is `nil`.
    func button(command: (() async -> ())?) -> some View {
        button {
            Task {
                await command?()
            }
        }
        .disabled(command == nil)
    }
}

@available(macOS 12.0, iOS 15.0, *)
public struct RootView : View {
    let fairManager: FairManager

    public var body: some View {
        NavigationRootView()
            .environmentObject(fairManager)
            .environmentObject(fairManager.appManager)
            .environmentObject(fairManager.caskManager)
    }
}

//typealias SidebarSelection = AppManager.SidebarItem

struct SidebarSelection : Hashable {
    let source: AppSource
    let item: AppManager.SidebarItem
}

@available(macOS 12.0, iOS 15.0, *)
struct NavigationRootView : View {
    @EnvironmentObject var fairManager: FairManager
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var caskManager: CaskManager

    @FocusedBinding(\.reloadCommand) private var reloadCommand: (() async -> ())?

    @State var selection: AppInfo.ID? = nil
    /// Indication that the selection should be scrolled to
    @State var scrollToSelection: Bool = false

    @State var sidebarSelection: SidebarSelection? = SidebarSelection(source: .fairapps, item: .all)

    @SceneStorage("displayMode") var displayMode: TriptychOrient = TriptychOrient.allCases.first!
    @AppStorage("iconBadge") private var iconBadge = true
    //@SceneStorage("source") var source: AppSource = AppSource.allCases.first!

    @State var searchText: String = ""

    public var body: some View {
        triptychView
            .frame(minHeight: 600) // we'd rather set idealWidth/idealHeight as a hint to what the original size should be, but they are ignored
            .displayingFirstAlert($appManager.errors)
            .toolbar(id: "NavToolbar") {
                ToolbarItem(id: "ReloadButton", placement: .automatic, showsByDefault: true) {
                    Text("Reload")
                        .label(symbol: "arrow.triangle.2.circlepath.circle")
                        .button(command: reloadCommand)
                        .hoverSymbol(activeVariant: .fill)
                        .help(Text("Reload the App Fair catalog"))
                        .keyboardShortcut("R")
                }
                ToolbarItem(id: "DisplayModePicker", placement: .automatic, showsByDefault: false) {
                    DisplayModePicker(mode: $displayMode)
                }
            }
            .task(priority: .high) {
                dbg("scanning installed apps")
                await fairManager.trying {
                    try await fairManager.refresh()
                }
            }
            .onChange(of: fairManager.updateCount()) { updateCount in
                if iconBadge == true {
                    UXApplication.shared.setBadge(updateCount)
                }
            }
            .onChange(of: iconBadge) { iconBadge in
                // update the badge when the setting changes
                UXApplication.shared.setBadge(iconBadge ? fairManager.updateCount() : 0)
            }
            .onChange(of: sidebarSelection) { selection in
                if selection?.item != .all { // only clear when switching away from the "popular" tab
                    searchText = "" // clear search whenever the sidebar selection changes
                }
            }
            .handlesExternalEvents(preferring: [], allowing: ["*"]) // re-use this window to open external URLs
            .onOpenURL(perform: handleURL)
    }

    /// Handles opening the URL schemes suppored by this app.
    ///
    /// Supported schemes:
    ///
    ///   1. `appfair://app/App-Name`: selects the "Apps" outline and searches for "app.App-Name"
    ///   1. `appfair://cask/token`: selects the "Casks" outline and searches for "homebrew/cask/token"
    func handleURL(_ url: URL) {
        let components = url.pathComponents
        dbg("handling app URL", url.absoluteString, "scheme:", url.scheme, "action:", components)
        if let scheme = url.scheme, scheme == "appfair" {
            var path = ([url.host ?? ""] + url.pathComponents)
                .filter { !$0.isEmpty && $0 != "." && $0 != "/" }

            if path.count < 1 {
                dbg("invalid URL path", path)
                return
            }

            if path.count == 2 && path.first == "cask" {
                path.insert("homebrew", at: 0)
            }

            let isCask = path.first == "homebrew"
            let searchID = path.joined(separator: isCask ? "/" : ".") // "homebrew/cask/iterm2" vs. "app/Tidal-Zone"

            let bundleID = BundleIdentifier(searchID)

            // random crashes seem to happen without dispatching to main
            self.searchText = bundleID.rawValue // needed to cause the item to appear
            self.sidebarSelection = SidebarSelection(source: isCask ? .homebrew : .fairapps, item: .all)

            // without the async, we crash with: 2022-01-16 15:59:21.205139-0500 App Fair[44011:2933267] [General] *** __boundsFail: index 2 beyond bounds [0 .. 1] … [NSSplitViewController removeSplitViewItem:] … s7SwiftUI22AppKitNavigationBridgeC10showDetail33_7420C33EDE6D7EA74A00CE41E680CEAELLySbAA0E18DestinationContentVF
            DispatchQueue.main.async {
                self.selection = bundleID
                dbg("selected app ID", self.selection)
//                        DispatchQueue.main.async {
//                            self.scrollToSelection = true // if the catalog item is offscreen, then the selection will fail, so we need to also refine the current search to the bundle id
//                        }
            }
        }
    }

    /// The currently selected source for the sidebar
    var sidebarSource: AppSource {
        return sidebarSelection?.source ?? .fairapps
    }

    public var triptychView : some View {
        TriptychView(orient: $displayMode) {
            SidebarView(selection: $selection, scrollToSelection: $scrollToSelection, sidebarSelection: $sidebarSelection, displayMode: $displayMode, searchText: $searchText)
        } list: {
            AppsListView(source: sidebarSource, selection: $selection, scrollToSelection: $scrollToSelection, sidebarSelection: sidebarSelection, searchText: $searchText)
        } table: {
            #if os(macOS)
            AppsTableView(source: sidebarSource, selection: $selection, sidebarSelection: sidebarSelection, searchText: $searchText)
            #endif
        } content: {
            AppDetailView()
        }
        // warning: this spikes CPU usage when idle
//        .focusedSceneValue(\.reloadCommand, .constant({
//            await appManager.fetchApps(cache: .reloadIgnoringLocalAndRemoteCacheData)
//        }))
    }
}

#if os(macOS)
@available(macOS 12.0, iOS 15.0, *)
public struct AppTableDetailSplitView : View {
    let source: AppSource
    @Binding var selection: AppInfo.ID?
    @Binding var searchText: String
    let sidebarSelection: SidebarSelection?

    @ViewBuilder public var body: some View {
        VSplitView {
            AppsTableView(source: source, selection: $selection, sidebarSelection: sidebarSelection, searchText: $searchText)
                .frame(minHeight: 150)
            AppDetailView()
                .layoutPriority(1.0)
        }
    }
}
#endif


@available(macOS 12.0, iOS 15.0, *)
public struct AppDetailView : View {
    @FocusedBinding(\.selection) private var selection: Selection??

    public var body: some View {
        VStack {
            switch selection {
            case .app(let app):
                CatalogItemView(info: app)
            case .none:
                Text("No Selection").font(.title)
            case .some(.none):
                Text("No Selection").font(.title)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A label that tints its image
@available(macOS 12.0, iOS 15.0, *)
public struct TintedLabel : View {
    @Environment(\.colorScheme) var colorScheme
    public let title: Text
    public let systemName: String
    public var tint: Color? = nil
    public var mode: SymbolRenderingMode? = nil

    public var body: some View {
        Label(title: { title }) {
            if let tint = tint {
                if let mode = mode {
                    Image(systemName: systemName.description)
                        .symbolRenderingMode(mode)
                        .foregroundStyle(tint)
                } else {
                    Image(systemName: systemName.description)
                        .fairTint(simple: false, color: tint, scheme: colorScheme)
                }
            } else {
                Image(systemName: systemName.description)
            }
        }
    }
}

extension View {
    /// The custom tinting style for the App Fair
    @available(macOS 12.0, iOS 15.0, *)
    @ViewBuilder func fairTint(simple: Bool, color: Color, scheme: ColorScheme) -> some View {
        if simple {
            foregroundStyle(.linearGradient(colors: [color, color], startPoint: .top, endPoint: .bottom))
                .opacity(0.8)
        } else {
            foregroundStyle(
                .linearGradient(colors: [color.opacity(0.5), color], startPoint: .top, endPoint: .bottom),
                .linearGradient(colors: [color.opacity(0.5), .green], startPoint: .top, endPoint: .bottom),
                .linearGradient(colors: [color.opacity(0.5), .blue], startPoint: .top, endPoint: .bottom)
            )
//                .brightness(scheme == .light ? -0.3 : 0.3) // brighten the image a bit
        }
    }
}

extension SwiftUI.Color {
    /// Adjusrs the given components of the color
    @available(*, deprecated, message: "must handle color space conversion") // else: “-getHue:saturation:brightness:alpha: not valid for the NSColor Catalog color: #$customDynamic 2939580E-3E73-4C4B-B435-371CEF86B9D1; need to first convert colorspace.”
    func adjust(hue: Double = 0.0, saturation: Double = 0.0, brightness: Double = 0.0, alpha: Double = 0.0) -> Color {
        var h = CGFloat(0.0)
        var s = CGFloat(0.0)
        var b = CGFloat(0.0)
        var a = CGFloat(0.0)
        UXColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        h += hue
        s += saturation
        b += brightness
        a += alpha
        return Color(hue: h, saturation: s, brightness: b, opacity: a)

    }
}
public extension AppCategory {
    /// The grouping for an app category
    enum Grouping : String, CaseIterable, Hashable {
        case create
        case research
        case communicate
        case entertain
        case live
        case game
        case work

        /// All the categories that belong to this grouping
        public var symbolName: String {
            switch self {
            case .create: return FairSymbol.puzzlepiece.symbolName
            case .research: return FairSymbol.book.symbolName
            case .communicate: return FairSymbol.envelope.symbolName
            case .entertain: return FairSymbol.sparkles_tv.symbolName
            case .live: return FairSymbol.house.symbolName
            case .game: return FairSymbol.circle_hexagongrid.symbolName
            case .work: return FairSymbol.briefcase.symbolName
            }
        }

        /// All the categories that belong to this grouping
        @available(macOS 12.0, iOS 15.0, *)
        public var tintColor: Color {
            switch self {
            case .create: return .cyan
            case .research: return .green
            case .communicate: return .pink
            case .entertain: return .teal
            case .live: return .mint
            case .game: return .yellow
            case .work: return .brown
            }
        }


        @available(macOS 12.0, iOS 15.0, *)
        public var tintedLabel: TintedLabel {
            TintedLabel(title: text, systemName: symbolName, tint: tintColor)
        }

        @available(macOS 12.0, iOS 15.0, *)
        public var text: Text {
            switch self {
            case .create:
                return Text("Arts & Crafts")
            case .research:
                return Text("Knowledge")
            case .communicate:
                return Text("Communication")
            case .entertain:
                return Text("Entertainment")
            case .live:
                return Text("Health & Lifestyle")
            case .game:
                return Text("Diversion")
            case .work:
                return Text("Work")
            }
        }

        /// All the categories that belong to this grouping
        public var categories: [AppCategory] {
            switch self {
            case .create: return Self.createCategories
            case .research: return Self.researchCategories
            case .communicate: return Self.communicateCategories
            case .entertain: return Self.entertainCategories
            case .live: return Self.liveCategories
            case .game: return Self.gameCategories
            case .work: return Self.workCategories
            }
        }

        private static let createCategories = AppCategory.allCases.filter({ $0.groupings.contains(.create) })
        private static let researchCategories = AppCategory.allCases.filter({ $0.groupings.contains(.research) })
        private static let communicateCategories = AppCategory.allCases.filter({ $0.groupings.contains(.communicate) })
        private static let entertainCategories = AppCategory.allCases.filter({ $0.groupings.contains(.entertain) })
        private static let liveCategories = AppCategory.allCases.filter({ $0.groupings.contains(.live) })
        private static let gameCategories = AppCategory.allCases.filter({ $0.groupings.contains(.game) })
        private static let workCategories = AppCategory.allCases.filter({ $0.groupings.contains(.work) })
    }

    var groupings: Set<Grouping> {
        switch self {
        case .graphicsdesign: return [.create]
        case .photography: return [.create]
        case .productivity: return [.create]
        case .video: return [.create]
        case .developertools: return [.create]

        case .business: return [.work]
        case .finance: return [.work]
        case .utilities: return [.work]

        case .education: return [.research]
        case .weather: return [.research]
        case .reference: return [.research]
        case .news: return [.research]

        case .socialnetworking: return [.communicate]

        case .healthcarefitness: return [.live]
        case .lifestyle: return [.live]
        case .medical: return [.live]
        case .travel: return [.live]

        case .sports: return [.entertain]
        case .entertainment: return [.entertain]

        case .games: return [.game]
        case .actiongames: return [.game]
        case .adventuregames: return [.game]
        case .arcadegames: return [.game]
        case .boardgames: return [.game]
        case .cardgames: return [.game]
        case .casinogames: return [.game]
        case .dicegames: return [.game]
        case .educationalgames: return [.game]
        case .familygames: return [.game]
        case .kidsgames: return [.game]
        case .musicgames: return [.game]
        case .puzzlegames: return [.game]
        case .racinggames: return [.game]
        case .roleplayinggames: return [.game]
        case .simulationgames: return [.game]
        case .sportsgames: return [.game]
        case .strategygames: return [.game]
        case .triviagames: return [.game]
        case .wordgames: return [.game]
        case .music: return [.game]
        }
    }
}


/// A view that passes its enabled state to the given content closure
public struct EnabledView<V: View> : View {
    @Environment(\.isEnabled) var isEnabled
    public let content: (Bool) -> V

    public init(@ViewBuilder content: @escaping (Bool) -> V) {
        self.content = content
    }

    public var body: some View {
        content(isEnabled)
    }
}


@available(macOS 12.0, iOS 15.0, *)
struct SidebarView: View {
    @EnvironmentObject var fairManager: FairManager
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var caskManager: CaskManager
    @Binding var selection: AppInfo.ID?
    @Binding var scrollToSelection: Bool
    @Binding var sidebarSelection: SidebarSelection?
    @Binding var displayMode: TriptychOrient
    @Binding var searchText: String

    func shortCut(for grouping: AppCategory.Grouping, offset: Int) -> KeyboardShortcut {
        let index = (AppCategory.Grouping.allCases.enumerated().first(where: { $0.element == grouping })?.offset ?? 0) + offset
        if index > 9 || index < 0 {
            return KeyboardShortcut("0") // otherwise: Fatal error: Can't form a Character from a String containing more than one extended grapheme cluster
        } else {
            let key = Character("\(index)") // the first three are taken by favorites
            return KeyboardShortcut(KeyEquivalent(key))
        }
    }

    var body: some View {
        List {
            Section("Fairground") {
                item(.fairapps, .all).keyboardShortcut("1")
                item(.fairapps, .recent).keyboardShortcut("2")
                item(.fairapps, .installed).keyboardShortcut("3")
                item(.fairapps, .updated).keyboardShortcut("4")
            }

            if caskManager.enableHomebrew {
                Section("Homebrew") {
                    item(.homebrew, .all).keyboardShortcut("5")
                    // item(.homebrew, .recent) // casks don't have a last-updated date
                    item(.homebrew, .installed).keyboardShortcut("6")
                    item(.homebrew, .updated).keyboardShortcut("7")
                }
            }

//            Section("Categories") {
//                ForEach(AppCategory.Grouping.allCases, id: \.self) { grouping in
//                    item(.fairapps, .category(grouping))
//                        .keyboardShortcut(shortCut(for: grouping, offset: 5))
//                }
//            }

//            Section("Searches") {
//                item(.search("Search 1"))
//                item(.search("Search 2"))
//                item(.search("Search 3"))
//            }
        }
        //.symbolVariant(.none)
        .symbolRenderingMode(.hierarchical)
        //.symbolVariant(.circle) // note that these can be stacked
        //.symbolVariant(.fill)
        //.symbolRenderingMode(.multicolor)
        .listStyle(.automatic)
        .toolbar(id: "SidebarView") {
            tool(.all)
            tool(.recent)
            tool(.updated)
            tool(.installed)

            tool(.category(.entertain))
            tool(.category(.research))
            tool(.category(.create))
            tool(.category(.game))
            tool(.category(.live))
            tool(.category(.work))
        }
    }

    func item(_ source: AppSource, _ item: AppManager.SidebarItem) -> some View {
        let selection = SidebarSelection(source: source, item: item)
        let label = selection.item.label(for: source)
        return NavigationLink(tag: selection, selection: $sidebarSelection, destination: {
            navigationDestinationView(item: selection)
                .navigationTitle(label.title)
        }, label: {
            label.badge(badgeCount(for: selection))
        })
    }

    func badgeCount(for item: SidebarSelection) -> Text? {
        switch item.source {
        case .fairapps:
            return appManager.badgeCount(for: item.item)
        case .homebrew:
            return caskManager.badgeCount(for: item.item)
        }
    }

    @ViewBuilder func navigationDestinationView(item: SidebarSelection) -> some View {
        switch displayMode {
        case .list:
            AppsListView(source: item.source, selection: $selection, scrollToSelection: $scrollToSelection, sidebarSelection: sidebarSelection, searchText: $searchText)
        #if os(macOS)
        case .table:
            AppTableDetailSplitView(source: item.source, selection: $selection, searchText: $searchText, sidebarSelection: sidebarSelection)
        #endif
        }
    }

    func tool(source: AppSource = .fairapps, _ item: AppManager.SidebarItem) -> some CustomizableToolbarContent {
        ToolbarItem(id: item.id, placement: .automatic, showsByDefault: false) {
            Button(action: {
                selectItem(item)
            }, label: {
                item.label(for: source)
                    //.symbolVariant(.fill)
//                    .symbolRenderingMode(.multicolor)
            })
        }
    }

    func selectItem(_ item: AppManager.SidebarItem) {
        dbg("selected:", item.label, item.id)
    }
}

@available(macOS 12.0, iOS 15.0, *)
extension FocusedValues {

//    private struct FocusedGardenKey: FocusedValueKey {
//        typealias Value = Binding<Selection?>
//    }
//
//    var garden: Binding<Garden>? {
//        get { self[FocusedGardenKey.self] }
//        set { self[FocusedGardenKey.self] = newValue }
//    }

    private struct FocusedSelection: FocusedValueKey {
        typealias Value = Binding<Selection?>
    }

    var selection: Binding<Selection?>? {
        get { self[FocusedSelection.self] }
        set { self[FocusedSelection.self] = newValue }
    }

    private struct FocusedReloadCommand: FocusedValueKey {
        typealias Value = Binding<() async -> ()>
    }

    var reloadCommand: Binding<() async -> ()>? {
        get { self[FocusedReloadCommand.self] }
        set { self[FocusedReloadCommand.self] = newValue }
    }
}


#if os(macOS)
extension NSAppleScript {
    /// Performs the given shell command and returns the output via an `NSAppleScript` operation
    public static func fork(command: String, admin: Bool = false) throws -> String? {
        let withAdmin = admin ? " with administrator privileges" : ""

        let cmd = "do shell script \"\(command)\"" + withAdmin

        guard let script = NSAppleScript(source: cmd) else {
            throw CocoaError(.coderReadCorrupt)
        }

        var errorDict: NSDictionary?
        let output: NSAppleEventDescriptor = script.executeAndReturnError(&errorDict)

        if var errorDict = errorDict as? [String: Any] {
            dbg("script execution error:", errorDict) // e.g.: script execution error: { NSAppleScriptErrorAppName = "App Fair"; NSAppleScriptErrorBriefMessage = "chmod: /Applications/App Fair/Pan Opticon.app: No such file or directory"; NSAppleScriptErrorMessage = "chmod: /Applications/App Fair/Pan Opticon.app: No such file or directory"; NSAppleScriptErrorNumber = 1; NSAppleScriptErrorRange = "NSRange: {0, 106}"; }

            // also: ["NSAppleScriptErrorMessage": User canceled., "NSAppleScriptErrorAppName": App Fair, "NSAppleScriptErrorNumber": -128, "NSAppleScriptErrorBriefMessage": User canceled., "NSAppleScriptErrorRange": NSRange: {0, 115}]

            // should we re-throw the original error (which would help explain the root cause of the problem), or the script failure error (which will be more vague but will include the information about why the re-auth failed)?
            errorDict[NSLocalizedFailureReasonErrorKey] = errorDict["NSAppleScriptErrorMessage"]
            errorDict[NSLocalizedDescriptionKey] = errorDict["NSAppleScriptErrorBriefMessage"]

            throw NSError(domain: "", code: 0, userInfo: errorDict)
        } else {
            dbg("successfully executed script:", command)
            return output.stringValue
        }
    }
}
#endif


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

/// If true, show simulated information
let pretendMode = false // wip(true) // pretend mode is for pretend

/// Intercept `LocalizedStringKey` constructor and forward it to ``SwiftUI.Text/init(_:bundle)``
@usableFromInline internal func Text(_ string: LocalizedStringKey) -> SwiftUI.Text {
    SwiftUI.Text(string, bundle: .module)
}

