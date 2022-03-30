import FairApp
import SwiftUI

/// The source of the apps
public enum AppSource: String, CaseIterable {
    case homebrew
    case fairapps
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
            return .ticket
        case .homebrew:
            return .shippingbox_fill
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

    /// Returns the homepage for the info URL
    var homepage: URL? {
        if let cask = self.cask {
            if let homepage = cask.homepage {
                if let url = URL(string: homepage) {
                    return url
                }
            }

            return nil
        } else {
            return release.homepage
        }
    }

    /// The categories as should be displayed in the UI; this will collapes sub-groups (i.e., game categories) into their parent groups.
    var displayCategories: [AppCategory] {
        release.appCategories
            .map { cat in
                switch cat {
                case .business: return .business
                case .developertools: return .developertools
                case .education: return .education
                case .entertainment: return .entertainment
                case .finance: return .finance
                case .graphicsdesign: return .graphicsdesign
                case .healthcarefitness: return .healthcarefitness
                case .lifestyle: return .lifestyle
                case .medical: return .medical
                case .music: return .music
                case .news: return .news
                case .photography: return .photography
                case .productivity: return .productivity
                case .reference: return .reference
                case .socialnetworking: return .socialnetworking
                case .sports: return .sports
                case .travel: return .travel
                case .utilities: return .utilities
                case .video: return .video
                case .weather: return .weather

                case .games: return .games

                case .actiongames: return .games
                case .adventuregames: return .games
                case .arcadegames: return .games
                case .boardgames: return .games
                case .cardgames: return .games
                case .casinogames: return .games
                case .dicegames: return .games
                case .educationalgames: return .games
                case .familygames: return .games
                case .kidsgames: return .games
                case .musicgames: return .games
                case .puzzlegames: return .games
                case .racinggames: return .games
                case .roleplayinggames: return .games
                case .simulationgames: return .games
                case .sportsgames: return .games
                case .strategygames: return .games
                case .triviagames: return .games
                case .wordgames: return .games
                }
            }
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
//                fairAppInv.activateFind()
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

        return sheet(isPresented: presented) {
            VStack(alignment: .center, spacing: 16) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 55, height: 55, alignment: .center)
                    .padding()

                if let errorDescription = firstError?.errorDescription {
                    Text(errorDescription)
                        .font(Font.headline)
                        .textSelection(.enabled)
                        .lineLimit(4)
                }

                if let failureReason = firstError?.failureReason {
                    Text(failureReason)
                        .font(Font.subheadline)
                        .textSelection(.enabled)
                        .lineLimit(5)
                }

                if let recoverySuggestion = firstError?.recoverySuggestion {
                    Text(recoverySuggestion)
                        .font(Font.subheadline)
                        .textSelection(.enabled)
                        .lineLimit(5)
                }

                if let underlyingError = (firstError as NSError?)?.underlyingErrors.first
                ?? (firstError as? AppError)?.underlyingError {
                    DisclosureGroup {
                        TextEditor(text: .constant(underlyingError.localizedDescription))
                            .textSelection(.disabled)
                            .font(Font.body.monospaced())
                            .focusable(false)
                            .frame(maxHeight: 200)
                    } label: {
                        Text("More Info")
                    }
                }

                Button {
                    errorBinding.wrappedValue.removeFirst()
                } label: {
                    Text("OK").padding()
                }
                .keyboardShortcut(.defaultAction)
            }
            .frame(width: 250)
            .padding()
//            .background(Material.thin)
            //.alert(Text(title), isPresented: .constant(true), actions: { EmptyView() }, message: { Text(message) })
        }
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
            .environmentObject(fairManager.fairAppInv)
            .environmentObject(fairManager.homeBrewInv)
    }
}

struct SidebarSelection : Hashable {
    let source: AppSource
    let item: FairAppInventory.SidebarItem
}

@available(macOS 12.0, iOS 15.0, *)
struct NavigationRootView : View {
    @EnvironmentObject var fairManager: FairManager
    @EnvironmentObject var fairAppInv: FairAppInventory
    @EnvironmentObject var homeBrewInv: HomebrewInventory

    @FocusedBinding(\.reloadCommand) private var reloadCommand: (() async -> ())?

    @State var selection: AppInfo.ID? = nil
    /// Indication that the selection should be scrolled to
    @State var scrollToSelection: Bool = false

    @State var sidebarSelection: SidebarSelection? = SidebarSelection(source: AppSource.allCases.first!, item: .top)

    @SceneStorage("displayMode") var displayMode: TriptychOrient = TriptychOrient.allCases.first!
    @AppStorage("iconBadge") private var iconBadge = true
    //@SceneStorage("source") var source: AppSource = AppSource.allCases.first!

    @State var searchText: String = ""

    public var body: some View {
        triptychView
            .frame(minHeight: 500) // we'd rather set idealWidth/idealHeight as a hint to what the original size should be, but they are ignored
            .displayingFirstAlert($fairAppInv.errors)
            .toolbar(id: "NavToolbar") {
//                ToolbarItem(placement: .navigation) {
//                    Button(action: toggleSidebar) {
//                        FairSymbol.sidebar_left.image
//                    })
//                }

                ToolbarItem(id: "ReloadButton", placement: .automatic, showsByDefault: true) {
                    Text("Reload")
                        .label(symbol: "arrow.triangle.2.circlepath.circle")
                        //.button(command: reloadCommand)
                        .button {
                            await fairManager.trying {
                                try await fairManager.refresh()
                            }
                        }
                        .hoverSymbol(activeVariant: .fill)
                        .help(Text("Reload the App Fair catalog"))
                }
                ToolbarItem(id: "DisplayModePicker", placement: .automatic, showsByDefault: false) {
                    DisplayModePicker(mode: $displayMode)
                }
            }
            .task(priority: .userInitiated) {
                dbg("refreshing fairground")
                await fairManager.trying {
                    try await fairManager.refresh()
                }
            }
            .task(priority: .low) {
                do {
                    try await homeBrewInv.installHomebrew(force: true, fromLocalOnly: true, retainCasks: true)
                } catch {
                    dbg("error unpacking homebrew in local cache:", error)
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
                if selection?.item != .top { // only clear when switching away from the "popular" tab
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
            self.sidebarSelection = SidebarSelection(source: isCask ? .homebrew : .fairapps, item: .top)

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
            AppsListView(source: sidebarSource, sidebarSelection: sidebarSelection, selection: $selection, scrollToSelection: $scrollToSelection, searchTextSource: $searchText)
        } table: {
            #if os(macOS)
            AppsTableView(source: sidebarSource, selection: $selection, sidebarSelection: sidebarSelection, searchText: $searchText)
            #endif
        } content: {
            AppDetailView()
        }
        // warning: this spikes CPU usage when idle
//        .focusedSceneValue(\.reloadCommand, .constant({
//            await fairAppInv.fetchApps(cache: .reloadIgnoringLocalAndRemoteCacheData)
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
    public var title: Text
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
    @available(macOS 12.0, iOS 15.0, *)
    var text: Text {
        switch self {
        case .business:
            return Text("appfair.business")
        case .developertools:
            return Text("appfair.developer-tools")
        case .education:
            return Text("appfair.education")
        case .entertainment:
            return Text("appfair.entertainment")
        case .finance:
            return Text("appfair.finance")
        case .graphicsdesign:
            return Text("appfair.graphics-design")
        case .healthcarefitness:
            return Text("appfair.healthcare-fitness")
        case .lifestyle:
            return Text("appfair.lifestyle")
        case .medical:
            return Text("appfair.medical")
        case .music:
            return Text("appfair.music")
        case .news:
            return Text("appfair.news")
        case .photography:
            return Text("appfair.photography")
        case .productivity:
            return Text("appfair.productivity")
        case .reference:
            return Text("appfair.reference")
        case .socialnetworking:
            return Text("appfair.social-networking")
        case .sports:
            return Text("appfair.sports")
        case .travel:
            return Text("appfair.travel")
        case .utilities:
            return Text("appfair.utilities")
        case .video:
            return Text("appfair.video")
        case .weather:
            return Text("appfair.weather")

        case .games:
            return Text("appfair.games")
        case .actiongames:
            return Text("appfair.action-games")
        case .adventuregames:
            return Text("appfair.adventure-games")
        case .arcadegames:
            return Text("appfair.arcade-games")
        case .boardgames:
            return Text("appfair.board-games")
        case .cardgames:
            return Text("appfair.card-games")
        case .casinogames:
            return Text("appfair.casino-games")
        case .dicegames:
            return Text("appfair.dice-games")
        case .educationalgames:
            return Text("appfair.educational-games")
        case .familygames:
            return Text("appfair.family-games")
        case .kidsgames:
            return Text("appfair.kids-games")
        case .musicgames:
            return Text("appfair.music-games")
        case .puzzlegames:
            return Text("appfair.puzzle-games")
        case .racinggames:
            return Text("appfair.racing-games")
        case .roleplayinggames:
            return Text("appfair.role-playing-games")
        case .simulationgames:
            return Text("appfair.simulation-games")
        case .sportsgames:
            return Text("appfair.sports-games")
        case .strategygames:
            return Text("appfair.strategy-games")
        case .triviagames:
            return Text("appfair.trivia-games")
        case .wordgames:
            return Text("appfair.word-games")
        }
    }

    @available(macOS 12.0, iOS 15.0, *)
    var symbol: FairSymbol {
        switch self {
        case .business:
            return .building_2
        case .developertools:
            return .keyboard
        case .education:
            return .graduationcap
        case .entertainment:
            return .tv
        case .finance:
            return .diamond
        case .graphicsdesign:
            return .paintpalette
        case .healthcarefitness:
            return .figure_walk
        case .lifestyle:
            return .suitcase
        case .medical:
            return .cross_case
        case .music:
            return .radio
        case .news:
            return .newspaper
        case .photography:
            return .camera
        case .productivity:
            return .puzzlepiece
        case .reference:
            return .books_vertical
        case .socialnetworking:
            return .person_3
        case .sports:
            return .rosette
        case .travel:
            return .suitcase
        case .utilities:
            return .crown
        case .video:
            return .film
        case .weather:
            return .cloud

        case .games:
            return .gamecontroller
            
        case .actiongames:
            return .gamecontroller
        case .adventuregames:
            return .gamecontroller
        case .arcadegames:
            return .gamecontroller
        case .boardgames:
            return .gamecontroller
        case .cardgames:
            return .gamecontroller
        case .casinogames:
            return .gamecontroller
        case .dicegames:
            return .gamecontroller
        case .educationalgames:
            return .gamecontroller
        case .familygames:
            return .gamecontroller
        case .kidsgames:
            return .gamecontroller
        case .musicgames:
            return .gamecontroller
        case .puzzlegames:
            return .gamecontroller
        case .racinggames:
            return .gamecontroller
        case .roleplayinggames:
            return .gamecontroller
        case .simulationgames:
            return .gamecontroller
        case .sportsgames:
            return .gamecontroller
        case .strategygames:
            return .gamecontroller
        case .triviagames:
            return .gamecontroller
        case .wordgames:
            return .gamecontroller
        }
    }

    var tint: Color {
        switch self {
        case .business:
            return Color.green
        case .developertools:
            return Color.orange
        case .education:
            return Color.blue
        case .entertainment:
            return Color.purple
        case .finance:
            return Color.green
        case .graphicsdesign:
            return Color.teal
        case .healthcarefitness:
            return Color.mint
        case .lifestyle:
            return Color.orange
        case .medical:
            return Color.white
        case .music:
            return Color.yellow
        case .news:
            return Color.brown
        case .photography:
            return Color.pink
        case .productivity:
            return Color.cyan
        case .reference:
            return Color.gray
        case .socialnetworking:
            return Color.yellow
        case .sports:
            return Color.teal
        case .travel:
            return Color.indigo
        case .utilities:
            return Color.purple
        case .video:
            return Color.yellow
        case .weather:
            return Color.blue
        case .games:
            return Color.red
        case .actiongames:
            return Color.red
        case .adventuregames:
            return Color.red
        case .arcadegames:
            return Color.red
        case .boardgames:
            return Color.red
        case .cardgames:
            return Color.red
        case .casinogames:
            return Color.red
        case .dicegames:
            return Color.red
        case .educationalgames:
            return Color.red
        case .familygames:
            return Color.red
        case .kidsgames:
            return Color.red
        case .musicgames:
            return Color.red
        case .puzzlegames:
            return Color.red
        case .racinggames:
            return Color.red
        case .roleplayinggames:
            return Color.red
        case .simulationgames:
            return Color.red
        case .sportsgames:
            return Color.red
        case .strategygames:
            return Color.red
        case .triviagames:
            return Color.red
        case .wordgames:
            return Color.red
        }
    }

    var tintedLabel: TintedLabel {
        TintedLabel(title: text, systemName: symbol.symbolName, tint: tint)
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
    @EnvironmentObject var fairAppInv: FairAppInventory
    @EnvironmentObject var homeBrewInv: HomebrewInventory
    @Binding var selection: AppInfo.ID?
    @Binding var scrollToSelection: Bool
    @Binding var sidebarSelection: SidebarSelection?
    @Binding var displayMode: TriptychOrient
    @Binding var searchText: String

    private func sectionHeader(label: Label<Text, Image>, updating: Bool) -> some View {
        HStack {
            label.labelStyle(.titleOnly)
            if updating {
                Spacer()
                ProgressView()
                    .controlSize(.mini)
                    .padding(.trailing, 18)
            }
        }
    }

    var body: some View {
        List {
            ForEach(AppSource.allCases, id: \.self) { source in
                switch source {
                case .homebrew:
                    if homeBrewInv.enableHomebrew {
                        Section {
                            item(.homebrew, item: .top).keyboardShortcut("1")
                            // item(.homebrew, .recent) // casks don't have a last-updated date
                            item(.homebrew, item: .installed).keyboardShortcut("2")
                            item(.homebrew, item: .updated).keyboardShortcut("3")
                                .symbolVariant(.fill)
                        } header: {
                            sectionHeader(label: source.label, updating: homeBrewInv.updateInProgress != 0)
                         }
                    }

                case .fairapps:
                    Section {
                        item(.fairapps, item: .top).keyboardShortcut("4")
                        item(.fairapps, item: .recent).keyboardShortcut("5")
                        item(.fairapps, item: .installed).keyboardShortcut("6")
                        item(.fairapps, item: .updated).keyboardShortcut("7")
                    } header: {
                        sectionHeader(label: source.label, updating: fairAppInv.updateInProgress != 0)

                    }
                }


            }

            // categories section
            // TODO: merge homebrew
            if homeBrewInv.enableHomebrew {
                Section {
                    ForEach(AppCategory.allCases) { cat in
                        if homeBrewInv.apps(for: cat).isEmpty == false {
                            item(.homebrew, item: .category(cat))
                        }
                    }
                    .symbolVariant(.fill)
                } header: {
                    sectionHeader(label: Label(title: { Text("Categories") }, icon: { FairSymbol.list_dash.image }), updating: homeBrewInv.updateInProgress != 0)
                }
            }
        }
        //.symbolVariant(.none)
        .symbolRenderingMode(.hierarchical)
        //.symbolVariant(.circle) // note that these can be stacked
        //.symbolVariant(.fill)
        //.symbolRenderingMode(.multicolor)
        .listStyle(.automatic)
        .toolbar(id: "SidebarView") {
            tool(.top)
            tool(.recent)
            tool(.updated)
            tool(.installed)

//            tool(.category(.entertain))
//            tool(.category(.research))
//            tool(.category(.create))
//            tool(.category(.game))
//            tool(.category(.live))
//            tool(.category(.work))
        }
    }

    func item(_ source: AppSource, item: FairAppInventory.SidebarItem) -> some View {
        let selection = SidebarSelection(source: source, item: item)
        let label = selection.item.label(for: source)
        var navtitle = label.title
        if !searchText.isEmpty {
            navtitle = navtitle + Text(": ") + Text(searchText)
        }
        return NavigationLink(tag: selection, selection: $sidebarSelection, destination: {
            navigationDestinationView(item: selection)
                .navigationTitle(navtitle)
        }, label: {
            label.badge(badgeCount(for: selection))
        })
    }

    func badgeCount(for item: SidebarSelection) -> Text? {
        switch item.source {
        case .fairapps:
            return fairAppInv.badgeCount(for: item.item)
        case .homebrew:
            return homeBrewInv.badgeCount(for: item.item)
        }
    }

    @ViewBuilder func navigationDestinationView(item: SidebarSelection) -> some View {
        switch displayMode {
        case .list:
            AppsListView(source: item.source, sidebarSelection: sidebarSelection, selection: $selection, scrollToSelection: $scrollToSelection, searchTextSource: $searchText)
        #if os(macOS)
        case .table:
            AppTableDetailSplitView(source: item.source, selection: $selection, searchText: $searchText, sidebarSelection: sidebarSelection)
        #endif
        }
    }

    func tool(source: AppSource = .fairapps, _ item: FairAppInventory.SidebarItem) -> some CustomizableToolbarContent {
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

    func selectItem(_ item: FairAppInventory.SidebarItem) {
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
extension NSUserScriptTask {
    /// Performs the given shell command and returns the output via an `NSAppleScript` operation
    /// - Parameters:
    ///   - command: the command to execute
    ///   - async: whether to fork async using `NSUserAppleScriptTask` as opposed to synchronously with `NSAppleScript`
    ///   - admin: whether to execute the script `with administrator privileges`
    /// - Returns: the string contents of the response
    public static func fork(command: String, admin: Bool = false) async throws -> String? {
        let withAdmin = admin ? " with administrator privileges" : ""

        let cmd = "do shell script \"\(command)\"" + withAdmin

        let scriptURL = URL.tmpdir
            .appendingPathComponent("scriptcmd-" + UUID().uuidString)
            .appendingPathExtension("scpt") // needed or else error that the script: “couldn’t be opened because it isn’t in the correct format”
        try cmd.write(to: scriptURL, atomically: true, encoding: .utf8)
        dbg("running NSUserAppleScriptTask in:", scriptURL.path, "command:", cmd)
        let task = try NSUserAppleScriptTask(url: scriptURL)
        let output = try await task.execute(withAppleEvent: nil)
        dbg("successfully executed script:", command)
        return output.stringValue
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

/// Intercept `LocalizedStringKey` constructor and forward it to ``SwiftUI.Text/init(_:bundle)``
/// Otherwise it will default to the main bundle's strings, which is always empty.
@usableFromInline internal func Text(_ string: LocalizedStringKey, comment: StaticString? = nil) -> SwiftUI.Text {
    SwiftUI.Text(string, bundle: .module, comment: comment)
}
