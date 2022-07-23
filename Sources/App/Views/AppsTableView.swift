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

#if os(macOS)

@available(macOS 12.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct AppsTableView : View, ItemTableView {
    typealias TableRowValue = AppInfo
    @EnvironmentObject var fairManager: FairManager
    let source: AppSource
    @Binding var selection: AppInfo.ID?
    let sourceSelection: SourceSelection?
    @State private var sortOrder: [KeyPathComparator<AppInfo>] = []
    @Binding var searchText: String
    @State private var searchTextBuffer: String = ""

    var items: [AppInfo] {
        fairManager.arrangedItems(source: source, sourceSelection: sourceSelection, sortOrder: sortOrder, searchText: searchText)
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
            .id(sourceSelection) // attempt to prevent: “*** Assertion failure in -[NSTableRowHeightData _variableRemoveRowSpansInRange:], NSTableRowHeightData.m:1283 … [General] row validation for deletion of 1 rows starting at index 5”
            .font(Font.body.monospacedDigit())
            .focusedSceneValue(\.selection, .constant(itemSelection))
            .searchable(text: $searchTextBuffer)
            .task(id: searchTextBuffer) {
                do {
                    // buffer search typing by a short interval so we can type
                    // without the UI slowing down with live search results
                    // TODO: unify with ``AppsListView.updateSearchTextSource``
                    try await Task.sleep(interval: 0.2)
                    self.searchText = searchTextBuffer
                } catch {
                    dbg("search text cancelled: \(error)")
                }
            }
    }

    var tableView: some View {
        Table(selection: $selection, sortOrder: $sortOrder, columns: {
            Group {
                let imageColumn = TableColumn("", value: \AppInfo.app.iconURL, comparator: URLComparator()) { item in
                    fairManager.iconView(for: item)
                        .frame(width: 20, height: 20)
                }
                imageColumn
                    .width(20)
            }

            Group {
                let nameColumn = strColumn(named: "Name", path: \AppInfo.app.name)
                nameColumn.width(ideal: 125)

//                let subtitleColumn = ostrColumn(named: "Subtitle", path: \AppInfo.release.subtitle)
//                subtitleColumn

//                let descColumn = strColumn(named: "Description", path: \AppInfo.release.localizedDescription)
//                descColumn
            }

            Group {
                let versionColumn = ostrColumn(named: "Version", path: \AppInfo.app.version)
                versionColumn.width(ideal: 60)

//                let installedColumn = ostrColumn(named: "Installed", path: \AppInfo.installedVersionString)
//                installedColumn.width(ideal: 60)

                let sizeColumn = TableColumn("Size", value: \AppInfo.app.size, comparator: optionalComparator(0)) { item in
                    Text((item.app.size ?? 0).localizedByteCount())
                        .multilineTextAlignment(.trailing)
                }

                sizeColumn.width(ideal: 60)

//                let coreSizeColumn = onumColumn(named: "Core Size", path: \AppInfo.app.coreSize)
//                coreSizeColumn

                let riskColumn = TableColumn("Risk", value: \AppInfo.app.riskLevel) { item in
                    item.app.riskLevel.riskLabel()
                        .help(item.app.riskLevel.riskSummaryText())
                }
                riskColumn.width(ideal: 125)

                let dateColumn = TableColumn("Date", value: \AppInfo.app.versionDate, comparator: optionalDateComparator) { item in
                    Text(item.app.versionDate?.localizedDate(dateStyle: .medium, timeStyle: .none) ?? "")
                        .multilineTextAlignment(.trailing)
                }
                dateColumn

            }

            Group { // ideally, we'd guard for whether we are using Homebrew casks, but table builders don't support conditional statements: “Closure containing control flow statement cannot be used with result builder 'TableColumnBuilder'”
                let starCount = onumColumn(named: "Stars", path: \AppInfo.app.stats?.starCount)
                starCount.width(ideal: 40)

                let downloadCount = onumColumn(named: "Downloads", path: \AppInfo.app.stats?.downloadCount)
                downloadCount.width(ideal: 40)

                //let forkCount = onumColumn(named: "Forks", path: \AppInfo.app.stats?.forkCount)
                //forkCount.width(ideal: 40)

                let issueCount = onumColumn(named: "Issues", path: \AppInfo.app.stats?.issueCount)
                issueCount.width(ideal: 40)

                let catgoryColumn = ostrColumn(named: "Category", path: \AppInfo.app.primaryCategoryIdentifier?.rawValue)
                catgoryColumn

                let authorColumn = ostrColumn(named: "Author", path: \AppInfo.app.developerName)
                authorColumn.width(ideal: 200)
            }
        }, rows: { self })
    }

    /// The currently selected item
    var itemSelection: AppInfo? {
        guard let item = items.first(where: { $0.id == selection }) else {
            return nil
        }

        return item
    }
}

#endif // os(macOS)
