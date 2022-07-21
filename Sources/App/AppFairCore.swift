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
import FairExpo
import Combine
import TabularData

/// A source of apps.
public struct AppSource: RawRepresentable, Hashable {
    public let rawValue: String

    /// The Homebrew Casks catalog from [formulae.brew.sh](https://formulae.brew.sh)
    public static let homebrew = Self(rawValue: "homebrew")

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension AppSource : Identifiable {
    /// The identifier for this ``AppSource``, which is the underlying identifier (typically the URL) that was used to create the catalog
    public var id: Self { self }
}

/// A structure representing an ``FairApp.AppCatalogItem`` with optional ``CaskItem`` metadata.
struct AppInfo : Identifiable, Equatable {
    /// The underlying source for this info
    var source: AppSource
    
    /// The catalog item metadata
    var app: AppCatalogItem

    /// The associated homebrew cask
    var cask: CaskItem?

    /// The bundle ID of the selected app (e.g., "app.App-Name")
    var id: AppCatalogItem.ID {
        app.id
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
            return app.homepage
        }
    }

    /// The categories as should be displayed in the UI; this will collapes sub-groups (i.e., game categories) into their parent groups.
    var displayCategories: [AppCategory] {
        app.categories?.filter({ $0.parentCategory == nil }) ?? []
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

/// A type wrapper for a bundle identifier string
public struct BundleIdentifier: Pure, RawRepresentable, Comparable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public init(rawValue: String) { self.rawValue = rawValue }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// TODO: potentially separate these into separate types
// typealias AppIdentifier = XOr<BundleIdentifier>.Or<CaskIdentifier>

extension AppCatalogItem : Identifiable {
    public var id: AppIdentifier { BundleIdentifier(bundleIdentifier) }
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

@available(macOS 12.0, iOS 15.0, *)
struct AppFairCommands: Commands {
    @FocusedBinding(\.selection) private var selection: AppInfo??
    @FocusedBinding(\.sidebarSelection) private var sidebarSelection: SourceSelection??

    //    @FocusedBinding(\.reloadCommand) private var reloadCommand: (() async -> ())?

    @ObservedObject var fairManager: FairManager

    var body: some Commands {
        CommandMenu(Text("Sources", bundle: .module, comment: "menu title for app source actions")) {
            Text("Refresh Catalogs", bundle: .module, comment: "menu title for refreshing the app catalog")
                .button(action: { reloadAll() })
                .keyboardShortcut("R")

//            Text("Add Catalog", bundle: .module, comment: "menu title for adding an app catalog")
//                .button(action: { addCatalog() })
//                .keyboardShortcut("N")


            Divider()

            appInventorySelectionCommands()

        }
    }

    func appInventorySelectionCommands() -> some View {
        ForEach(enumerated: fairManager.appInventories) { index, inv in
            Section {
                ForEach(enumerated: inv.supportedSidebars) { itemIndex, section in
                    let key: (Int) -> KeyEquivalent? = { itemIndex in
                        switch itemIndex {
                        case 0: return "1"
                        case 1: return "2"
                        case 2: return "3"
                        case 3: return "4"
                        case 4: return "5"
                        case 5: return "6"
                        case 6: return "7"
                        case 7: return "8"
                        case 8: return "9"
                        case 9: return "0"
                        default: return nil
                        }
                    }

                    if let shortcut = (index > 1 ? nil : key(itemIndex).flatMap { KeyboardShortcut($0, modifiers: index == 0 ? [.command] : [.option, .command]) }) {
                        sidebarButton(SourceSelection(source: inv.source, section: section)).keyboardShortcut(shortcut)
                    } else {
                        sidebarButton(SourceSelection(source: inv.source, section: section))
                    }
                }
            } header: {
                inv.title.text()
            }
        }
    }

    func sidebarButton(_ selection: SourceSelection) -> some View {
        Button {
            sidebarSelection = selection
        } label: {
            fairManager.sourceInfo(for: selection)?.tintedLabel(monochrome: true).title
        }
    }

    func sourceInfo(for selection: SourceSelection) -> AppSourceInfo? {
        fairManager.sourceInfo(for: selection)
    }

    func reloadAll() {
        Task {
            fairManager.clearCaches() // also flush caches
            await fairManager.refresh(reloadFromSource: false)
        }
    }
}

struct CopyAppURLCommand : View {
    @EnvironmentObject var fairManager: FairManager
    @FocusedBinding(\.selection) private var selection: AppInfo??
    @FocusedBinding(\.sidebarSelection) private var sidebarSelection: SourceSelection??

    var body: some View {
        Text("Copy App URL", bundle: .module, comment: "menu title for command")
            .button(action: commandSelected)
            .keyboardShortcut("C", modifiers: [.command, .shift])
            //.disabled(sidebarSelection??.app == nil)
    }

    func commandSelected() {
        dbg()
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

extension Collection where Element == Text {
    /// Joins multiple ``Text`` elements together with the given separator ``Text``.
    ///
    /// - SeeAlso: ``Array<String>.joined``
    public func joined(separator: Text) -> Text {
        if let first = self.first {
            return self.dropFirst().reduce(first, { $0 + separator + $1 })
        } else {
            return Text(verbatim: "")
        }
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
                        // have a text edit will the full descripton of the error
                        TextEditor(text: .constant(String(describing: underlyingError)))
                            //.textSelection(.disabled)
                            .font(Font.body.monospaced())
                            //.focusable(false)
                            .frame(height: 200)
                    } label: {
                        Text("More Info", bundle: .module, comment: "error dialog disclosure button title for showing more information")
                    }
                }

                Button {
                    errorBinding.wrappedValue.removeFirst()
                } label: {
                    Text("OK", bundle: .module, comment: "error dialog button to dismiss the error").padding()
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
    /// Text("Reload", bundle: .module, comment: "help text")
    ///     .label(symbol: "arrow.triangle.2.circlepath.circle")
    ///     .button(command: reloadCommand)
    /// ```
    ///
    /// The button will be disabled when the action is `nil`.
    func button(priority: TaskPriority? = nil, command: (() async -> ())?) -> some View {
        button {
            Task(priority: priority) {
                await command?()
            }
        }
        .disabled(command == nil)
    }
}

@available(macOS 12.0, iOS 15.0, *)
public struct RootView : View, Equatable {
    public var body: some View {
        NavigationRootView()
    }
}

/// The selection in the sidebar, consisting of an ``AppSource`` and a ``SidebarSection``
struct SourceSelection : Hashable {
    let source: AppSource
    let section: SidebarSection
}

/// A standard group for a sidebar representation
enum SidebarSection : Hashable {
    case top
    case updated
    case installed
    case sponsorable
    case recent
    case category(_ category: AppCategory)

    /// The persistent identifier for this grouping
    var id: String {
        switch self {
        case .top:
            return "top"
        case .updated:
            return "updated"
        case .installed:
            return "installed"
        case .sponsorable:
            return "sponsorable"
        case .recent:
            return "recent"
        case .category(let category):
            return "category:" + category.rawValue
        }
    }

    /// True indicates that this sidebar specifies to filter for locally-installed packages
    var isLocalFilter: Bool {
        switch self {
        case .updated:
            return true
        case .installed:
            return true
        case .top:
            return false
        case .sponsorable:
            return false
        case .recent:
            return true
        case .category:
            return false
        }
    }
}


@available(macOS 12.0, iOS 15.0, *)
struct NavigationRootView : View {
    @EnvironmentObject var fairManager: FairManager
    @Environment(\.scenePhase) var scenePhase

    //@FocusedBinding(\.reloadCommand) private var reloadCommand: (() async -> ())?

    @State var selection: AppInfo.ID? = nil
    /// Indication that the selection should be scrolled to
    @State var scrollToSelection: Bool = false

    @State var sidebarSelection: SourceSelection? = nil

    //@SceneStorage("displayMode")
    @State var displayMode: TriptychOrient = TriptychOrient.allCases.first!
    
    @AppStorage("iconBadge") private var iconBadge = true
    //@SceneStorage("source") var source: AppSource = AppSource.allCases.first!

    @State var searchText: String = ""

    public var body: some View {
        triptychView
            .displayingFirstAlert($fairManager.errors)
            .toolbar(id: "NavToolbar") {
                //                ToolbarItem(placement: .navigation) {
                //                    Button(action: toggleSidebar) {
                //                        FairSymbol.sidebar_left.image
                //                    })
                //                }

                ToolbarItem(id: "AppPrivacy", placement: .automatic, showsByDefault: true) {
                    fairManager.launchPrivacyButton()
                }

                ToolbarItem(id: "ReloadButton", placement: .automatic, showsByDefault: true) {
                    Text("Reload", bundle: .module, comment: "refresh catalog toolbar button title")
                        .label(image: FairSymbol.arrow_triangle_2_circlepath.symbolRenderingMode(.hierarchical).foregroundStyle(Color.teal, Color.yellow, Color.blue))
                        .button {
                            await fairManager.refresh(reloadFromSource: false) // TODO: true when option or control key is down?
                        }
                        .hoverSymbol(activeVariant: .fill)
                        .help(Text("Refresh the app catalogs", bundle: .module, comment: "refresh catalog toolbar button tooltip"))
                }


                ToolbarItem(id: "DisplayModePicker", placement: .automatic, showsByDefault: false) {
                    DisplayModePicker(mode: $displayMode)
                }
            }
            .task(priority: .medium) {
                dbg("refreshing catalogs")
                await fairManager.refresh(reloadFromSource: false)
            }
            .task(priority: .low) {
                do {
                    try await fairManager.homeBrewInv?.installHomebrew(force: true, fromLocalOnly: true, retainCasks: true)
                } catch {
                    dbg("error unpacking homebrew in local cache:", error)
                }
            }
            .onChange(of: scenePhase) { phase in
                if phase == .background || phase == .inactive {
                    fairManager.inactivate()
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
                if !searchText.isEmpty && selection?.section != .top { // only clear when switching away from the "popular" tab
                    searchText = "" // clear search whenever the sidebar selection changes
                }
            }
            .onChange(of: fairManager.enableUserSources) { enable in
                fairManager.updateUserSources(enable: enable)
            }
            .handlesExternalEvents(preferring: [], allowing: ["*"]) // re-use this window to open external URLs
            .onOpenURL(perform: handleURL)
    }

    var sidebarSelectionBinding: Binding<SourceSelection?> {
        //return .constant(.init(source: .fairapps, section: .updated))
        return $sidebarSelection
        //            .mapSetter { oldValue, newValue in
        //            // clear search whenever the sidebar selection changes
        //            if newValue?.section != .top && !searchText.isEmpty {
        ////                self.searchText = ""
        //            }
        //            return newValue
        //        }

    }

    /// The currently selected source for the sidebar
    var sidebarSource: AppSource? {
        return sidebarSelection?.source
    }

    public var triptychView : some View {
        TriptychView(orient: $displayMode) {
            SidebarView(selection: $selection
                        //                .mapSetter(action: { dump($1, name: wip("changing selection")) })
                        , scrollToSelection: $scrollToSelection, sidebarSelection: sidebarSelectionBinding, displayMode: $displayMode, searchText: $searchText)
            .focusedSceneValue(\.sidebarSelection, sidebarSelectionBinding)
        } list: {
            if let sidebarSource = sidebarSource {
                AppsListView(source: sidebarSource, sidebarSelection: sidebarSelection, selection: $selection, scrollToSelection: $scrollToSelection, searchTextSource: $searchText)
            } else {
                EmptyView() // TODO: better placeholder view for un-selected sidebar section
            }
        } table: {
#if os(macOS)
            if let sidebarSource = sidebarSource {
                AppsTableView(source: sidebarSource, selection: $selection, sidebarSelection: sidebarSelection, searchText: $searchText)
            } else {
                EmptyView()
            }
#endif
        } content: {
            AppDetailView(sidebarSelection: sidebarSelectionBinding)
        }
        // warning: this spikes CPU usage when idle
        //        .focusedSceneValue(\.reloadCommand, .constant({
        //            await fairAppInv.fetchApps(cache: .reloadIgnoringLocalAndRemoteCacheData)
        //        }))
    }
}

extension NavigationRootView {

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

            // by default, an app source catalog will reference the primary fair catalog
            var catalogURL = appfairCatalogURLMacOS

            if let paramMap = url.queryParameters {
                dbg("URL params:", paramMap)
                if let catalogString = paramMap["catalog"],
                   let catalogString = catalogString,
                    let url = URL(string: "https://" + catalogString) {
                    // TODO: prompt to add catalog URL if it is not present in the sources list
                    catalogURL = url
                    dbg("parsing cagalog URL:", catalogURL.absoluteString)
                }
            }

            let isCask = path.first == "homebrew"
            let searchID = path.joined(separator: isCask ? "/" : ".") // "homebrew/cask/iterm2" vs. "app.Tidal-Zone"

            // handle: https://appfair.app/fair?app=Tune-Out&catalog=appfair.net/fairapps-ios.json

            let bundleID = BundleIdentifier(searchID)

            // random crashes seem to happen without dispatching to main
            self.searchText = bundleID.rawValue // needed to cause the section to appear

            // switch to correct catalog by matching the source when opening from URL
            let source = AppSource(rawValue: catalogURL.absoluteString)
            self.sidebarSelection = SourceSelection(source: isCask ? .homebrew : source, section: .top)

            self.selection = bundleID
            dbg("selected app ID", self.selection)
            // DispatchQueue.main.async {
            //     self.scrollToSelection = true // if the catalog section is offscreen, then the selection will fail, so we need to also refine the current search to the bundle id
            // }
        }
    }
}

extension URL {
    /// Parses the URL for query parameters
    var queryParameters: [String: String?]? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems?.dictionary(keyedBy: \.name).mapValues(\.value)
    }
}

#if os(macOS)
@available(macOS 12.0, iOS 15.0, *)
public struct AppTableDetailSplitView : View {
    let source: AppSource
    @Binding var selection: AppInfo.ID?
    @Binding var searchText: String
    @Binding var sidebarSelection: SourceSelection?

    @ViewBuilder public var body: some View {
        VSplitView {
            AppsTableView(source: source, selection: $selection, sidebarSelection: sidebarSelection, searchText: $searchText)
                .frame(minHeight: 150)
            AppDetailView(sidebarSelection: $sidebarSelection)
                .layoutPriority(1.0)
        }
    }
}
#endif

@available(macOS 12.0, iOS 15.0, *)
public struct AppDetailView : View {
    @Binding var sidebarSelection: SourceSelection?
    @FocusedBinding(\.selection) private var selection: AppInfo??
    @EnvironmentObject var fairManager: FairManager

    @ViewBuilder public var body: some View {
        if let source = sidebarSelection?.source,
           let selection = selection,
           let app = selection {
            CatalogItemView(info: app, source: source)
        } else {
            emptySelectionView()
        }
    }

    @ViewBuilder func emptySelectionView() -> some View {
        VStack {
            if let sidebarSelection = sidebarSelection {
                fairManager.sourceOverviewView(selection: sidebarSelection, showText: true, showFooter: true)
                    .font(.body)
                Spacer()

//                if !showOverviewText {
//                    Text("No Selection", bundle: .module, comment: "placeholder text for detail panel indicating there is no app currently selected")
//                        .font(Font.title)
//                        .foregroundColor(Color.secondary)
//                    Spacer()
//                }
            } else {
                ScrollView {
                    catalogsCardsView()
                }
            }
        }
    }

    @ViewBuilder func catalogsCardsView() -> some View {
        let selection = { SourceSelection(source: $0, section: .top) }
        //let maxSourceSummary = 3 // only display the first three catalog summaries on the front page
        let sources = fairManager.appSources // .prefix(maxSourceSummary)

        LazyVGrid(columns: [GridItem(.flexible(minimum: 250), alignment: .top), GridItem(.flexible(minimum: 250), alignment: .top)], alignment: .center, pinnedViews: [.sectionHeaders]) {
            Section {
                ForEach(enumerated: sources) { _, source in
                    VStack {
                        let sel = selection(source)
                        fairManager.sourceOverviewView(selection: sel, showText: true, showFooter: false)
                            //.frame(height: 450)
                        Spacer()
                        browseButton(sel)
                        ForEach(enumerated: fairManager.sourceInfo(for: sel)?.footerText ?? []) { _, footerText in
                            footerText
                        }
                        .font(.footnote)
                    }
                    .frame(alignment: .top)

                }
            } header: {
                VStack {
                    Text("The App Fair", bundle: .module, comment: "header text for detail screen with no selection")
                        .font(Font.system(size: 40, weight: .regular, design: .rounded).lowercaseSmallCaps())
                    Text("Community App Sources", bundle: .module, comment: "header sub-text for detail screen with no selection")
                        .font(Font.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Material.thin)
            }
        }
    }

    func browseButton(_ sidebarSelection: SourceSelection) -> some View {
        Button {
            withAnimation {
                self.sidebarSelection = sidebarSelection
                self.selection = .some(.none)
            }
        } label: {
            let title = fairManager.sourceInfo(for: sidebarSelection)?.fullTitle ?? Text(verbatim: "")
            Text("Browse \(title)", bundle: .module, comment: "format pattern for the label of the button at the bottom of the category info screen")
        }
    }

}

extension View {
    /// The custom tinting style for the App Fair
    @available(macOS 12.0, iOS 15.0, *)
    @ViewBuilder func fairTint(simple: Bool, color: Color) -> some View {
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

struct CategoryAppInfo : AppSourceInfo {
    let category: AppCategory

    func tintedLabel(monochrome: Bool) -> TintedLabel {
        category.tintedLabel(monochrome: monochrome)
    }

    /// Subtitle text for this source
    var fullTitle: Text {
        Text("Category: \(category.text)", bundle: .module, comment: "app category info: title pattern")
    }

    /// A textual description of this source
    var overviewText: [Text] {
        []
        // Text(wip("XXX"), bundle: .module, comment: "app category info: overview text")
    }

    var footerText: [Text] {
        []
        // Text(wip("XXX"), bundle: .module, comment: "homebrew recent apps info: overview text")
    }

    /// A list of the features of this source, which will be displayed as a bulleted list
    var featureInfo: [(FairSymbol, Text)] {
        []
    }
}

extension AppCategory : Identifiable {
    public var id: Self { self }
}

@available(macOS 12.0, iOS 15.0, *)
extension FocusedValues {
    private struct FocusedSelection: FocusedValueKey {
        typealias Value = Binding<AppInfo?>
    }

    var selection: Binding<AppInfo?>? {
        get { self[FocusedSelection.self] }
        set { self[FocusedSelection.self] = newValue }
    }

    private struct FocusedSidebarSelection: FocusedValueKey {
        typealias Value = Binding<SourceSelection?>
    }

    var sidebarSelection: Binding<SourceSelection?>? {
        get { self[FocusedSidebarSelection.self] }
        set { self[FocusedSidebarSelection.self] = newValue }
    }

//    private struct FocusedReloadCommand: FocusedValueKey {
//        typealias Value = Binding<() async -> ()>
//    }
//
//    var reloadCommand: Binding<() async -> ()>? {
//        get { self[FocusedReloadCommand.self] }
//        set { self[FocusedReloadCommand.self] = newValue }
//    }
}


/// Whether to remember the response to a prompt or not;
enum PromptSuppression : Int, CaseIterable {
    /// The user has not specified whether to remember the response
    case unset
    /// The user specified that the the response should always the confirmation response
    case confirmation
    /// The user specified that the the response should always be the destructive response
    case destructive
}

extension ObservableObject {
    /// Issues a prompt with the given parameters, returning whether the user selected OK or Cancel
    @MainActor func prompt(_ style: NSAlert.Style = .informational, window sheetWindow: NSWindow? = nil, messageText: String, informativeText: String? = nil, accept: String = NSLocalizedString("OK", bundle: .module, comment: "default button title for prompt"), refuse: String = NSLocalizedString("Cancel", bundle: .module, comment: "cancel button title for prompt"), suppressionTitle: String? = nil, suppressionKey: Binding<PromptSuppression>? = nil) async -> Bool {

        let window = sheetWindow ?? UXApplication.shared.currentEvent?.window ?? NSApp.keyWindow ?? NSApp.mainWindow

        if let suppressionKey = suppressionKey {
            switch suppressionKey.wrappedValue {
            case .confirmation: return true
            case .destructive: return false
            case .unset: break // show prompt
            }
        }

        let alert = NSAlert()
        alert.alertStyle = style
        alert.messageText = messageText
        if let informativeText = informativeText {
            alert.informativeText = informativeText
        }
        alert.addButton(withTitle: accept)
        alert.addButton(withTitle: refuse)

        if let suppressionTitle = suppressionTitle {
            alert.suppressionButton?.title = suppressionTitle
        }
        alert.showsSuppressionButton = suppressionKey != nil

        let response: NSApplication.ModalResponse
        if let window = window {
            response = await alert.beginSheetModal(for: window)
        } else {
            response = alert.runModal() // note that this tends to crash even when called from the main thread with: Assertion failure in -[NSApplication _commonBeginModalSessionForWindow:relativeToWindow:modalDelegate:didEndSelector:contextInfo:]
        }

        // remember the response if we have prompted to do so
        if let suppressionKey = suppressionKey, alert.suppressionButton?.state == .on {
            switch response {
            case .alertFirstButtonReturn: suppressionKey.wrappedValue = .confirmation
            case .alertSecondButtonReturn: suppressionKey.wrappedValue = .destructive
            default: break
            }
        }

        return response == .alertFirstButtonReturn
    }
}


#if os(macOS)
extension NSUserScriptTask {
    /// Performs the given shell command and returns the output via an `NSAppleScript` operation
    /// - Parameters:
    ///   - command: the command to execute
    ///   - name: the name of the script command to run
    ///   - async: whether to fork async using `NSUserAppleScriptTask` as opposed to synchronously with `NSAppleScript`
    ///   - admin: whether to execute the script `with administrator privileges`
    /// - Returns: the string contents of the response
    public static func fork(command: String, name: String = "App Fair Command", admin: Bool = false) async throws -> String? {
        let withAdmin = admin ? " with administrator privileges" : ""

        let cmd = "do shell script \"\(command)\"" + withAdmin

        let scriptURL = URL.tmpdir
            .appendingPathComponent("scriptcmd-" + UUID().uuidString)
            .appendingPathComponent(name + ".scpt") // needed or else error that the script: “couldn’t be opened because it isn’t in the correct format”
        try FileManager.default.createDirectory(at: scriptURL.deletingLastPathComponent(), withIntermediateDirectories: true)

        try cmd.write(to: scriptURL, atomically: true, encoding: .utf8)
        dbg("running NSUserAppleScriptTask in:", scriptURL.path, "command:", cmd)
        let task = try NSUserAppleScriptTask(url: scriptURL)
        let output = try await task.execute(withAppleEvent: nil)
        dbg("successfully executed script:", command)
        return output.stringValue
    }
}
#endif

extension Text {
    /// Converts this `Text` into a label with a yellow exclamation warning.
    func warningLabel() -> some View {
        self.label(image: FairSymbol.exclamationmark_triangle_fill.symbolRenderingMode(.multicolor))
    }
}

// MARK: Parochial (package-local) Utilities

/// Work-in-Progress marker
@available(*, deprecated, message: "work in progress")
internal func wip<T>(_ value: T) -> T { value }

/// Work-in-Progress marker for ipa installation
///
/// - TODO: @available(*, deprecated, message: "work in progress")
internal func wipipa<T>(_ value: T) -> T { value }

/// Intercept `LocalizedStringKey` constructor and forward it to ``SwiftUI.Text/init(_:bundle)``
/// Otherwise it will default to the main bundle's strings, which is always empty.
@available(*, deprecated, message: "use bundle: .module, comment: arguments literally")
@usableFromInline internal func Text(_ string: LocalizedStringKey, comment: StaticString? = nil) -> SwiftUI.Text {
    SwiftUI.Text(string, bundle: .module, comment: comment)
}
