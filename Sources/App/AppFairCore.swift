import FairApp
import SwiftUI

struct AppInfo : Identifiable, Equatable {
    var release: AppCatalogItem
    var installedPlist: Plist? = nil

    /// The bundle ID of the selected app (e.g., "app.App-Name")
    var id: AppCatalogItem.ID {
        release.id
    }

    /// The released version of this app
    var releasedVersion: AppVersion? {
        release.version.flatMap({ AppVersion(string: $0, prerelease: release.beta == true) })
    }

    /// The installed version of this app, which will always be indicated as a non-prerelease
    var installedVersion: AppVersion? {
        installedVersionString.flatMap({ AppVersion(string: $0, prerelease: false) })
    }

    /// The installed version of this app
    var installedVersionString: String? {
        installedPlist?.versionString
    }

    /// The app is updated if its installed version is less than the released version
    var appUpdated: Bool {
        installedVersion != nil && (installedVersion ?? .max) < (releasedVersion ?? .min)
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


extension AppCatalogItem : Identifiable {
    public var id: String { bundleIdentifier }

    /// The hyphenated form of this app's name
    var appNameHyphenated: String {
        self.name.rehyphenated()
    }

    /// Returns the URL to this app's home page
    var baseURL: URL! {
        URL(string: "https://github.com/\(appNameHyphenated)/App")
    }

    /// The e-mail address for contacting the developer
    var developerEmail: String {
        developerName // TODO: parse out
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

    var developerURL: URL! {
        queryURL(type: "users", term: developerEmail)
    }

    var fairsealURL: URL! {
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
                        dbg("search toolbar:", toolbar, toolbar.visibleItems?.compactMap(\.view).flatMap(\.subviews))
                        if let textField = toolbar.visibleItems?.compactMap(\.view).flatMap(\.subviews).compactMap({ $0 as? UXTextField }).first {
                            window.makeFirstResponder(textField)
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

        CommandMenu(Text("Fair")) {
            Text("Reload Apps")
                .button {
                    await appManager.fetchApps(cache: .reloadIgnoringLocalAndRemoteCacheData)
//                    guard let cmd = reloadCommand else {
//                        dbg("no reload command")
//                        return
//                    }
//                    let start = CFAbsoluteTimeGetCurrent()
//                    Task {
//                        await cmd()
//                        let end = CFAbsoluteTimeGetCurrent()
//                        dbg("reloaded:", end - start)
//                    }
                }
                .keyboardShortcut("R")
//                .disabled(reloadCommand == nil)
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

    func activateFind() {
        dbg("### ", #function) // TODO: is there a way to focus the search field in the toolbar?
    }

    func updateCount() -> Int {
        appInfoItems(includePrereleases: showPreReleases).filter { item in
            item.appUpdated
        }
        .count
    }

    func badgeCount(for item: SidebarItem) -> Text? {
        switch item {
        case .popular:
            return nil // Text(123.localizedNumber(style: .decimal))
        case .recent:
            return nil // Text(11.localizedNumber(style: .decimal))
        case .updated:
            return Text(updateCount().localizedNumber(style: .decimal))
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

    enum SidebarItem : Hashable {
        case popular
        case updated
        case installed
        case recent
        case category(_ group: AppCategory.Grouping)

        /// The persistent identifier for this grouping
        var id: String {
            switch self {
            case .popular:
                return "popular"
            case .updated:
                return "updated"
            case .installed:
                return "installed"
            case .recent:
                return "recent"
            case .category(let grouping):
                return "category:" + grouping.rawValue
            }
        }

        var text: Text {
            switch self {
            case .popular:
                return Text("Popular", bundle:. module)
            case .updated:
                return Text("Updated", bundle:. module)
            case .installed:
                return Text("Installed", bundle:. module)
            case .recent:
                return Text("Recent", bundle:. module)
            case .category(let grouping):
                return grouping.text
            }
        }

        var label: TintedLabel {
            switch self {
            case .popular:
                return TintedLabel(title: self.text, systemName: "star", tint: Color.red)
            case .updated:
                return TintedLabel(title: self.text, systemName: "pin", tint: Color.red)
            case .installed:
                return TintedLabel(title: self.text, systemName: "internaldrive", tint: Color.green)
            case .recent:
                return TintedLabel(title: self.text, systemName: "clock", tint: Color.blue)
            case .category(let grouping):
                return grouping.tintedLabel
            }
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
struct GeneralSettingsView: View {
    @AppStorage("showPreReleases") private var showPreReleases = false
//    @AppStorage("controlSize") private var controlSize = 3.0
    @AppStorage("themeStyle") private var themeStyle = ThemeStyle.system
    @AppStorage("riskFilter") private var riskFilter = AppRisk.risky
    @AppStorage("iconBadge") private var iconBadge = true

    var body: some View {
        Form {
            ThemeStylePicker(style: $themeStyle)

//            Slider(value: $controlSize, in: 1...5, step: 1) {
//                Text("Interface Scale:")
//            }

            Divider()

            HStack(alignment: .firstTextBaseline) {
                AppRiskPicker(risk: $riskFilter)
                riskFilter.riskSummaryText(bold: true)
                    .textSelection(.enabled)
                    .font(.body)
                    .frame(height: 150, alignment: .top)
            }

            Toggle(isOn: $iconBadge) {
                Text("Badge App Icon with update count")
            }
                .help(Text("Show the number of updates that are available to install."))


            Toggle(isOn: $showPreReleases) {
                Text("Show Pre-Releases")
            }
                .help(Text("Display releases that are not yet production-ready according to the developer's standards."))

            Text("Pre-releases are experimental versions of software that are less tested than stable versions. They are generally released to garner user feedback and assistance, and so should only be installed by those willing experiment.")
                .font(.body)
                .multilineTextAlignment(.leading)
                .frame(height: 200, alignment: .top)

        }
        .padding(20)
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

@available(macOS 12.0, iOS 15.0, *)
struct AppRiskPicker: View {
    @Binding var risk: AppRisk

    var body: some View {
        Picker(selection: $risk) {
            ForEach(AppRisk.allCases) { appRisk in
                appRisk.riskLabel()
            }
        } label: {
            Text("Risk Exposure:")
        }
        .radioPickerStyle()
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
            //FairSymbol.questionmark_circle_fill
            FairSymbol.questionmark
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
                .tabItem {
                    Label("General", systemImage: "gear")
                        .symbolVariant(.fill)
                }
                .tag(Tabs.general)
            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "star")
                        .symbolVariant(.fill)
                }
                .tag(Tabs.advanced)
        }
        .padding(20)
        .frame(width: 600)
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
public struct NavigationRootView : View {
    @EnvironmentObject var appManager: AppManager
    @FocusedBinding(\.reloadCommand) private var reloadCommand: (() async -> ())?
    @State var selection: AppInfo.ID? = nil
    @State var category: AppManager.SidebarItem? = .popular
    @SceneStorage("displayMode") var displayMode: TriptychOrient = TriptychOrient.allCases.first!
    @AppStorage("iconBadge") private var iconBadge = true

    public var body: some View {
        triptychView
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
                ToolbarItem(id: "DisplayModePicker", placement: .automatic, showsByDefault: true) {
                    DisplayModePicker(mode: $displayMode)
                }
            }
            .task {
                dbg("fetching app catalog")
                await appManager.fetchApps()
            }
            .onChange(of: appManager.updateCount()) { updateCount in
                if iconBadge == true {
                    UXApplication.shared.setBadge(updateCount)
                }
            }
            .onChange(of: iconBadge) { iconBadge in
                // update the badge when the setting changes
                UXApplication.shared.setBadge(iconBadge ? appManager.updateCount() : 0)
            }
            .onChange(of: selection) { newSelection in
                dbg("selected:", newSelection)
            }
            .onOpenURL { url in
                let components = url.pathComponents
                dbg("handling app URL", url.absoluteString, "scheme:", url.scheme, "action:", components)
                // e.g., appfair://app/app.App-Name
                // e.g., appfair://update/app.App-Name
                // e.g., appfair:app.App-Name
                // e.g., appfair:/app/App-Name
                if let scheme = url.scheme, scheme == "appfair" {
                    let appName = url.lastPathComponent
                    // prefix the app-id with the app name
                    let appID = appName.hasPrefix("app.") ? appName : ("app." + appName)
                    self.selection = appID
                    dbg("selected app ID", self.selection)
                }
            }
    }

    public var triptychView : some View {
        TriptychView(orient: $displayMode) {
            SidebarView(selection: $selection, category: $category, displayMode: $displayMode)
        } list: {
            AppsListView(selection: $selection, category: $category)
        } table: {
            #if os(macOS)
            AppsTableView(selection: $selection, category: $category)
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
    @Binding var selection: AppInfo.ID?
    @Binding var category: AppManager.SidebarItem?

    @ViewBuilder public var body: some View {
        VSplitView {
            AppsTableView(selection: $selection, category: $category)
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
    public let systemName: StaticString
    public let tint: Color?

    public var body: some View {
        Label(title: { title }) {
            if let tint = tint {
                Image(systemName: systemName.description)
                    .fairTint(simple: false, color: tint, scheme: colorScheme)
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
        public var symbolName: StaticString {
            switch self {
            case .create: return "puzzlepiece"
            case .research: return "book"
            case .communicate: return "envelope"
            case .entertain: return "sparkles.tv"
            case .live: return "house"
            case .game: return "circle.hexagongrid"
            case .work: return "briefcase"
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

@available(macOS 12.0, iOS 15.0, *)
struct SidebarView: View {
    @EnvironmentObject var appManager: AppManager
    @Binding var selection: AppInfo.ID?
    @Binding var category: AppManager.SidebarItem?
    @Binding var displayMode: TriptychOrient

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
                item(.installed).keyboardShortcut("3")
                item(.updated).keyboardShortcut("4")
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

    func item(_ item: AppManager.SidebarItem) -> some View {
        NavigationLink(tag: item, selection: $category, destination: {
            navigationDestinationView(item: item)
                .navigationTitle(category?.label.title ?? Text("Apps"))
        }, label: {
            item.label
                .badge(appManager.badgeCount(for: item))
        })
    }

    @ViewBuilder func navigationDestinationView(item: AppManager.SidebarItem) -> some View {
        switch displayMode {
        case .list:
            AppsListView(selection: $selection, category: $category)
        #if os(macOS)
        case .table:
            AppTableDetailSplitView(selection: $selection, category: $category)
        #endif
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

