/**
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 The full text of the GNU Affero General Public License can be
 found in the COPYING.txt file or at https://www.gnu.org/licenses/

 Linking this library statically or dynamically with other modules is
 making a combined work based on this library.  Thus, the terms and
 conditions of the GNU Affero General Public License cover the whole
 combination.

 As a special exception, the copyright holders of this library give you
 permission to link this library with independent modules to produce an
 executable, regardless of the license terms of these independent
 modules, and to copy and distribute the resulting executable under
 terms of your choice, provided that you also meet, for each linked
 independent module, the terms and conditions of the license of that
 module.  An independent module is a module which is not derived from
 or based on this library.  If you modify this library, you may extend
 this exception to your version of the library, but you are not
 obligated to do so.  If you do not wish to do so, delete this
 exception statement from your version.
 */
import FairKit
import FairExpo
import Combine

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
extension AppInfo : Identifiable {
    /// The bundle ID of the selected app (e.g., "app.App-Name")
    public var id: AppCatalogItem.ID {
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
    var displayCategories: [AppCategoryType] {
        app.categories?.filter({ $0.parentCategory == nil }) ?? []
    }
}

extension Plist {
    /// The value of the `CFBundleIdentifier` key
    var bundleID: String? {
        self.CFBundleIdentifier
    }

    /// A `AppIdentifier` wrapper for the value of the `CFBundleIdentifier` key
    var appIdentifier: AppIdentifier? {
        bundleID.flatMap(AppIdentifier.init(rawValue:))
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

/// A type wrapper for a bundle identifier string
public struct AppIdentifier: Hashable, RawRepresentable, Comparable {
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
    public var id: AppIdentifier { AppIdentifier(bundleIdentifier ?? wip("")) }
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

struct AppFairCommands: Commands {
    @FocusedBinding(\.selection) private var selection: AppInfo??
    @FocusedBinding(\.sourceSelection) private var sourceSelection: SourceSelection??

    //    @FocusedBinding(\.reloadCommand) private var reloadCommand: (() async -> ())?

    @ObservedObject var fairManager: FairManager

    var body: some Commands {
        CommandMenu(Text("Sources", comment: "menu title for app source actions")) {
            Text("Refresh Catalogs", comment: "menu title for refreshing the app catalog")
                .button(action: { reloadAll(fromSouce: false) })
                .disabled(fairManager.refreshing)
                .keyboardShortcut("R", modifiers: [.command])

            Text("Reload Catalogs from Source", comment: "menu title for reloading the app catalog")
                .button(action: { reloadAll(fromSouce: true) })
                .disabled(fairManager.refreshing)
                .keyboardShortcut("R", modifiers: [.command, .shift])

//            Text("Add Catalog", comment: "menu title for adding an app catalog")
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
            sourceSelection = selection
        } label: {
            fairManager.sourceInfo(for: selection)?.tintedLabel(monochrome: true).title
        }
    }

    func sourceInfo(for selection: SourceSelection) -> AppSourceInfo? {
        fairManager.sourceInfo(for: selection)
    }

    func reloadAll(fromSouce: Bool) {
        Task(priority: .userInitiated) {
            if fromSouce {
                fairManager.clearCaches() // also flush caches
            }
            await fairManager.refresh(reloadFromSource: fromSouce)
        }
    }
}

struct CopyAppURLCommand : View {
    @EnvironmentObject var fairManager: FairManager
    @FocusedBinding(\.selection) private var selection: AppInfo??
    @FocusedBinding(\.sourceSelection) private var sourceSelection: SourceSelection??

    var body: some View {
        Text("Copy App URL", comment: "menu title for command")
            .button(action: commandSelected)
            .keyboardShortcut("C", modifiers: [.command, .shift])
            .disabled(selection??.app == nil)
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
                #if os(macOS)
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 55, height: 55, alignment: .center)
                    .padding()
                #endif

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
                        Text("More Info", comment: "error dialog disclosure button title for showing more information")
                    }
                }

                Button {
                    errorBinding.wrappedValue.removeFirst()
                } label: {
                    Text("OK", comment: "error dialog button to dismiss the error").padding()
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

extension View {
    /// Creates a button with the given optional async action.
    ///
    /// This is intended to be used with something like:
    ///
    /// ```
    /// @FocusedBinding(\.reloadCommand) private var reloadCommand: (() async -> ())?
    ///
    /// Text("Reload", comment: "help text")
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

public struct RootView : View, Equatable {
    public var body: some View {
        NavigationRootView()
    }
}

/// The selection in the sidebar, consisting of an ``AppSource`` and a ``SidebarSection``
public struct SourceSelection : Hashable {
    public let source: AppSource
    public let section: SidebarSection
}

/// A standard group for a sidebar representation
public enum SidebarSection : Hashable {
    case top
    case updated
    case installed
    case sponsorable
    case recent
    case category(_ category: AppCategoryType)

    /// The sections in the order of display in a sidebar
    public static let orderedSections = [
        Self.top,
        .updated,
        .sponsorable,
        .installed,
        .recent,
    ]

    func shouldDisplay(sectionWithCount count: Int?) -> Bool {
        if case .sponsorable = self {
            // the sponsorable section will only display when there are apps
             return (count ?? 0) > 0
        }

        return count != nil
    }

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


struct NavigationRootView : View {
    @EnvironmentObject var fairManager: FairManager
    @Environment(\.scenePhase) var scenePhase

    //@FocusedBinding(\.reloadCommand) private var reloadCommand: (() async -> ())?

    @State var selection: AppInfo.ID? = nil
    /// Indication that the selection should be scrolled to
    @State var scrollToSelection: Bool = false

    @State var sourceSelection: SourceSelection? = nil

    //@SceneStorage("displayMode")
    @State var displayMode: TriptychOrient = TriptychOrient.allCases.first!
    
    @AppStorage("iconBadge") var iconBadge = true
    //@SceneStorage("source") var source: AppSource = AppSource.allCases.first!

    /// The window-wide search text
    @State var searchText: String = ""

    /// The information for a dialog requesting that a new source be added
    @State var addSourceItem: AddSourceItem? = nil

    var body: some View {
        triptychView
            .displayingFirstAlert($fairManager.errors)
            .toolbar(id: "NavToolbar") {
                //                ToolbarItem(placement: .navigation) {
                //                    Button(action: toggleSidebar) {
                //                        FairSymbol.sidebar_left.image
                //                    })
                //                }

                #if os(macOS)
                ToolbarItem(id: "AppPrivacy", placement: .automatic, showsByDefault: true) {
                    fairManager.launchPrivacyButton()
                }
                #endif
                
                ToolbarItem(id: "ReloadButton", placement: .automatic, showsByDefault: true) {
                    Text("Reload", comment: "refresh catalog toolbar button title")
                        .label(image: FairSymbol.arrow_triangle_2_circlepath.symbolRenderingMode(.hierarchical).foregroundStyle(Color.teal, Color.yellow, Color.blue))
                        .button {
                            await fairManager.refresh(reloadFromSource: false) // TODO: true when option or control key is down?
                        }
                        .hoverSymbol(activeVariant: .fill)
                        .help(Text("Refresh the app catalogs", comment: "refresh catalog toolbar button tooltip"))
                }


                ToolbarItem(id: "DisplayModePicker", placement: .automatic, showsByDefault: false) {
                    DisplayModePicker(mode: $displayMode)
                }
            }
//            .task(priority: .background) {
//                dbg(wip("Testing Task"))
//                do {
//                    for try await data in try FileHandle(forReadingFrom: URL(fileURLWithPath: "/dev/random")).readDataAsync() {
//                        dbg("read data:", data)
//                    }
//                } catch {
//                    dbg("error:", error)
//                }
//            }
            .task(priority: .medium) {
                dbg("refreshing catalogs")
                await fairManager.refresh(reloadFromSource: false)
            }
            .task(priority: .low) {
                #if os(macOS)
                do {
                    // TODO: check for system homebrew here and prompt user for which one to use
                    try await fairManager.homeBrewInv?.installHomebrew(force: true, fromLocalOnly: true, retainCasks: true)
                } catch {
                    dbg("error unpacking homebrew in local cache:", error)
                }
                #endif
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
            .onChange(of: sourceSelection) { selection in
                if !searchText.isEmpty && selection?.section != .top { // only clear when switching away from the "popular" tab
                    searchText = "" // clear search whenever the sidebar selection changes
                }
            }
            .onChange(of: fairManager.enableUserSources) { enable in
                fairManager.loadUserSources(enable: enable)
            }
            .handlesExternalEvents(preferring: [], allowing: ["*"]) // re-use this window to open external URLs
            .onOpenURL(perform: handleURL)
            .sheet(item: $addSourceItem, content: addSourcePrompView)
    }

    var sourceSelectionBinding: Binding<SourceSelection?> {
        //return .constant(.init(source: .fairapps, section: .updated))
        return $sourceSelection
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
        return sourceSelection?.source
    }

    public var triptychView : some View {
        TriptychView(orient: $displayMode) {
            SidebarView(selection: $selection, scrollToSelection: $scrollToSelection, sourceSelection: sourceSelectionBinding, displayMode: $displayMode, searchText: $searchText, addSourceItem: $addSourceItem)
            .focusedSceneValue(\.sourceSelection, sourceSelectionBinding)
        } list: {
            if let sidebarSource = sidebarSource {
                AppsListView(source: sidebarSource, sourceSelection: sourceSelection, selection: $selection, scrollToSelection: $scrollToSelection, searchTextSource: $searchText)
            } else {
                EmptyView() // TODO: better placeholder view for un-selected sidebar section
            }
        } table: {
#if os(macOS)
            if let sidebarSource = sidebarSource {
                AppsTableView(source: sidebarSource, selection: $selection, sourceSelection: sourceSelection, searchText: $searchText)
            } else {
                EmptyView()
            }
#endif
        } content: {
            AppDetailView(sourceSelection: sourceSelectionBinding)
        }
        // warning: this spikes CPU usage when idle
        //        .focusedSceneValue(\.reloadCommand, .constant({
        //            await fairAppInv.fetchApps(cache: .reloadIgnoringLocalAndRemoteCacheData)
        //        }))
    }
}

/// A type that can handle adding a source dialog
protocol AddSourceDialogHandler {
    @MainActor var fairManager: FairManager { get }
    var addSourceItem: AddSourceItem? { get nonmutating set }
}

extension NavigationRootView : AddSourceDialogHandler {
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

            if path == ["source"], let sourceURLString = url.queryParameters?["url"] as? String {
                if let sourceURL = URL(partialString: sourceURLString, defaultScheme: "https") {
                    dbg("displaying add source dialog:", sourceURL)
                    self.addSourceItem = AddSourceItem(addSource: sourceURL.absoluteString)
                }
                return
            }

            let isCask = path.first == "homebrew"
            let searchID = path.joined(separator: isCask ? "/" : ".") // "homebrew/cask/iterm2" vs. "app.Tidal-Zone"

            // handle: https://appfair.app/fair?app=Tune-Out&catalog=appfair.net/fairapps-ios.json

            let bundleID = AppIdentifier(searchID)

            // random crashes seem to happen without dispatching to main
            self.searchText = bundleID.rawValue // needed to cause the section to appear

            // switch to correct catalog by matching the source when opening from URL
            let source = AppSource(rawValue: catalogURL.absoluteString)
            self.sourceSelection = SourceSelection(source: isCask ? .homebrew : source, section: .top)

            self.selection = bundleID
            dbg("selected app ID", self.selection)
            // DispatchQueue.main.async {
            //     self.scrollToSelection = true // if the catalog section is offscreen, then the selection will fail, so we need to also refine the current search to the bundle id
            // }
        }
    }
}

extension AddSourceDialogHandler {

    func isValidSourceURL(_ urlString: String) -> URL? {
        guard let url = URL(string: urlString) else {
            return nil
        }
        if ["http", "https", "file"].contains(url.scheme) {
            return url
        }
        return nil
    }

    func addSourcePrompView(item: AddSourceItem) -> some View {
        GroupBox {
            VStack {
                Form {
                    TextField(text: Binding(get: { addSourceItem?.addSource ?? item.addSource }, set: { addSourceItem?.addSource = $0 })) {
                        Text("Catalog URL:", comment: "add catalog source dialog text")
                    }
                    .onSubmit(of: .text) {
                        // clear error whenever we change the url
                        addSourceItem?.addSourceItemValidationError = nil
                    }
                    .onChange(of: addSourceItem?.addSource) { url in
                        // clear error whenever we change the url
                        addSourceItem?.addSourceItemValidationError = nil
                    }
                    .disableAutocorrection(true)
                    //.keyboardType(.default)
                    Text("An app source is a URL pointing to a JSON file with a list of apps.", comment: "add catalog source footer")
                        .font(.footnote)
                    Text("For information on the catalog format see [appfair.net/#appsource](https://appfair.net/#appsource).", comment: "add catalog source footer")
                        .font(.footnote)
                    Spacer()

                    ScrollView {
                        addSourceItem?.addSourceItemValidationError?.localizedDescription.text()
                            .font(.callout)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.red)
                            .textSelection(.enabled)
                    }
                    .frame(height: 75)
                }

                Spacer()
                HStack {
                    Spacer()
                    Button(role: .cancel, action: closeNewAppSourceDialog) {
                        Text("Cancel", comment: "add catalog source button text")
                    }
                    .keyboardShortcut(.escape)
                    Text("Add", comment: "add catalog source button text")
                        .button(priority: .userInitiated) {
                            do {
                                try await validateNewAppSource(default: item)
                            } catch {
                                dbg("error adding catalog:", error)
                                self.addSourceItem?.addSourceItemValidationError = error
                            }
                        }
                    .keyboardShortcut(.return)
                    .disabled(isValidSourceURL(addSourceItem?.addSource ?? item.addSource) == nil)
                }
            }
            .frame(width: 400)
            .padding()
        } label: {
            Text("Add App Source", comment: "add catalog source dialog title")
                .font(.largeTitle)
                .padding()
        }
    }

    func closeNewAppSourceDialog() {
        self.addSourceItem = nil
    }

    func validateNewAppSource(default item: AddSourceItem) async throws {
        guard let url = isValidSourceURL(addSourceItem?.addSource ?? item.addSource) else {
            throw AppError(NSLocalizedString("URL is invalid", comment: "error message when app source URL is not valid"))
        }

        let source = AppSource(rawValue: url.absoluteString)

        if let _ = await self.fairManager.appInventories.first(where: { inv in
            inv.source == source
        }) {
            throw AppError(NSLocalizedString("A catalog with the same source URL is already added.", comment: "error message when app source URL is already added"))
        }

        let data = try await URLSession.shared.fetch(request: URLRequest(url: url)).data

        // ensure we can parse the catalog
        let catalog = try AppCatalog.parse(jsonData: data)

        // since a catalog saves apps to '/Applications/Fair Ground/net.catalog.id/App Name.app',
        // we need to ensure that only a single catalog is managing a specific folder
        if let _ = await self.fairManager.appInventories.first(where: { inv in
            (inv as? AppSourceInventory)?.catalogSuccess?.identifier == catalog.identifier
        }) {
            throw AppError(NSLocalizedString("A catalog with the same identifier is already added.", comment: "error message when app source identifier is already added"), recoverySuggestion: NSLocalizedString("The other catalog must be removed before this one can be added.", comment: "error message recover suggestion when app source URL identifier is already added"))
        }

        guard let inventory = await self.fairManager.addAppSource(url: url, load: .userInitiated, persist: true) else {
            throw AppError(NSLocalizedString("Unable to add App Source", comment: "error message when app source URL is not valid"))
        }

        let _ = inventory

        closeNewAppSourceDialog()
    }

}

extension URL {
    /// Creates a URL that may not contain a scheme.
    ///
    /// - Parameters:
    ///   - partialString: a URL that may not contain the leading "scheme://" string
    ///   - defaultScheme: the scheme to fill in if the expected scheme is missing
    ///
    /// For example, `URL(partialString: "example.org", defaultScheme: "ftp")`
    /// will create a URL: "ftp://example.org"
    public init?(partialString: String, defaultScheme: String) {
        if let url = URL(string: partialString), url.scheme != nil {
            self = url
        } else if let url = URL(string: defaultScheme + "://" + partialString) {
            self = url
        } else {
            return nil
        }
    }

    /// Parses the URL for query parameters
    var queryParameters: [String: String?]? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems?.dictionary(keyedBy: \.name).mapValues(\.value)
    }
}

#if os(macOS)
public struct AppTableDetailSplitView : View {
    let source: AppSource
    @Binding var selection: AppInfo.ID?
    @Binding var searchText: String
    @Binding var sourceSelection: SourceSelection?

    @ViewBuilder public var body: some View {
        VSplitView {
            AppsTableView(source: source, selection: $selection, sourceSelection: sourceSelection, searchText: $searchText)
                .frame(minHeight: 150)
            AppDetailView(sourceSelection: $sourceSelection)
                .layoutPriority(1.0)
        }
    }
}
#endif

public struct AppDetailView : View {
    @Binding var sourceSelection: SourceSelection?
    @FocusedBinding(\.selection) private var selection: AppInfo??
    @EnvironmentObject var fairManager: FairManager

    @ViewBuilder public var body: some View {
        if let source = sourceSelection?.source,
           let selection = selection,
           let app = selection {
            CatalogItemView(info: app, source: source)
        } else {
            emptySelectionView()
        }
    }

    @ViewBuilder func emptySelectionView() -> some View {
        VStack {
            if let sourceSelection = sourceSelection {
                fairManager.sourceOverviewView(selection: sourceSelection, showText: true, showFooter: true)
                    .font(.body)
                Spacer()

//                if !showOverviewText {
//                    Text("No Selection", comment: "placeholder text for detail panel indicating there is no app currently selected")
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
                    Text("The App Fair", comment: "header text for detail screen with no selection")
                        .font(Font.system(size: 40, weight: .regular, design: .rounded).lowercaseSmallCaps())
                    Text("Community App Sources", comment: "header sub-text for detail screen with no selection")
                        .font(Font.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Material.thin)
            }
        }
    }

    func browseButton(_ sourceSelection: SourceSelection) -> some View {
        Button {
            withAnimation {
                self.sourceSelection = sourceSelection
                self.selection = .some(.none)
            }
        } label: {
            let title = fairManager.sourceInfo(for: sourceSelection)?.fullTitle ?? Text(verbatim: "")
            Text("Browse \(title)", comment: "format pattern for the label of the button at the bottom of the category info screen")
        }
    }

}

extension View {
    /// The custom tinting style for the App Fair
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
    let category: AppCategoryType

    func tintedLabel(monochrome: Bool) -> TintedLabel {
        category.tintedLabel(monochrome: monochrome)
    }

    /// Subtitle text for this source
    var fullTitle: Text {
        Text("Category: \(category.text)", comment: "app category info: title pattern")
    }

    /// A textual description of this source
    var overviewText: [Text] {
        []
        // Text(wip("XXX"), comment: "app category info: overview text")
    }

    var footerText: [Text] {
        []
        // Text(wip("XXX"), comment: "homebrew recent apps info: overview text")
    }

    /// A list of the features of this source, which will be displayed as a bulleted list
    var featureInfo: [(FairSymbol, Text)] {
        []
    }
}

extension AppCategoryType : Identifiable {
    public var id: Self { self }
}

extension FocusedValues {
    private struct FocusedSelection: FocusedValueKey {
        typealias Value = Binding<AppInfo?>
    }

    var selection: Binding<AppInfo?>? {
        get { self[FocusedSelection.self] }
        set { self[FocusedSelection.self] = newValue }
    }

    private struct FocusedSourceSelection: FocusedValueKey {
        typealias Value = Binding<SourceSelection?>
    }

    var sourceSelection: Binding<SourceSelection?>? {
        get { self[FocusedSourceSelection.self] }
        set { self[FocusedSourceSelection.self] = newValue }
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

#if os(macOS)

extension ObservableObject {
    /// Issues a prompt with the given parameters, returning whether the user selected OK or Cancel
    @MainActor func prompt(_ style: NSAlert.Style = .informational, window sheetWindow: NSWindow? = nil, messageText: String, informativeText: String? = nil, accept: String = NSLocalizedString("OK", comment: "default button title for prompt"), refuse: String = NSLocalizedString("Cancel", comment: "cancel button title for prompt"), suppressionTitle: String? = nil, suppressionKey: Binding<PromptSuppression>? = nil) async -> Bool {

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
        _ = alert.addButton(withTitle: accept)
        _ = alert.addButton(withTitle: refuse)

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

        let scriptBase = URL.tmpdir.appendingPathComponent("cmd-" + UUID().uuidString)
        let scriptURL = scriptBase.appendingPathComponent(name + ".scpt") // needed or else error that the script: “couldn’t be opened because it isn’t in the correct format”
        try FileManager.default.createDirectory(at: scriptURL.deletingLastPathComponent(), withIntermediateDirectories: true)

        // clean up the script folders afer we execute
        defer { try? FileManager.default.removeItem(at: scriptBase) }

        try cmd.write(to: scriptURL, atomically: true, encoding: .utf8)
        dbg("running NSUserAppleScriptTask in:", scriptURL.path, "command:", cmd)
        let task = try NSUserAppleScriptTask(url: scriptURL)
        let output = try await task.execute(withAppleEvent: nil)
        dbg("successfully executed script:", command)
        return output.stringValue
    }
}
#endif


public extension Date {
    /// Returns a ``SwiftUI/Text`` that will format the given date.
    ///
    /// - Parameters:
    ///   - presentation: the presentation style
    ///   - unitStyle: the units style
    /// - Returns: A ``Text`` with the presentation format
    func relativeText(presentation: RelativeFormatStyle.Presentation, unitStyle: RelativeFormatStyle.UnitsStyle) -> Text {
        Text(self, format: RelativeFormatStyle.relative(presentation: presentation, unitsStyle: unitStyle))
    }

    func textDate(dateStyle: FormatStyle.DateStyle? = nil, timeStyle: FormatStyle.TimeStyle? = nil, locale: Locale = .autoupdatingCurrent, calender: Calendar = .autoupdatingCurrent, timeZone: TimeZone = .autoupdatingCurrent, capitalizationContext: FormatStyleCapitalizationContext = .unknown) -> Text {
        Text(self, format: Date.FormatStyle(date: dateStyle, time: timeStyle, locale: locale, calendar: calender, timeZone: timeZone, capitalizationContext: capitalizationContext))
    }
}

extension Int {
    func textNumber() -> Text {
        Text(self, format: .number)
    }
}

extension Text {
    /// Converts this `Text` into a label with a yellow exclamation warning.
    func warningLabel() -> some View {
        self.label(image: FairSymbol.exclamationmark_triangle_fill.symbolRenderingMode(.multicolor))
    }
}

// MARK: Parochial (package-local) Utilities

/// Work-in-Progress marker for ipa installation
///
/// - TODO: @available(*, deprecated, message: "work in progress")
internal func wipipa<T>(_ value: T) -> T { value }

