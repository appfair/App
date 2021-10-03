import Swift
import SwiftUI
import FairApp

#if os(macOS)
/// A container for a Table
@available(macOS 12.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
protocol ItemTableView : TableRowContent {

    /// The items that this table holds
    var items: [TableRowValue] { get }

    /// The current selection, if any
    var selection: TableRowValue.ID? { get nonmutating set }

    /// The current sort orders
    var sortOrder: [KeyPathComparator<TableRowValue>] { get nonmutating set }

    /// Filters the rows based on the current search term
    func filterRows(_ items: [TableRowValue]) -> [TableRowValue]

    /// The type of column that is to be displayed
    associatedtype Columnator: SetAlgebra
    func columnVisible(element: Columnator.Element) -> Bool
}

@available(macOS 12.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension ItemTableView {
    /// By default no searching is performed
    func filterRows(_ items: [TableRowValue]) -> [TableRowValue] {
        return items
    }

    var filteredRows: [TableRowValue] {
        filterRows(self.items)
    }

    var tableRowBody: some TableRowContent {
        ForEach(filteredRows) { item in
            TableRow(item)
                //.itemProvider { items.itemProvider }
        }
    }
}


@available(macOS 12.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension ItemTableView {

    func dateColumn(named key: LocalizedStringKey, path: KeyPath<TableRowValue, Date?>) -> TableColumn<TableRowValue, KeyPathComparator<TableRowValue>, Text, Text> {
        TableColumn(key, value: path, comparator: optionalDateComparator) { item in
            Text(item[keyPath: path]?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
            //Text(item[keyPath: path].localizedDate(dateStyle: .short, timeStyle: .short))
        }
    }

    func numColumn<T: BinaryInteger>(named key: LocalizedStringKey, path: KeyPath<TableRowValue, T>) -> TableColumn<TableRowValue, KeyPathComparator<TableRowValue>, Text, Text> {
        TableColumn(key, value: path, comparator: NumericComparator()) { item in
            Text(item[keyPath: path].localizedNumber())
        }
    }

    func boolColumn(named key: LocalizedStringKey, path: KeyPath<TableRowValue, Bool>) -> TableColumn<TableRowValue, KeyPathComparator<TableRowValue>, Toggle<EmptyView>, Text> {
        TableColumn(key, value: path, comparator: BoolComparator()) { item in
            Toggle(isOn: .constant(item[keyPath: path])) { EmptyView () }
        }
    }

    /// Non-optional string column
    func strColumn(named key: LocalizedStringKey, path: KeyPath<TableRowValue, String>) -> TableColumn<TableRowValue, KeyPathComparator<TableRowValue>, Text, Text> {
        TableColumn(key, value: path, comparator: .localizedStandard) { item in
            Text(item[keyPath: path])
        }
    }

    func ostrColumn(named key: LocalizedStringKey, path: KeyPath<TableRowValue, String?>) -> TableColumn<TableRowValue, KeyPathComparator<TableRowValue>, Text, Text> {
        TableColumn(key, value: path, comparator: optionalStringComparator) { item in
            Text(item[keyPath: path] ?? "")
        }
    }

    func oversionColumn(named key: LocalizedStringKey, path: KeyPath<TableRowValue, AppVersion?>) -> TableColumn<TableRowValue, KeyPathComparator<TableRowValue>, VersionLabel, Text> {
        // TODO: we might want to disallow sorting on versions since it doesn't make sense to compare the versions of two different apps, and we want to discourage version inflation as a mechanism for rank boosting
        TableColumn(key, value: path, comparator: optionalComparator(AppVersion.min)) { item in
            VersionLabel(version: item[keyPath: path])
        }
    }

    func onumColumn<T: BinaryInteger>(named key: LocalizedStringKey, path: KeyPath<TableRowValue, T?>) -> TableColumn<TableRowValue, KeyPathComparator<TableRowValue>, AlignedText, Text> {
        TableColumn(key, value: path, comparator: optionalComparator(0)) { item in
            AlignedText(text: Text(item[keyPath: path]?.localizedNumber() ?? ""), alignment: .trailing)
        }
    }
}

struct AlignedText : View {
    let text: Text
    let alignment: TextAlignment

    var body: some View {
        text.multilineTextAlignment(alignment)
    }
}

/// The label that renders a version of an app
struct VersionLabel : View {
    let version: AppVersion?

    var body: some View {
        Text(version?.versionDescription ?? "-")
            .multilineTextAlignment(.trailing)
    }
}


@available(macOS 12.0, iOS 15.0, *)
extension SortComparator {
    func reorder(_ result: ComparisonResult) -> ComparisonResult {
        switch (order, result) {
        case (_, .orderedSame): return .orderedSame
        case (.forward, .orderedAscending): return .orderedAscending
        case (.reverse, .orderedAscending): return .orderedDescending
        case (.forward, .orderedDescending): return .orderedDescending
        case (.reverse, .orderedDescending): return .orderedAscending
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct BoolComparator : SortComparator {
    var order: SortOrder = SortOrder.forward

    func compare(_ lhs: Bool, _ rhs: Bool) -> ComparisonResult {
        switch (lhs, rhs) {
        case (true, true): return reorder(.orderedSame)
        case (false, false): return reorder(.orderedSame)
        case (true, false): return reorder(.orderedAscending)
        case (false, true): return reorder(.orderedAscending)
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct OptionalCompatator<T: Comparable & Hashable> : SortComparator {
    var order: SortOrder = SortOrder.forward

    let lhsDefault: T
    let rhsDefault: T

    func compare(_ lhs: T?, _ rhs: T?) -> ComparisonResult {
        lhs ?? lhsDefault < rhs ?? rhsDefault ? reorder(.orderedAscending)
        : lhs ?? lhsDefault > rhs ?? rhsDefault ? reorder(.orderedDescending)
        : .orderedSame
    }
}

@available(macOS 12.0, iOS 15.0, *)
let optionalDateComparator = OptionalCompatator(lhsDefault: Date.distantPast, rhsDefault: Date.distantFuture)

@available(macOS 12.0, iOS 15.0, *)
let optionalStringComparator = OptionalCompatator(lhsDefault: "", rhsDefault: "")

@available(macOS 12.0, iOS 15.0, *)
func optionalComparator<T: Hashable & Comparable>(_ value: T) -> OptionalCompatator<T> {
    OptionalCompatator(lhsDefault: value, rhsDefault: value)
}


@available(macOS 12.0, iOS 15.0, *)
struct URLComparator : SortComparator {
    var order: SortOrder = SortOrder.forward

    func compare(_ lhs: URL?, _ rhs: URL?) -> ComparisonResult {
        reorder((lhs?.absoluteString ?? "").compare(rhs?.absoluteString ?? ""))
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct NumericComparator<N: Numeric & Comparable> : SortComparator {
    var order: SortOrder = SortOrder.forward

    func compare(_ lhs: N, _ rhs: N) -> ComparisonResult {
        lhs < rhs ? reorder(.orderedAscending) : lhs > rhs ? reorder(.orderedDescending) : .orderedSame
    }
}

@available(macOS 12.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ReleasesTableView : View, ItemTableView {
    typealias TableRowValue = AppInfo
    @EnvironmentObject var appManager: AppManager
    @State var selection: AppInfo.ID? = nil
    @State var sortOrder = [KeyPathComparator(\TableRowValue.release.versionDate)]
    @State var searchText: String = ""
    @State var displayExtensions: Set<String> = ["zip"] // , "ipa"]

    @AppStorage("catalogURL") var catalogURL: URL = URL(string: "https://www.appfair.net/fairapps.json")!

    var items: [AppInfo] {
        appManager.catalog
            .map(appInfo(for:))
            .sorted(using: sortOrder)
    }

    func appInfo(for item: AppCatalogItem) -> AppInfo {
        // let plist = appManager.installedApps[appManager.appInstallPath(for: $0)]

        let plist = appManager.installedApps.values.compactMap(\.successValue).first(where: {
            $0.CFBundleIdentifier == item.bundleIdentifier
        })
        return AppInfo(release: item, installedPlist: plist)
    }

    struct Columnator : OptionSet {
        public static let defaultColumns: Self = [.icon, .name]

        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        public static let icon = Self(rawValue: 1 << 0)
        public static let name = Self(rawValue: 1 << 1)
    }

    func columnVisible(element: Columnator.Element) -> Bool {
        return true // TODO: allow users to customize the table columns to display
        //store.releaseTableColumns.contains(element)
    }

    var body: some View {
        table
            .task {
                dbg("table task: fetchApps")
                await fetchApps()
            }
    }

    func fetchApps(cache: URLRequest.CachePolicy? = nil) async {
        do {
            let start = CFAbsoluteTimeGetCurrent()
            let catalog = try await appManager.hub().fetchCatalog(catalogURL: catalogURL, cache: cache)
            appManager.catalog = catalog.apps
            let end = CFAbsoluteTimeGetCurrent()
            dbg("fetched catalog:", catalog.apps.count, "in:", (end - start))
        } catch {
            Task { // otherwise warnings about accessing off of the main thread
                // errors here are not unexpected, since we can get a `cancelled` error if the view that initiated the `fetchApps` request
                dbg("received error:", error)
                // we tolerate a "cancelled" error because it can happen when a view that is causing a catalog load is changed and its request gets automaticallu cancelled
                if (error as NSError).domain == NSURLErrorDomain && (error as NSError).code == -999 {

                } else {
                    appManager.reportError(error)
                }
            }
        }
    }

    var tableView: some View {
        Table(selection: $selection, sortOrder: $sortOrder, columns: {
            Group {
                let imageColumn = TableColumn("", value: \TableRowValue.release.iconURL, comparator: URLComparator()) { item in
                    if let iconURL = item.release.iconURL {
                        URLImage(url: iconURL, resizable: .fit)
                    }
                    //FairIconView(item.release.name)
                }
                imageColumn
                    .width(40)
            }

            Group {
                let nameColumn = strColumn(named: "Name", path: \TableRowValue.release.name)
                nameColumn

//                let subtitleColumn = ostrColumn(named: "Subtitle", path: \TableRowValue.release.subtitle)
//                subtitleColumn

                let descColumn = strColumn(named: "Description", path: \TableRowValue.release.localizedDescription)
                descColumn
            }

            Group {
                let versionColumn = oversionColumn(named: "Version", path: \TableRowValue.releasedVersion)
                versionColumn

                let installedColumn = oversionColumn(named: "Installed", path: \TableRowValue.installedVersion)
                installedColumn
                let sizeColumn = TableColumn("Size", value: \TableRowValue.release.size) { item in
                    Text(item.release.size.localizedByteCount())
                        .multilineTextAlignment(.trailing)
                }
                sizeColumn

                let coreSizeColumn = onumColumn(named: "Core Size", path: \TableRowValue.release.coreSize)
                coreSizeColumn

                let riskColumn = TableColumn("Risk", value: \TableRowValue.release.riskLevel) { item in
                    item.release.riskLabel()
                }
                riskColumn

                let dateColumn = TableColumn("Date", value: \TableRowValue.release.versionDate, comparator: optionalDateComparator) { item in
                    Text(item.release.versionDate?.localizedDate(dateStyle: .medium, timeStyle: .none) ?? "")
                        .multilineTextAlignment(.trailing)
                }
                dateColumn

            }

            Group {
                let starCount = onumColumn(named: "Stars", path: \TableRowValue.release.starCount)
                starCount

                let downloadCount = onumColumn(named: "Downloads", path: \TableRowValue.release.downloadCount)
                downloadCount

                //let forkCount = onumColumn(named: "Forks", path: \TableRowValue.release.forkCount)
                //forkCount

                let issueCount = onumColumn(named: "Issues", path: \TableRowValue.release.issueCount)
                issueCount
            }
        }, rows: { self })
    }

    var table: some View {
        return tableView
            .tableStyle(.inset(alternatesRowBackgrounds: false))
            .font(Font.body.monospacedDigit())
            .focusedSceneValue(\.selection, .constant(itemSelection))
            .focusedSceneValue(\.reloadCommand, .constant({ await fetchApps(cache: .reloadIgnoringLocalAndRemoteCacheData) }))
            .searchable(text: $searchText)
    }

    /// The currently selected item
    var itemSelection: Selection? {
        guard let item = items.first(where: { $0.id == selection }) else {
            return nil
        }

        return Selection.app(item)
    }

    func filterRows(_ items: [TableRowValue]) -> [TableRowValue] {
        items.filter { item in
            (displayExtensions.contains(item.release.downloadURL.pathExtension))
            && (searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || item.release.name.localizedCaseInsensitiveContains(searchText) == true
                || item.release.subtitle?.localizedCaseInsensitiveContains(searchText) == true
                || item.release.localizedDescription.localizedCaseInsensitiveContains(searchText) == true)
        }
    }
}

#endif // os(macOS)
