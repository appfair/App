import FairApp

#if os(macOS)

@available(macOS 12.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct AppsTableView : View, ItemTableView {
    typealias TableRowValue = AppInfo
    @EnvironmentObject var fairManager: FairManager
    @EnvironmentObject var fairAppInv: FairAppInventory
    @EnvironmentObject var homeBrewInv: HomebrewInventory
    let source: AppSource
    @Binding var selection: AppInfo.ID?
    let sidebarSelection: SidebarSelection?
    @State var sortOrder: [KeyPathComparator<AppInfo>] = []
    @Binding var searchText: String

    var items: [AppInfo] {
        switch source {
        case .homebrew:
            return homeBrewInv.arrangedItems(sidebarSelection: sidebarSelection, sortOrder: sortOrder, searchText: searchText)
        case .fairapps:
            return fairAppInv.arrangedItems(sidebarSelection: sidebarSelection, sortOrder: sortOrder, searchText: searchText).map({ AppInfo(catalogMetadata: $0) })
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
            .id(sidebarSelection) // attempt to prevent: “*** Assertion failure in -[NSTableRowHeightData _variableRemoveRowSpansInRange:], NSTableRowHeightData.m:1283 … [General] row validation for deletion of 1 rows starting at index 5”
            .font(Font.body.monospacedDigit())
            .focusedSceneValue(\.selection, .constant(itemSelection))
            .searchable(text: $searchText)
    }

    var tableView: some View {
        Table(selection: $selection, sortOrder: $sortOrder, columns: {
            Group {
                let imageColumn = TableColumn("", value: \AppInfo.catalogMetadata.iconURL, comparator: URLComparator()) { item in
                    fairManager.iconView(for: item)
                        .frame(width: 20, height: 20)
                }
                imageColumn
                    .width(20)
            }

            Group {
                let nameColumn = strColumn(named: "Name", path: \AppInfo.catalogMetadata.name)
                nameColumn.width(ideal: 125)

//                let subtitleColumn = ostrColumn(named: "Subtitle", path: \AppInfo.release.subtitle)
//                subtitleColumn

//                let descColumn = strColumn(named: "Description", path: \AppInfo.release.localizedDescription)
//                descColumn
            }

            Group {
                let versionColumn = ostrColumn(named: "Version", path: \AppInfo.catalogMetadata.version)
                versionColumn.width(ideal: 60)

//                let installedColumn = ostrColumn(named: "Installed", path: \AppInfo.installedVersionString)
//                installedColumn.width(ideal: 60)

                let sizeColumn = TableColumn("Size", value: \AppInfo.catalogMetadata.size, comparator: optionalComparator(0)) { item in
                    Text((item.catalogMetadata.size ?? 0).localizedByteCount())
                        .multilineTextAlignment(.trailing)
                }

                sizeColumn.width(ideal: 60)

//                let coreSizeColumn = onumColumn(named: "Core Size", path: \AppInfo.catalogMetadata.coreSize)
//                coreSizeColumn

                let riskColumn = TableColumn("Risk", value: \AppInfo.catalogMetadata.riskLevel) { item in
                    item.catalogMetadata.riskLevel.riskLabel()
                        .help(item.catalogMetadata.riskLevel.riskSummaryText())
                }
                riskColumn.width(ideal: 125)

                let dateColumn = TableColumn("Date", value: \AppInfo.catalogMetadata.versionDate, comparator: optionalDateComparator) { item in
                    Text(item.catalogMetadata.versionDate?.localizedDate(dateStyle: .medium, timeStyle: .none) ?? "")
                        .multilineTextAlignment(.trailing)
                }
                dateColumn

            }

            Group { // ideally, we'd guard for whether we are using Homebrew casks, but table builders don't support conditional statements: “Closure containing control flow statement cannot be used with result builder 'TableColumnBuilder'”
                let starCount = onumColumn(named: "Stars", path: \AppInfo.catalogMetadata.starCount)
                starCount.width(ideal: 40)

                let downloadCount = onumColumn(named: "Downloads", path: \AppInfo.catalogMetadata.downloadCount)
                downloadCount.width(ideal: 40)

                //let forkCount = onumColumn(named: "Forks", path: \AppInfo.catalogMetadata.forkCount)
                //forkCount.width(ideal: 40)

                let issueCount = onumColumn(named: "Issues", path: \AppInfo.catalogMetadata.issueCount)
                issueCount.width(ideal: 40)

                let catgoryColumn = ostrColumn(named: "Category", path: \AppInfo.catalogMetadata.primaryCategoryIdentifier?.rawValue)
                catgoryColumn

                let authorColumn = ostrColumn(named: "Author", path: \AppInfo.catalogMetadata.developerName)
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

#endif // os(macOS)
