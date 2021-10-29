import FairApp

/// List version of the `AppsTableView` for list browsing mode.
@available(macOS 12.0, iOS 15.0, *)
struct AppsListView : View {
    var item: AppManager.SidebarItem?

    var body : some View {
        wip(EmptyView())
    }
}

#if os(macOS)

@available(macOS 12.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct AppsTableView : View, ItemTableView {
    typealias TableRowValue = AppInfo
    @EnvironmentObject var appManager: AppManager
    @Binding var selection: AppInfo.ID?
    @State var sortOrder = [KeyPathComparator(\TableRowValue.release.versionDate)]
    @State var searchText: String = ""
    var displayExtensions: Set<String>? = ["zip"] // , "ipa"]
    var sidebarItem: AppManager.SidebarItem?

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

//                let coreSizeColumn = onumColumn(named: "Core Size", path: \TableRowValue.release.coreSize)
//                coreSizeColumn

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
            .focusedSceneValue(\.reloadCommand, .constant({
                await appManager.fetchApps(cache: .reloadIgnoringLocalAndRemoteCacheData)
            }))
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
        items
            .filter(matchesFilterText)
            .filter(matchesSearch)
            .filter(matchesSidebarItem)
    }

    func matchesFilterText(item: TableRowValue) -> Bool {
        displayExtensions?.contains(item.release.downloadURL.pathExtension) != false
    }

    func matchesSearch(item: TableRowValue) -> Bool {
        (searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || item.release.name.localizedCaseInsensitiveContains(searchText) == true
            || item.release.subtitle?.localizedCaseInsensitiveContains(searchText) == true
            || item.release.localizedDescription.localizedCaseInsensitiveContains(searchText) == true)
    }

    func matchesSidebarItem(item: TableRowValue) -> Bool {
        sidebarItem?.matches(item: item) != false
    }
}


@available(macOS 12.0, iOS 15.0, *)
extension AppManager.SidebarItem {
    func matches(item: AppInfo) -> Bool {
        switch self {
        case .popular: return true
        case .pinned: return true
        case .installed: return true
        case .recent: return true
        case .category(let category): return Set(category.categories).intersection(item.release.appCategories).isEmpty == false
        case .search(let _): return wip(true)
        }
    }
}


@available(macOS 12.0, *)
struct AppsTableView_Previews: PreviewProvider {
    static var previews: some View {
        AppManager.default.catalog = [
            AppCatalogItem.sample,
            //AppCatalogItem.sample,
            //AppCatalogItem.sample,
            //AppCatalogItem.sample,
            //AppCatalogItem.sample,
        ]

        //AppManager.default.catalog += AppManager.default.catalog

        assert(AppManager.default.catalog.count > 0)

        return VStack {
            Text("App Catalog Table")
                .font(.largeTitle)
            AppsTableView(selection: .constant(AppCatalogItem.sample.id))
            .environmentObject(AppManager.default)
        }
    }
}

#endif // os(macOS)

