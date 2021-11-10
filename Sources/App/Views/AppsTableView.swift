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
    @Binding var category: AppManager.SidebarItem?
    @State var sortOrder: [KeyPathComparator<AppsTableView.TableRowValue>] = []
    @State var searchText: String = ""
    let showBetaReleases: Bool = wip(false) // TODO: preference to enable betas
    var displayExtensions: Set<String>? = ["zip"] // , "ipa"]

    var items: [AppInfo] {
        appManager
            .appInfoItems()
            .sorted(using: sortOrder + categorySortOrder())
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
                nameColumn.width(ideal: 125)

//                let subtitleColumn = ostrColumn(named: "Subtitle", path: \TableRowValue.release.subtitle)
//                subtitleColumn

//                let descColumn = strColumn(named: "Description", path: \TableRowValue.release.localizedDescription)
//                descColumn
            }

            Group {
                let versionColumn = oversionColumn(named: "Version", path: \TableRowValue.releasedVersion)
                versionColumn.width(ideal: 60)

                let installedColumn = oversionColumn(named: "Installed", path: \TableRowValue.installedVersion)
                installedColumn.width(ideal: 60)

                let sizeColumn = TableColumn("Size", value: \TableRowValue.release.size) { item in
                    Text(item.release.size.localizedByteCount())
                        .multilineTextAlignment(.trailing)
                }
                sizeColumn.width(ideal: 60)

//                let coreSizeColumn = onumColumn(named: "Core Size", path: \TableRowValue.release.coreSize)
//                coreSizeColumn

                let riskColumn = TableColumn("Risk", value: \TableRowValue.release.riskLevel) { item in
                    item.release.riskLabel()
                }
                riskColumn.width(ideal: 125)

                let dateColumn = TableColumn("Date", value: \TableRowValue.release.versionDate, comparator: optionalDateComparator) { item in
                    Text(item.release.versionDate?.localizedDate(dateStyle: .medium, timeStyle: .none) ?? "")
                        .multilineTextAlignment(.trailing)
                }
                dateColumn

            }

            Group {
                let starCount = onumColumn(named: "Stars", path: \TableRowValue.release.starCount)
                starCount.width(ideal: 40)

                let downloadCount = onumColumn(named: "Downloads", path: \TableRowValue.release.downloadCount)
                downloadCount.width(ideal: 40)

                //let forkCount = onumColumn(named: "Forks", path: \TableRowValue.release.forkCount)
                //forkCount.width(ideal: 40)

                let issueCount = onumColumn(named: "Issues", path: \TableRowValue.release.issueCount)
                issueCount.width(ideal: 40)

                let catgoryColumn = ostrColumn(named: "Category", path: \TableRowValue.release.primaryCategoryIdentifier?.rawValue)
                catgoryColumn

                let authorColumn = strColumn(named: "Author", path: \TableRowValue.release.developerName)
                authorColumn.width(ideal: 200)
            }
        }, rows: { self })
    }

    var table: some View {
        return tableView
            .tableStyle(.inset(alternatesRowBackgrounds: false))
            .id(category) // attempt to prevent: “*** Assertion failure in -[NSTableRowHeightData _variableRemoveRowSpansInRange:], NSTableRowHeightData.m:1283 … [General] row validation for deletion of 1 rows starting at index 5”
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

    func categorySortOrder() -> [KeyPathComparator<AppsTableView.TableRowValue>] {
        switch category {
        case .none:
            return []
        case .popular:
            return [KeyPathComparator(\TableRowValue.release.starCount, order: .reverse), KeyPathComparator(\TableRowValue.release.downloadCount, order: .reverse)]
        case .recent:
            return [KeyPathComparator(\TableRowValue.release.versionDate, order: .reverse)]
        case .updated:
            return [KeyPathComparator(\TableRowValue.release.versionDate, order: .reverse)]
        case .installed:
            return [KeyPathComparator(\TableRowValue.release.name, order: .forward)]
        case .category:
            return [KeyPathComparator(\TableRowValue.release.starCount, order: .reverse), KeyPathComparator(\TableRowValue.release.downloadCount, order: .reverse)]
        }
    }

    func categoryFilter(item: TableRowValue) -> Bool {
        category?.matches(item: item) != false
    }

    func filterRows(_ items: [TableRowValue]) -> [TableRowValue] {
        items
            .filter(matchesFilterText)
            .filter(matchesSearch)
            .filter(matchesBeta)
            .filter(categoryFilter)
    }

    func matchesFilterText(item: TableRowValue) -> Bool {
        displayExtensions?.contains(item.release.downloadURL.pathExtension) != false
    }

    func matchesBeta(item: TableRowValue) -> Bool {
        showBetaReleases == (item.release.beta ?? false)
    }

    func matchesSearch(item: TableRowValue) -> Bool {
        (searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || item.release.name.localizedCaseInsensitiveContains(searchText) == true
            || item.release.subtitle?.localizedCaseInsensitiveContains(searchText) == true
            || item.release.localizedDescription.localizedCaseInsensitiveContains(searchText) == true)
    }
}


@available(macOS 12.0, iOS 15.0, *)
extension AppManager.SidebarItem {
    func matches(item: AppInfo) -> Bool {
        switch self {
        case .popular:
            return true
        case .updated:
            return item.appUpdated
        case .installed:
            return item.installedVersion != nil
        case .recent:
            return true
        case .category(let category):
            return Set(category.categories).intersection(item.release.appCategories).isEmpty == false
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
            AppsTableView(selection: .constant(AppCatalogItem.sample.id), category: .constant(.popular))
                .environmentObject(AppManager.default)
        }
    }
}

#endif // os(macOS)

