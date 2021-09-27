import FairApp

//extension FairHub {
//    /// The App Fair's fair-ground hub
//    static let appfair: Self = try! FairHub(hostOrg: "github.com/appfair")
//}

struct AppInfo : Identifiable {
    var release: FairAppCatalog.AppRelease
    var installedPlist: Plist? = nil

    var id: FairAppCatalog.AppRelease.ID {
        release.id
    }

    /// The released version of this app
    var releasedVersion: AppVersion? {
        release.version.flatMap(AppVersion.init(string:))
    }

    /// The installed version of this app
    var installedVersion: AppVersion? {
        installedVersionString.flatMap(AppVersion.init(string:))
    }

    /// The installed version of this app
    private var installedVersionString: String? {
        installedPlist?.versionString
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
}


extension FairAppCatalog.AppRelease : Identifiable {
    public var id: URL { downloadURL }

    /// The hyphenated form of this app's name
    var appNameHyphenated: String {
        self.name.replacingOccurrences(of: " ", with: "-")
    }

    /// Returns the URL to this app's home page
    var baseURL: URL! {
        URL(string: "https://github.com/\(appNameHyphenated)/App")
    }

    /// Returns the URL to this app's home page
    var sourceURL: URL! {
        baseURL!.appendingPathExtension("git")
    }

    var issuesURL: URL! {
        baseURL!.appendingPathComponent("issues")
    }

    var discussionsURL: URL! {
        baseURL!.appendingPathComponent("discussions")
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
struct AppFairCommands: Commands {
    @FocusedBinding(\.selection) private var selection: Selection??
    @FocusedBinding(\.reloadCommand) private var reloadCommand: (() async -> ())?
    var appManager: AppManager

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

        CommandMenu(Text("Fair", bundle: .module)) {
            Bundle.module.button("Reload Apps") {
                guard let cmd = reloadCommand else {
                    dbg("no reload command")
                    return
                }
                let start = CFAbsoluteTimeGetCurrent()
                Task {
                    await cmd()
                    let end = CFAbsoluteTimeGetCurrent()
                    dbg("reloaded:", end - start)
                }
            }
            .keyboardShortcut("R")
            .disabled(reloadCommand == nil)
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

@available(macOS 12.0, iOS 15.0, *)
extension AppManager {
    typealias Item = URL

    func hub() throws -> FairHub {
        try FairHub(hostOrg: hubProvider + "/" + hubOrg, authToken: hubToken.isEmpty ? nil : hubToken)
    }

    func activateFind() {
        dbg("### ", #function) // TODO: is there a way to focus the search field?
    }

    func share(_ item: Item) {
        dbg("### ", #function)
    }

    func markFavorite(_ item: Item) {
        dbg("### ", #function)
    }

    func deleteItem(_ item: Item) {
        dbg("### ", #function)
    }

    func submitCurrentSearchQuery() {
        dbg("### ", #function)
    }

    func openFilters() {
        dbg("### ", #function)
    }

    func appCount(_ grouping: AppCategory.Grouping) -> Text? {
        if grouping == .research {
            return Text("10", bundle: .module)
        } else {
            return nil
        }
    }

    func badgeCount(for item: SidebarItem) -> Text? {
        switch item {
        case .search(_):
            return nil
        case .popular:
            return nil // Text(123.localizedNumber(style: .decimal))
        case .pinned:
            return nil // Text(11.localizedNumber(style: .decimal))
        case .recent:
            return nil // Text(32.localizedNumber(style: .decimal))
        case .installed:
            return Text(installedBundleIDs.count.localizedNumber(style: .decimal))
        case .category:
            if pretendMode {
                let pretendCount = item.id.utf8Data.sha256().first ?? 0 // 0-256
                return Text(pretendCount.localizedNumber(style: .decimal))
            } else {
                return nil
            }
        }
    }

    enum SidebarItem {
        case popular
        case pinned
        case installed
        case recent

        case category(_ group: AppCategory.Grouping)

        case search(_ term: String)

        /// The persistent identifier for this grouping
        var id: String {
            switch self {
            case .popular:
                return "popular"
            case .pinned:
                return "pinned"
            case .installed:
                return "installed"
            case .recent:
                return "recent"
            case .category(let grouping):
                return "category:" + grouping.rawValue
            case .search(let term):
                return "search:" + term
            }
        }

        var label: TintedLabel {
            switch self {
            case .popular:
                return TintedLabel(title: "Popular", systemName: "star", tint: Color.red)
            case .pinned:
                return TintedLabel(title: "Pinned", systemName: "pin", tint: Color.red)
            case .installed:
                return TintedLabel(title: "Installed", systemName: "internaldrive", tint: Color.green)
            case .recent:
                return TintedLabel(title: "Recent", systemName: "clock", tint: Color.blue)
            case .category(let grouping):
                return grouping.label
            case .search(let term):
                return TintedLabel(title: "Search: \(term)", systemName: "magnifyingglass", tint: Color.gray)
            }
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct GeneralSettingsView: View {
    @AppStorage("showPreview") private var showPreview = true
    @AppStorage("fontSize") private var fontSize = 12.0

    var body: some View {
        Form {
            Toggle("Show Previews", isOn: $showPreview)
            Slider(value: $fontSize, in: 9...96) {
                Text("Font Size (\(fontSize, specifier: "%.0f") pts)", bundle: .module)
            }
        }
        .padding(20)
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct AdvancedSettingsView: View {
    @EnvironmentObject var appManager: AppManager

    func checkButton(_ parts: String...) -> some View {
        EmptyView()
//        Group {
//            Image(systemName: "checkmark.square.fill").aspectRatio(contentMode: .fit).foregroundColor(.green)
//            Image(systemName: "xmark.square.fill").aspectRatio(contentMode: .fit).foregroundColor(.red)
//        }
    }

    var body: some View {
        VStack {
            Form {
                HStack {
                    TextField("Hub", text: appManager.$hubProvider)
                    checkButton(appManager.hubProvider)
                }
                HStack {
                    TextField("Organization", text: appManager.$hubOrg)
                    checkButton(appManager.hubProvider, appManager.hubOrg)
                }
                HStack {
                    TextField("Repository", text: appManager.$hubRepo)
                    checkButton(appManager.hubProvider, appManager.hubOrg, appManager.hubRepo)
                }
                HStack {
                    SecureField("Token", text: appManager.$hubToken)
                }

                Text(atx: "The token is optional, and is only needed for development or advanced usage. One can be created at your [GitHub Personal access token](https://github.com/settings/tokens) setting").multilineTextAlignment(.trailing)

                HelpButton(url: "https://github.com/settings/tokens")
            }
            .padding(20)
        }
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
            //Image(systemName: "questionmark.circle.fill")
            Image(systemName: "questionmark")
        }
        .buttonStyle(.bordered)
    }

}

@available(macOS 12.0, iOS 15.0, *)
public struct AppSettingsView: View {
    public enum Tabs: Hashable {
        case general, advanced
    }

    public var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }
                .tag(Tabs.general)
            AdvancedSettingsView()
                .tabItem { Label("Advanced", systemImage: "star") }
                .tag(Tabs.advanced)
        }
        .padding(20)
        .frame(width: 500)
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
public struct NavigationRootView : View {
    @EnvironmentObject var appManager: AppManager

    public var body: some View {
        NavigationView {
            SidebarView().frame(minWidth: 160) // .controlSize(.large)
            AppSplitView(item: nil)
        }
        .displayingFirstAlert($appManager.errors)
    }
}

@available(macOS 12.0, iOS 15.0, *)
public struct AppSplitView : View {
    var item: AppManager.SidebarItem? = nil

    public var body: some View {
        VSplit {
            AppsListView(item: item)
            DetailView()
        }
    }
}



#if os(iOS)
typealias VSplit = Group
#else
typealias VSplit = VSplitView
#endif

@available(macOS 12.0, iOS 15.0, *)
public struct DetailView : View {
    @FocusedBinding(\.selection) private var selection: Selection??

    public var body: some View {
        VStack {
            switch selection {
            case .app(let app):
                CatalogItemView(info: app)
            case .none:
                Text("No Selection", bundle: .module).font(.title)
            case .some(.none):
                Text("No Selection", bundle: .module).font(.title)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A label that tints its image
@available(macOS 12.0, iOS 15.0, *)
public struct TintedLabel : View {
    public let title: LocalizedStringKey
    public let systemName: StaticString
    public let tint: Color?

    public var body: some View {
        Label(title: { Text(title, bundle: .module) }) {
            if let tint = tint {
                Image(systemName: systemName.description)
                    .foregroundStyle(
                        .linearGradient(colors: [tint, .white], startPoint: .top, endPoint: .bottomTrailing),
                        .linearGradient(colors: [.green, .black], startPoint: .top, endPoint: .bottomTrailing),
                        .linearGradient(colors: [.blue, .black], startPoint: .top, endPoint: .bottomTrailing)
                    )
            } else {
                Image(systemName: systemName.description)
            }
        }
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

        @available(macOS 12.0, iOS 15.0, *)
        public var label: TintedLabel {
            switch self {
            case .create:
                return TintedLabel(title: "Arts & Crafts", systemName: "puzzlepiece", tint: Color.cyan) // "paintpalette" is nicer, but the multi-color is currently messed up when used with gradient foregroundStyle so we nil the tint instead of using Color.cyan
            case .research:
                return TintedLabel(title: "Knowledge", systemName: "book", tint: Color.green)
            case .communicate:
                return TintedLabel(title: "Communication", systemName: "envelope", tint: Color.pink)
            case .entertain:
                return TintedLabel(title: "Entertainment", systemName: "sparkles.tv", tint: Color.teal)
            case .live:
                return TintedLabel(title: "Health & Lifestyle", systemName: "house", tint: Color.mint)
            case .game:
                return TintedLabel(title: "Diversion", systemName: "circle.hexagongrid", tint: Color.yellow)
            case .work:
                return TintedLabel(title: "Work", systemName: "briefcase", tint: Color.brown)
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

@available(macOS 12.0, iOS 15.0, *)
struct SidebarView: View {
    @EnvironmentObject var appManager: AppManager

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
            Section("Apps") {
                item(.popular).keyboardShortcut("1")
                item(.recent).keyboardShortcut("2")
                item(.pinned).keyboardShortcut("3")
                item(.installed).keyboardShortcut("4")
            }

            Section("Categories") {
                ForEach(AppCategory.Grouping.allCases, id: \.self) { grouping in
                    item(.category(grouping)).keyboardShortcut(shortCut(for: grouping, offset: 5))
                }
            }

//            Section("Searches") {
//                item(.search("Search 1"))
//                item(.search("Search 2"))
//                item(.search("Search 3"))
//            }
        }
        //.symbolVariant(.none)
        //.symbolRenderingMode(.hierarchical)
        //.symbolVariant(.circle) // note that these can be stacked
        .symbolVariant(.fill)
        .symbolRenderingMode(.multicolor)
        .listStyle(.automatic)
        .toolbar(id: "SidebarView") {
            tool(.popular)
            tool(.recent)
            tool(.pinned)
            tool(.installed)

            tool(.category(.entertain))
            tool(.category(.research))
            tool(.category(.create))
            tool(.category(.game))
            tool(.category(.live))
            tool(.category(.work))
        }
    }

    func item(_ item: AppManager.SidebarItem) -> some View {
        NavigationLink(destination: AppSplitView(item: item)) {
            item.label
                .badge(appManager.badgeCount(for: item))
        }
    }

    func tool(_ item: AppManager.SidebarItem) -> some CustomizableToolbarContent {
        ToolbarItem(id: item.id, placement: .automatic, showsByDefault: false) {
            Button(action: {
                selectItem(item)
            }, label: {
                item.label
                    //.symbolVariant(.fill)
                    .symbolRenderingMode(.multicolor)
            })
        }
    }

    func selectItem(_ item: AppManager.SidebarItem) {
        print(wip("SELECTED"), item)
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


@available(macOS 12.0, iOS 15.0, *)
struct DisplayModePicker: View {
    @Binding var mode: AppsListView.ViewMode

    var body: some View {
        Picker("Display Mode", selection: $mode) {
            ForEach(AppsListView.ViewMode.allCases) { viewMode in
                viewMode.label
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

@available(macOS 12.0, iOS 15.0, *)
extension AppsListView.ViewMode {
    var labelContent: (name: LocalizedStringKey, systemImage: String) {
        switch self {
        case .table:
            return ("Table", "tablecells")
        case .gallery:
            return ("Gallery", "square.grid.3x2.fill")
        }
    }

    var label: some View {
        Label(labelContent.name, systemImage: labelContent.systemImage)
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct AppsListView: View {
    @EnvironmentObject var appManager: AppManager
    @SceneStorage("viewMode") private var mode: ViewMode = .table

    /// Whether to display the items as a table or gallery
    enum ViewMode: String, CaseIterable, Identifiable {
        var id: Self { self }
        case table
        case gallery
    }

    var item: AppManager.SidebarItem? = nil

    var body: some View {
        Group {
            #if os(macOS)
            switch (mode, item) {
            //case (.table, .pinned): SimpleTableView()
            //case (.table, .recent): ActionsTableView()
            //case (.table, .installed): ActionsTableView()
            case (.table, _): ReleasesTableView()
            case (_, _): ReleasesTableView()
            }
            #else
            wip(EmptyView())
            #endif
        }
        // .padding()
        // .focusedSceneValue(\.selection, $selection)
        .toolbar {
            ToolbarItem(id: "DisplayModePicker", placement: .automatic, showsByDefault: true) {
                DisplayModePicker(mode: $mode)
            }
        }
        .navigationTitle(item?.label.title ?? "Apps")
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

/// If true, show simulated information
let pretendMode = false // wip(true) // pretend mode is for pretend

