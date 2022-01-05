import FairApp

/// List version of the `AppsTableView` for list browsing mode.
@available(macOS 12.0, iOS 15.0, *)
struct AppsListView : View {
    @Binding var source: AppSource
    @EnvironmentObject var fairManager: FairManager
    @EnvironmentObject var appManager: AppManager
    #if CASK_SUPPORT
    @EnvironmentObject var caskManager: CaskManager
    #endif
    @Binding var selection: AppInfo.ID?
    @Binding var category: AppManager.SidebarItem?
    @State var sortOrder: [KeyPathComparator<AppInfo>] = []
    @State var searchText: String = ""

    func arrangedItems(source: AppSource, category: AppManager.SidebarItem?, sortOrder: [KeyPathComparator<AppInfo>], searchText: String) -> [AppInfo] {
        switch source {
        #if CASK_SUPPORT
        case .homebrew:
            return caskManager.arrangedItems(category: category, sortOrder: sortOrder, searchText: searchText)
        #endif
        case .fairapps:
            return appManager.arrangedItems(category: category, sortOrder: sortOrder, searchText: searchText)
        }
    }

    var items: [AppInfo] {
        arrangedItems(source: source, category: category, sortOrder: sortOrder, searchText: searchText)
    }

    var body : some View {
        List {
            ForEach(items) { item in
                NavigationLink(tag: item.id, selection: $selection, destination: {
                    CatalogItemView(info: item)
                }, label: {
                    label(for: item)
                })
            }
        }
        .searchable(text: $searchText)
    }

    func label(for item: AppInfo) -> some View {
        return HStack(alignment: .center) {
            ZStack {
                item.release.iconImage()
                if let progress = fairManager.appManager.operations[item.id]?.progress {
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
                    item.release.riskLevel.riskLabel()
                        .help(item.release.riskLevel.riskSummaryText())
                        .labelStyle(.iconOnly)
                        .frame(width: 20)
                    Text(verbatim: item.releasedVersion?.versionStringExtended ?? "")
                        .font(.subheadline)
                    Text(item.release.versionDate ?? .distantPast, format: .relative(presentation: .numeric, unitsStyle: .narrow))
                }
                .lineLimit(1)
            }
            .allowsTightening(true)
        }
    }
}

