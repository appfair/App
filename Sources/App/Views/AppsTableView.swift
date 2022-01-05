import FairApp

#if os(macOS)

@available(macOS 12.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct AppsTableView : View, ItemTableView {
    typealias TableRowValue = AppInfo
    @EnvironmentObject var fairManager: FairManager
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var caskManager: CaskManager
    @Binding var source: AppSource
    @Binding var selection: AppInfo.ID?
    @Binding var category: AppManager.SidebarItem?
    @State var sortOrder: [KeyPathComparator<AppInfo>] = []
    @State var searchText: String = ""

    var items: [AppInfo] {
        switch source {
        #if DEBUG
        case .homebrew:
            return caskManager.arrangedItems(category: category, sortOrder: sortOrder, searchText: searchText)
        #endif
        case .fairapps:
            return appManager.arrangedItems(category: category, sortOrder: sortOrder, searchText: searchText)
        }
    }

    var tableRowBody: some TableRowContent {
        ForEach(items) { item in
            TableRow(item)
                //.itemProvider { items.itemProvider }
        }
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
        return tableView
            .tableStyle(.inset(alternatesRowBackgrounds: true))
            .id(category) // attempt to prevent: “*** Assertion failure in -[NSTableRowHeightData _variableRemoveRowSpansInRange:], NSTableRowHeightData.m:1283 … [General] row validation for deletion of 1 rows starting at index 5”
            .font(Font.body.monospacedDigit())
            .focusedSceneValue(\.selection, .constant(itemSelection))
            .searchable(text: $searchText)
    }

    var tableView: some View {
        Table(selection: $selection, sortOrder: $sortOrder, columns: {
            Group {
                let imageColumn = TableColumn("", value: \AppInfo.release.iconURL, comparator: URLComparator()) { item in
                    item.release.iconImage()
                        .frame(width: 20, height: 20)
                }
                imageColumn
                    .width(20)
            }

            Group {
                let nameColumn = strColumn(named: "Name", path: \AppInfo.release.name)
                nameColumn.width(ideal: 125)

//                let subtitleColumn = ostrColumn(named: "Subtitle", path: \AppInfo.release.subtitle)
//                subtitleColumn

//                let descColumn = strColumn(named: "Description", path: \AppInfo.release.localizedDescription)
//                descColumn
            }

            Group {
                let versionColumn = ostrColumn(named: "Version", path: \AppInfo.release.version)
                versionColumn.width(ideal: 60)

                let installedColumn = ostrColumn(named: "Installed", path: \AppInfo.installedVersionString)
                installedColumn.width(ideal: 60)

                let sizeColumn = TableColumn("Size", value: \AppInfo.release.size) { item in
                    Text(item.release.size.localizedByteCount())
                        .multilineTextAlignment(.trailing)
                }
                sizeColumn.width(ideal: 60)

//                let coreSizeColumn = onumColumn(named: "Core Size", path: \AppInfo.release.coreSize)
//                coreSizeColumn

                let riskColumn = TableColumn("Risk", value: \AppInfo.release.riskLevel) { item in
                    item.release.riskLevel.riskLabel()
                        .help(item.release.riskLevel.riskSummaryText())
                }
                riskColumn.width(ideal: 125)

                let dateColumn = TableColumn("Date", value: \AppInfo.release.versionDate, comparator: optionalDateComparator) { item in
                    Text(item.release.versionDate?.localizedDate(dateStyle: .medium, timeStyle: .none) ?? "")
                        .multilineTextAlignment(.trailing)
                }
                dateColumn

            }

            Group {
                let starCount = onumColumn(named: "Stars", path: \AppInfo.release.starCount)
                starCount.width(ideal: 40)

                let downloadCount = onumColumn(named: "Downloads", path: \AppInfo.release.downloadCount)
                downloadCount.width(ideal: 40)

                //let forkCount = onumColumn(named: "Forks", path: \AppInfo.release.forkCount)
                //forkCount.width(ideal: 40)

                let issueCount = onumColumn(named: "Issues", path: \AppInfo.release.issueCount)
                issueCount.width(ideal: 40)

                let catgoryColumn = ostrColumn(named: "Category", path: \AppInfo.release.primaryCategoryIdentifier?.rawValue)
                catgoryColumn

                let authorColumn = strColumn(named: "Author", path: \AppInfo.release.developerName)
                authorColumn.width(ideal: 200)
            }
        }, rows: { self })
    }

    /// The currently selected item
    var itemSelection: Selection? {
        guard let item = items.first(where: { $0.id == selection }) else {
            return nil
        }

        return Selection.app(item)
    }
}



@available(macOS 12.0, *)
struct AppsTableView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = AppManager()
        manager.catalog = [
            AppCatalogItem.sample,
            //AppCatalogItem.sample,
            //AppCatalogItem.sample,
            //AppCatalogItem.sample,
            //AppCatalogItem.sample,
        ]

        //AppManager.default.catalog += AppManager.default.catalog

        //assert(AppManager.default.catalog.count > 0)

        return VStack {
            Text("App Catalog Table")
                .font(.largeTitle)
            AppsTableView(source: .constant(.fairapps), selection: .constant(AppCatalogItem.sample.id), category: .constant(.popular))
                .environmentObject(manager)
        }
    }
}

#endif // os(macOS)

