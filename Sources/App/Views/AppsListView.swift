import FairApp

/// List version of the `AppsTableView` for list browsing mode.
@available(macOS 12.0, iOS 15.0, *)
struct AppsListView : View {
    @EnvironmentObject var appManager: AppManager
    @Binding var selection: AppInfo.ID?
    @Binding var category: AppManager.SidebarItem?
    @State var sortOrder: [KeyPathComparator<AppInfo>] = []
    @State var searchText: String = ""
    @AppStorage("showPreReleases") private var showPreReleases = false

    var items: [AppInfo] {
        appManager.arrangedItems(category: category, sortOrder: sortOrder, searchText: searchText)
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
            item.release.iconImage()
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
                    item.release.riskLabel()
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

