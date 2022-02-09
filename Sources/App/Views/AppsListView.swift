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

    func arrangedItems(source: AppSource, sidebarSelection: SidebarSelection?, sortOrder: [KeyPathComparator<AppInfo>], searchText: String) -> [AppInfo] {
        switch source {
        case .homebrew:
            return homeBrewInv.arrangedItems(sidebarSelection: sidebarSelection, sortOrder: sortOrder, searchText: searchText)
        case .fairapps:
            return fairAppInv.arrangedItems(sidebarSelection: sidebarSelection, sortOrder: sortOrder, searchText: searchText)
        }
    }

    var items: [AppInfo] {
        arrangedItems(source: source, sidebarSelection: sidebarSelection, sortOrder: sortOrder, searchText: searchText)
    }

    var body : some View {
        ScrollViewReader { proxy in
            List {
                ForEach(items.prefix(fairManager.maxDisplayItems)) { item in
                    NavigationLink(tag: item.id, selection: $selection, destination: {
                        CatalogItemView(info: item)
                    }, label: {
                        label(for: item)
                            //.frame(minHeight: 44, maxHeight: 44) // attempt to speed up list rendering (doesn't seem to help)
                    })
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
                    if let group = item.release.appCategories.first?.groupings.first {
                        group.tintedLabel
                            .labelStyle(.iconOnly)
                            .help(group.text)
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

