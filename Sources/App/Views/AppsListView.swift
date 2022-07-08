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

    var catalog: AppInventoryCatalog {
        switch source {
        case .homebrew: return fairManager.homeBrewInv
        case .fairapps: return fairManager.fairAppInv
        }
    }

    @ViewBuilder var body : some View {
        VStack(spacing: 0) {
            appsList
            Divider()
            bottomBar
        }
    }

    @ViewBuilder var bottomBar: some View {
        Group {
            if let updated = catalog.catalogUpdated {
                // to keep the updated date correct, update the label every minute
                Text("Updated \(Text(updated, format: .relative(presentation: .numeric, unitsStyle: .wide)))", bundle: .module, comment: "apps list bottom bar title describing when the catalog was last updated")
                    //.refreshingEveryMinute()
            } else {
                Text("Not updated recently", bundle: .module, comment: "apps list bottom bar title")
            }
        }
        .font(.caption)
        .help(Text("The catalog was last updated on \(Text(catalog.catalogUpdated ?? .distantPast, format: Date.FormatStyle().year(.defaultDigits).month(.wide).day(.defaultDigits).weekday(.wide).hour(.conversationalDefaultDigits(amPM: .wide)).minute(.defaultDigits).second(.defaultDigits)))", bundle: .module, comment: "apps list bottom bar help text"))
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(4)
    }

    @ViewBuilder var appsList : some View {
        ScrollViewReader { proxy in
            List {
                if sidebarSelection?.item == .top {
                    ForEach(AppListSection.allCases) { section in
                        appListSection(section: section)
                    }
                } else if sidebarSelection?.item == .updated {
                    ForEach(AppUpdatesSection.allCases) { section in
                        appUpdatesSection(section: section)
                    }
                } else {
                    // installed list don't use sections
                    appListSection(section: nil)
                }
            }
            .searchable(text: $searchTextSource)
            .animation(.easeInOut, value: searchTextSource)
            .task(id: searchTextSource) {
                // a brief delay to allow for more responsive typing
                do {
                    // buffer search typing by a short interval so we can type
                    // without the UI slowing down with live search results
                    try await Task.sleep(interval: 0.2)
                    withAnimation {
                        self.searchText = searchTextSource
                    }
                } catch {
                    dbg("search text cancelled: \(error)")
                }
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
        switch source {
        case .homebrew:
            return fairManager.homeBrewInv.arrangedItems(sidebarSelection: sidebarSelection, sortOrder: sortOrder, searchText: searchText)
        case .fairapps:
            return fairManager.fairAppInv.arrangedItems(sidebarSelection: sidebarSelection, sortOrder: sortOrder, searchText: searchText)
        }
    }

    @ViewBuilder func appListSection(section: AppsListView.AppListSection?) -> some View {
        let items = appInfoItems(section: section)
        if let section = section {
            Section {
                AppSectionItems(items: items, selection: $selection, searchTextSource: searchTextSource)
            } header: {
                section.localizedTitle
            }
        } else {
            // nil section means don't sub-divide
            AppSectionItems(items: items, selection: $selection, searchTextSource: searchTextSource)
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
            AppSectionItems(items: updatedApps, selection: $selection, searchTextSource: searchTextSource)
        } header: {
            section.localizedTitle
        }
    }
}


struct AppSectionItems : View {
    let items: [AppInfo]
    @Binding var selection: AppInfo.ID?
    /// The underlying source of the search text
    let searchTextSource: String

    @EnvironmentObject var fairManager: FairManager

    /// The number of items to initially display to keep the list rendering responsive;
    /// when the list is scrolled to the bottom, this count will increment to give the appearance of infinite scrolling
    @State private var displayCount = 25

    var body: some View {
        sectionContents()
        sectionFooter()
    }

    @ViewBuilder func sectionContents() -> some View {
        ForEach(items.prefix(displayCount)) { item in
            NavigationLink(tag: item.id, selection: $selection, destination: {
                CatalogItemView(info: item)
            }, label: {
                AppItemLabel(item: item)
                    .frame(height: 50)
            })
        }
    }

    @ViewBuilder func sectionFooter() -> some View {
        let itemCount = items.count

        Group {
            if itemCount == 0 && refreshing == true {
                Text("Loading…", bundle: .module, comment: "apps list placeholder text while the catalog is loading")
            } else if itemCount == 0 && searchTextSource.isEmpty {
                Text("No results", bundle: .module, comment: "apps list placeholder text where there are no results to display")
            } else if itemCount == 0 {
                // nothing; we don't know if it was empty or not
            } else if itemCount > displayCount {
                Text("More…", bundle: .module, comment: "apps list text at the bottom of the list when there are more results to show")
                    .id((items.last?.id.rawValue ?? "") + "_moreitems") // the id needs to change so onAppear is called when we see this item again
                    .onAppear {
                        dbg("showing more items (\(displayCount) of \(items.count))")
                        DispatchQueue.main.async {
                            // displayCount += 50
                            withAnimation {
                                self.displayCount += self.displayCount + 1 // increase the total display count
                            }
                        }
                    }
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }

    /// Returns true is there are any refreshes in progress
    var refreshing: Bool {
        fairManager.fairAppInv.updateInProgress > 0 || fairManager.homeBrewInv.updateInProgress > 0
    }
}

