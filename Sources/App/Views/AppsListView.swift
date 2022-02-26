import FairApp

/// List version of the `AppsTableView` for list browsing mode.
@available(macOS 12.0, iOS 15.0, *)
struct AppsListView : View {
    let source: AppSource
    @EnvironmentObject var fairManager: FairManager
    @EnvironmentObject var fairAppInv: FairAppInventory
    @EnvironmentObject var homeBrewInv: HomebrewInventory
    @Binding var selection: AppInfo.ID?
    @Binding var scrollToSelection: Bool
    var sidebarSelection: SidebarSelection?
    @State var sortOrder: [KeyPathComparator<AppInfo>] = []
    @Binding var searchText: String

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
            .onChange(of: scrollToSelection) { scrollToSelection in
                // sadly, this doesn't seem to work
                if scrollToSelection == true {
                    dbg("scrolling to:", selection)
                    proxy.scrollTo(selection, anchor: nil)
                    self.scrollToSelection = false // reset once we have performed the scroll
                }
            }
            .searchable(text: $searchText)
            .animation(.easeInOut, value: searchText)
        }
    }

    func arrangedItems(source: AppSource, sidebarSelection: SidebarSelection?, sortOrder: [KeyPathComparator<AppInfo>], searchText: String) -> [AppInfo] {
        switch source {
        case .homebrew:
            return homeBrewInv.arrangedItems(sidebarSelection: sidebarSelection, sortOrder: sortOrder, searchText: searchText)
        case .fairapps:
            return fairAppInv.arrangedItems(sidebarSelection: sidebarSelection, sortOrder: sortOrder, searchText: searchText)
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

                let hasScreenshots = ($0.release.screenshotURLs ?? []).isEmpty == false
                let hasCategory = ($0.release.categories ?? []).isEmpty == false
                // an app is in the "top" apps iff it has at least one screenshot
                return (section == .top) == (hasScreenshots && hasCategory)
            })
    }

    @ViewBuilder func appListSection(section: AppsListView.AppListSection?) -> some View {
        let items = items(section: section)
        if let section = section {
            if !items.isEmpty {
                Section {
                    appSectionItems(items: items)
                } header: {
                    section.localizedTitle
                }
            }
        } else {
            // nil section means don't sub-divide
            appSectionItems(items: items)
        }
    }

    @ViewBuilder func appSectionItems(items: [AppInfo]) -> some View {
        ForEach(items.prefix(fairManager.maxDisplayItems)) { item in
            NavigationLink(tag: item.id, selection: $selection, destination: {
                CatalogItemView(info: item)
            }, label: {
                label(for: item)
                //.frame(minHeight: 44, maxHeight: 44) // attempt to speed up list rendering (doesn't seem to help)
            })
        }
    }

    func label(for item: AppInfo) -> some View {
        return HStack(alignment: .center) {
            ZStack {
                fairManager.iconView(for: item)
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
                    if let category = item.release.appCategories.first {
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

