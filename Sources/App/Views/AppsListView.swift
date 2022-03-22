import FairApp

/// List version of the `AppsTableView` for list browsing mode.
@available(macOS 12.0, iOS 15.0, *)
struct AppsListView : View {
    let source: AppSource
    let sidebarSelection: SidebarSelection?

    @EnvironmentObject var fairManager: FairManager
    @EnvironmentObject var fairAppInv: FairAppInventory
    @EnvironmentObject var homeBrewInv: HomebrewInventory

    @Binding var selection: AppInfo.ID?
    @Binding var scrollToSelection: Bool
    /// The underlying source of the search text
    @Binding var searchTextSource: String

    /// The filter text for displayed items
    @State private var searchText: String = ""
    @State private var sortOrder: [KeyPathComparator<AppInfo>] = []

    //static let topID = UUID()

    @ViewBuilder var body : some View {
        ScrollViewReader { proxy in
            List {
                if sidebarSelection?.item == .top {
                    ForEach(AppListSection.allCases) { section in
                        appListSection(section: section)
                    }
                } else {
                    // installed & updated don't use sections
                    appListSection(section: nil)
                }
            }
            .searchable(text: $searchText)
            .animation(.easeInOut, value: searchText)
            .onChange(of: searchTextSource) { searchString in
                selection = nil
                DispatchQueue.main.async {
                    searchText = searchString
                    // proxy.scrollTo(Self.topID, anchor: .top) // doesn't work
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
            case .top: return Text("Top Apps")
            case .all: return Text("All Apps")
            }
        }
    }

    func items(section: AppListSection?) -> [AppInfo] {
        arrangedItems(source: source, sidebarSelection: sidebarSelection, sortOrder: sortOrder, searchText: searchText)
            .filter({
                if section == nil { return true } // nil sections means unfiltered
                let hasScreenshots = $0.release.screenshotURLs?.isEmpty == false
                let hasCategory = $0.release.categories?.isEmpty == false
                // an app is in the "top" apps iff it has at least one screenshot and a category
                return (section == .top) == (hasScreenshots && hasCategory)
            })
    }

    func arrangedItems(source: AppSource, sidebarSelection: SidebarSelection?, sortOrder: [KeyPathComparator<AppInfo>], searchText: String) -> [AppInfo] {
        switch source {
        case .homebrew:
            return homeBrewInv.arrangedItems(sidebarSelection: sidebarSelection, sortOrder: sortOrder, searchText: searchText)
        case .fairapps:
            return fairAppInv.arrangedItems(sidebarSelection: sidebarSelection, sortOrder: sortOrder, searchText: searchText)
        }
    }

    @ViewBuilder func appListSection(section: AppsListView.AppListSection?) -> some View {
        let items = items(section: section)
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
}

struct AppSectionItems : View {
    let items: [AppInfo]
    @Binding var selection: AppInfo.ID?
    /// The underlying source of the search text
    @Binding var searchTextSource: String

    @EnvironmentObject var fairManager: FairManager
    @EnvironmentObject var fairAppInv: FairAppInventory
    @EnvironmentObject var homeBrewInv: HomebrewInventory

    /// The number of items to initially display to keep the list rendering responsive;
    /// when the list is scrolled to the bottom, this count will increment to give the appearance of infinite scrolling
    @State private var displayCount = 25

    var body: some View {
        sectionContents
    }

    @ViewBuilder var sectionContents: some View {
        ForEach(items.prefix(displayCount)) { item in
            NavigationLink(tag: item.id, selection: $selection, destination: {
                CatalogItemView(info: item)
            }, label: {
                label(for: item)
                //.frame(minHeight: 44, maxHeight: 44) // attempt to speed up list rendering (doesn't seem to help)
            })
        }

        let itemCount = items.count

        Group {
            if itemCount == 0 && refreshing == true {
                Text("Loading…")
            } else if itemCount == 0 && searchTextSource.isEmpty {
                Text("No results")
            } else if itemCount == 0 {
                // nothing; we don't know if it was empty or not
            } else if itemCount > displayCount {
                Text("More…")
                    .id((items.last?.id.rawValue ?? "") + "_moreitems") // the id needs to change so onAppear is called when we see this item again
                    .onAppear {
                        dbg("showing more items (\(displayCount) of \(items.count))")
                        DispatchQueue.main.async {
                            displayCount += 50
                        }
                    }
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }

    /// Returns true is there are any refreshes in progress
    var refreshing: Bool {
        self.fairAppInv.updateInProgress > 0 || self.homeBrewInv.updateInProgress > 0
    }

    func label(for item: AppInfo) -> some View {
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
                Text(verbatim: item.release.name)
                    .font(.headline)
                    .lineLimit(1)
                HStack {
                    if let category = item.displayCategories.first {
                        // category.tintedLabel
                        TintedLabel(title: category.text, systemName: category.symbol.symbolName, tint: item.release.itemTintColor(), mode: .hierarchical)
                            .symbolVariant(.fill)
                            .labelStyle(.iconOnly)
                            .help(category.text)
                            .frame(width: 20)
                    }
                    Text(verbatim: item.release.subtitle ?? "")
                        .font(.subheadline)
                        .lineLimit(1)
                }
                HStack {
                    if item.release.permissions != nil {
                        item.release.riskLevel.riskLabel()
                            .help(item.release.riskLevel.riskSummaryText())
                            .labelStyle(.iconOnly)
                            .frame(width: 20)
                    }

                    Text(verbatim: item.release.version ?? "")
                        .font(.subheadline)

                    if let versionDate = item.release.versionDate {
                        Text(versionDate, format: .relative(presentation: .numeric, unitsStyle: .narrow))
                    }

                }
                .lineLimit(1)
            }
            .allowsTightening(true)
        }
        .frame(height: 50)
    }
}
