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

/// List version of the `AppsTableView` for list browsing mode.
@available(macOS 12.0, iOS 15.0, *)
struct AppsListView : View {
    let source: AppSource
    let sidebarSelection: SidebarSelection?

    @EnvironmentObject var fairManager: FairManager

    @Binding var selection: AppInfo.ID?
    @Binding var scrollToSelection: Bool

    /// The underlying source of the search text
    @Binding var searchTextSource: String

    /// The filter text for displayed items
    @State private var searchText: String = ""
    @State private var sortOrder: [KeyPathComparator<AppInfo>] = []


    @ViewBuilder var body : some View {
        VStack(spacing: 0) {
            appsList
            Divider()
            bottomBar
        }
    }

    @ViewBuilder var bottomBar: some View {
        let catalog = fairManager.inventory(for: source)
        HStack {
            Group {
                if let updated = catalog?.catalogUpdated {
                    // to keep the updated date correct, update the label every minute
                    Text("Updated \(Text(updated, format: .relative(presentation: .numeric, unitsStyle: .wide)))", bundle: .module, comment: "apps list bottom bar title describing when the catalog was last updated")
                    //.refreshingEveryMinute()
                } else {
                    Text("Not updated recently", bundle: .module, comment: "apps list bottom bar title")
                }
            }
            .font(.footnote)
            .help(Text("The catalog was last updated on \(Text(catalog?.catalogUpdated ?? .distantPast, format: Date.FormatStyle().year(.defaultDigits).month(.wide).day(.defaultDigits).weekday(.wide).hour(.conversationalDefaultDigits(amPM: .wide)).minute(.defaultDigits).second(.defaultDigits)))", bundle: .module, comment: "apps list bottom bar help text"))
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(5)
    }

    @ViewBuilder var appsList : some View {
        ScrollViewReader { proxy in
            List {
                if sidebarSelection?.item == .top {
                    // appListSection(section: nil, source: source)
                    ForEach(AppListSection.allCases) { section in
                        appListSection(section: section, source: source)
                    }
                } else if sidebarSelection?.item == .updated {
                    ForEach(AppUpdatesSection.allCases) { section in
                        appUpdatesSection(section: section)
                    }
                } else {
                    // installed list don't use sections
                    appListSection(section: nil, source: source)
                }
            }
            .searchable(text: $searchTextSource)
            .animation(.easeInOut, value: searchTextSource)
            .onChange(of: searchTextSource, debounce: 0.18, priority: .userInitiated, perform: updateSearchTextSource) // a brief delay to allow for more responsive typing
        }
    }

    @MainActor func updateSearchTextSource(_ searchTextSource: String) async {
        withAnimation {
            self.searchText = searchTextSource
            if searchText.trimmed().isEmpty == false,
               let initialSearchResult = self.firstAppID {
                dbg("setting initial selection:", initialSearchResult)
                self.selection = initialSearchResult
            }
        }
    }

    enum AppListSection : CaseIterable, Identifiable, Hashable {
        case top
        case all

        var id: Self { self }

        var localizedTitle: Text {
            switch self {
            case .top: return Text("Top Apps", bundle: .module, comment: "apps list section header text")
            case .all: return Text("All Apps", bundle: .module, comment: "apps list section header text")
            }
        }
    }

    enum AppUpdatesSection : CaseIterable, Identifiable, Hashable {
        case available
        case recent

        var id: Self { self }

        var localizedTitle: Text {
            switch self {
            case .available: return Text("Available Updates", bundle: .module, comment: "apps list section header text")
            case .recent: return Text("Recently Updated", bundle: .module, comment: "apps list section header text")
            }
        }
    }

    /// Changes the selection to the first available app
    var firstAppID: AppCatalogItem.ID? {
        for section in AppListSection.allCases {
            let items = appInfoItems(section: section)
            if let firstItem = items.first {
                return firstItem.id
            }
        }
        return nil
    }

    func appInfoItems(section: AppListSection?) -> [AppInfo] {
        arrangedItems(source: source, sidebarSelection: sidebarSelection, sortOrder: sortOrder, searchText: searchText)
            .filter({
                if section == nil { return true } // nil sections means unfiltered
                let hasScreenshots = $0.app.screenshotURLs?.isEmpty == false
                let hasCategory = $0.app.categories?.isEmpty == false
                // an app is in the "top" apps iff it has at least one screenshot and a category
                return (section == .top) == (hasScreenshots && hasCategory)
            })
            .uniquing(by: \.id) // ensure there are no duplicates with the same id
    }

    func arrangedItems(source: AppSource, sidebarSelection: SidebarSelection?, sortOrder: [KeyPathComparator<AppInfo>], searchText: String) -> [AppInfo] {
        prf("arranging: \(source.rawValue)") {
            fairManager.arrangedItems(source: source, sidebarSelection: sidebarSelection, sortOrder: sortOrder, searchText: searchText)
        }
    }

    @ViewBuilder func appListSection(section: AppsListView.AppListSection?, source: AppSource) -> some View {
        let items = appInfoItems(section: section)
        //let _ = dbg("items for:", section, wip(items.count))
        if fairManager.refreshing == true || items.isEmpty == false {
            if let section = section {
                Section {
                    AppSectionItems(items: items, source: source, selection: $selection, searchTextSource: searchTextSource)
                } header: {
                    HStack {
                        section.localizedTitle
                    }
                }
            } else {
                // nil section means don't sub-divide
                AppSectionItems(items: items, source: source, selection: $selection, searchTextSource: searchTextSource)
            }
        }
    }

    func appUpdateItems(section: AppsListView.AppUpdatesSection) -> [AppInfo] {
        let updatedItems: [AppInfo] = arrangedItems(source: source, sidebarSelection: sidebarSelection, sortOrder: sortOrder, searchText: searchText)
        let updatedItemIDs = updatedItems.map(\.id).set()

        switch section {
        case .available:
            return updatedItems
        case .recent:
            // get a list of all recently installed items that are not in the availabe updates set
            let installedItems = arrangedItems(source: source, sidebarSelection: .some(SidebarSelection(source: source, item: .installed)), sortOrder: sortOrder, searchText: searchText)
                .filter({ fairManager.sessionInstalls.contains($0.id) })
                .filter({ !updatedItemIDs.contains($0.id) })
            return installedItems
        }
    }

    /// The section holding the updated app items
    @ViewBuilder func appUpdatesSection(section: AppsListView.AppUpdatesSection) -> some View {
        let updatedApps = appUpdateItems(section: section)
        Section {
            AppSectionItems(items: updatedApps, source: source, selection: $selection, searchTextSource: searchTextSource)
        } header: {
            section.localizedTitle
        }
    }
}

struct AppSectionItems : View {
    let items: [AppInfo]
    let source: AppSource
    @Binding var selection: AppInfo.ID?
    /// The underlying source of the search text
    let searchTextSource: String

    @EnvironmentObject var fairManager: FairManager

    /// The number of items to initially display to keep the list rendering responsive;
    /// when the list is scrolled to the bottom, this count will increment to give the appearance of infinite scrolling
    @State private var displayCount = 50

    var body: some View {
        sectionContents()
        sectionFooter()
    }

    @ViewBuilder func sectionContents() -> some View {
        ForEach(items.prefix(displayCount)) { item in
            NavigationLink(tag: item.id, selection: $selection, destination: {
                CatalogItemView(info: item, source: source)
            }, label: {
                AppItemLabel(item: item, source: source)
            })
        }
    }

    @ViewBuilder func sectionFooter() -> some View {
        let itemCount = items.count

        Group {
            if itemCount == 0 && fairManager.refreshing == true {
                Text("Loading…", bundle: .module, comment: "apps list placeholder text while the catalog is loading")
            } else if itemCount == 0 && searchTextSource.isEmpty {
                Text("No results", bundle: .module, comment: "apps list placeholder text where there are no results to display")
            } else if itemCount == 0 {
                // nothing; we don't know if it was empty or not
                Text("No apps", bundle: .module, comment: "apps list placeholder text where there are no results to display")
            } else if itemCount > displayCount {
                Text("More…", bundle: .module, comment: "apps list text at the bottom of the list when there are more results to show")
                    .id((items.last?.id.rawValue ?? "") + "_moreitems") // the id needs to change so onAppear is called when we see this item again
                    .onAppear {
                        dbg("showing more items (\(displayCount) of \(items.count))")
                        DispatchQueue.main.async {
                            // displayCount += 50
                            withAnimation {
                                self.displayCount += max(self.displayCount, 1) // increase the total display count
                            }
                        }
                    }
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
}
