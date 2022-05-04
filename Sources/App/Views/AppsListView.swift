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

    var catalog: AppCatalog {
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
                // FIXME: this doen't change automatically unless some other state has changed; we'd need some kind of refresh timer to mark it as stale in order for the updated status to always be accurate
                Text("Updated \(Text(updated, format: .relative(presentation: .numeric, unitsStyle: .wide)))", bundle: .module, comment: "apps list bottom bar title describing when the catalog was last updated")
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
            .animation(.easeInOut, value: searchText)
            .onChange(of: searchTextSource) { searchString in
                selection = nil
                // a brief delay to allow for more responsive typing
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                    // check to ensure text has not changed since we scheduled it
                    if searchString == self.searchTextSource {
                        self.searchText = searchString
                        //if let topItem = appInfoItems(section: .top).first ?? appInfoItems(section: .all).first {
                            // proxy.scrollTo(topItem.id, anchor: .top) // doesn't seem to work
                        //}
                    }
                }
            }
//            .onChange(of: fairManager.refreshing) { refreshing in
//                dbg(wip("### REFRESHING:"), refreshing)
//            }
//            .onChange(of: scrollToSelection) { scrollToSelection in
//                // sadly, this doesn't seem to work
//                if scrollToSelection == true {
//                    dbg("scrolling to:", selection)
//                    proxy.scrollTo(selection, anchor: nil)
//                    self.scrollToSelection = false // reset once we have performed the scroll
//                }
//            }
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
                let hasScreenshots = $0.catalogMetadata.screenshotURLs?.isEmpty == false
                let hasCategory = $0.catalogMetadata.categories?.isEmpty == false
                // an app is in the "top" apps iff it has at least one screenshot and a category
                return (section == .top) == (hasScreenshots && hasCategory)
            })
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
                AppSectionItems(items: items, selection: $selection, searchTextSource: $searchTextSource)
            } header: {
                section.localizedTitle
            }
        } else {
            // nil section means don't sub-divide
            AppSectionItems(items: items, selection: $selection, searchTextSource: $searchTextSource)
        }
    }

    func appUpdateItems(section: AppsListView.AppUpdatesSection) -> [AppInfo] {
        let updatedItems: [AppInfo] = arrangedItems(source: source, sidebarSelection: sidebarSelection, sortOrder: sortOrder, searchText: searchText)

        switch section {
        case .available:
            return updatedItems
        case .recent:
            // get a list of all recently installed items that are not in the availabe updates set
            let installedItems = arrangedItems(source: source, sidebarSelection: .some(SidebarSelection(source: source, item: .installed)), sortOrder: sortOrder, searchText: searchText)
                .filter({ fairManager.sessionInstalls.contains($0.id) })
                .filter({ !updatedItems.contains($0 )})
            return installedItems
        }
    }

    /// The section holding the updated app items
    @ViewBuilder func appUpdatesSection(section: AppsListView.AppUpdatesSection) -> some View {
        let updatedApps = appUpdateItems(section: section)

        Section {
            AppSectionItems(items: updatedApps, selection: $selection, searchTextSource: $searchTextSource)
        } header: {
            section.localizedTitle
        }
    }
}

struct AppSectionItems : View {
    let items: [AppInfo]
    @Binding var selection: AppInfo.ID?
    /// The underlying source of the search text
    @Binding var searchTextSource: String

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

struct AppItemLabel : View {
    let item: AppInfo
    @EnvironmentObject var fairManager: FairManager

    var body: some View {
        label(for: item)
    }

    var installedVersion: String? {
        if item.isCask {
            return fairManager.homeBrewInv.appInstalled(item: item)
        } else {
            return fairManager.fairAppInv.appInstalled(item: item.catalogMetadata)
        }
    }

    private func label(for item: AppInfo) -> some View {
        return HStack(alignment: .center) {
            ZStack {
                fairManager.iconView(for: item, transition: true)

                if let progress = fairManager.fairAppInv.operations[item.id]?.progress {
                    FairProgressView(progress)
                        .progressViewStyle(PieProgressViewStyle(lineWidth: 50))
                        .foregroundStyle(Color.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)) // make sure the progress doesn't extend pask the icon bounds
                }
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: item.catalogMetadata.name)
                    .font(.headline)
                    .lineLimit(1)
                TintedLabel(title: Text(item.catalogMetadata.subtitle ?? item.catalogMetadata.name), symbol: (item.displayCategories.first ?? .utilities).symbol, tint: item.catalogMetadata.itemTintColor(), mode: .hierarchical)
                    .font(.subheadline)
                    .lineLimit(1)
                    .symbolVariant(.fill)
                //.help(category.text)
                HStack {
                    if item.catalogMetadata.permissions != nil {
                        item.catalogMetadata.riskLevel.riskLabel()
                            .help(item.catalogMetadata.riskLevel.riskSummaryText())
                            .labelStyle(.iconOnly)
                            .frame(width: 20)
                    }


                    if let catalogVersion = item.catalogMetadata.version {
                        Label {
                            Text(verbatim: catalogVersion)
                                .font(.subheadline)
                        } icon: {
                            if let installedVersion = self.installedVersion {
                                if installedVersion == catalogVersion {
                                    CatalogActivity.launch.info.systemSymbol
                                        .foregroundStyle(CatalogActivity.launch.info.tintColor ?? .accentColor) // same as launchButton()
                                        .help(Text("The latest version of this app is installed", bundle: .module, comment: "tooltip text for the checkmark in the apps list indicating that the app is currently updated to the latest version"))
                                } else {
                                    CatalogActivity.update.info.systemSymbol
                                        .foregroundStyle(CatalogActivity.update.info.tintColor ?? .accentColor) // same as updateButton()
                                        .help(Text("An update to this app is available", bundle: .module, comment: "tooltip text for the checkmark in the apps list indicating that the app is currently installed but there is an update available"))
                                }
                            }
                        }
                    }

                    if let versionDate = item.catalogMetadata.versionDate {
                        Text(versionDate, format: .relative(presentation: .numeric, unitsStyle: .narrow))
                            .font(.subheadline)
                    }

                }
                .lineLimit(1)
            }
            .allowsTightening(true)
        }
    }
}
