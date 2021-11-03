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
import FairApp
import SwiftUI

@available(macOS 12.0, iOS 15.0, *)
struct CatalogItemView: View {
    let info: AppInfo
    var previewMode: Bool = false

    @EnvironmentObject var appManager: AppManager
    @Environment(\.openURL) var openURLAction

    @State var currentActivity: Activity? = nil
    @State var progress = Progress(totalUnitCount: 1)
    @State var readme: AttributedString? = nil
    @State var confirmations: [Activity: Bool] = [:]

    var body: some View {
        catalogBody()
            .task {
                await fetchREADME()
            }
    }

    func catalogBody() -> some View {
        catalogBodyFixed()
        //catalogBodyScrolling()
    }

    func catalogBodyFixed() -> some View {
        VStack {
            pinnedHeaderView()
                .padding(.top)
                .background(Material.ultraThinMaterial)
            catalogSummaryCards()
            Divider()
            catalogOverview()
            appPreviewImages()
        }
        //        .background(Material.ultraThinMaterial)
    }

    func catalogBodyScrolling() -> some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(pinnedViews: [.sectionHeaders]) {
                Section {
                    catalogSummaryCards()
                    Divider()
                    catalogOverview()
                    appPreviewImages()
                } header: {
                    pinnedHeaderView()
                        .padding(.top)
                        .background(Material.ultraThinMaterial)
                }
            }
        }
        // .background(Material.ultraThinMaterial)
    }

    func pinnedHeaderView() -> some View {
        VStack {
            catalogHeader()
            Divider()
            catalogActionButtons()
            Divider()
        }
    }

    func appPreviewImages() -> some View {
        EmptyView()
        // groupBox(title: Text("Previews")) {
        //     catalogPreviewImages()
        // }
    }

    func starsCard() -> some View {
        summarySegment {
            card(
                Text("Stars"),
                numberView(number: .decimal, \.starCount),
                histogramView(\.starCount)
            )
        }
    }

    func downloadsCard() -> some View {
        summarySegment {
            card(
                Text("Downloads"),
                numberView(number: .decimal, \.downloadCount),
                histogramView(\.downloadCount)
            )
        }
    }

    func sizeCard() -> some View {
        summarySegment {
            card(
                Text("Size"),
                numberView(size: .file, \.fileSize),
                histogramView(\.fileSize)
            )
        }
    }

    func coreSizeCard() -> some View {
        summarySegment {
            card(
                Text("Core Size"),
                numberView(size: .file, \.coreSize),
                histogramView(\.coreSize)
            )
        }
    }

    func watchersCard() -> some View {
        summarySegment {
            card(
                Text("Watchers"),
                numberView(number: .decimal, \.watcherCount),
                histogramView(\.watcherCount)
            )
        }
    }

    func issuesCard() -> some View {
        summarySegment {
            card(
                Text("Issues"),
                numberView(number: .decimal, \.issueCount),
                histogramView(\.issueCount)
            )
        }
    }

    func releaseDateCard() -> some View {
        summarySegment {
            card(
                Text("Updated"),
                Text(info.release.versionDate ?? Date(), format: .relative(presentation: .numeric, unitsStyle: .abbreviated)),
                histogramView(\.issueCount)
            )
        }
    }

    func catalogSummaryCards() -> some View {
        HStack(alignment: .center) {
            starsCard()
            Divider()
            releaseDateCard()
            Divider()
            downloadsCard()
            Divider()
            sizeCard()
            Divider()
            issuesCard()
            //watchersCard()
        }
        .frame(height: 54)
    }

    func linkTextField(_ title: Text, url: URL, linkText: String? = nil) -> some View {
        TextField(text: .constant(linkText ?? url.absoluteString)) {
            title.link(to: url)
                .font(Font.body)
        }
    }

    func detailsView() -> some View {
        ScrollView(.vertical, showsIndicators: true) {
            Form {
                linkTextField(Text("Discussions"), url: info.release.discussionsURL)
                    .help(Text("Opens link to the discussions page for this app at: \(info.release.discussionsURL.absoluteString)"))
                linkTextField(Text("Issues"), url: info.release.issuesURL)
                    .help(Text("Opens link to the issues page for this app at: \(info.release.issuesURL.absoluteString)"))
                linkTextField(Text("Source Code"), url: info.release.sourceURL)
                    .help(Text("Opens link to source code repository for this app at: \(info.release.sourceURL.absoluteString)"))
                linkTextField(Text("Seal"), url: info.release.fairsealURL, linkText: String(info.release.sha256 ?? ""))
                    .help(Text("Lookup fairseal at: \(info.release.fairsealURL)"))
                linkTextField(Text("Developer"), url: info.release.developerURL, linkText: item.developerName)
                    .help(Text("Searches for this developer at: \(info.release.developerURL)"))
            }
            .font(Font.body.monospaced())
            .textFieldStyle(.plain)
            .truncationMode(.middle)
        }

        //        VStack {
        //            Group {
        //                Text("Developer: \(item.developerName)")
        //                Text("Size: \(item.size)")
        //                Text("BundleIdentifier: \(item.bundleIdentifier)")
        //                //Text("Categories: \(item.categories ?? [])")
        //                //Text("SHA256: \(item.sha256 ?? "")")
        //            }
        //            Group {
        //                Text("ForkCount: \(item.forkCount ?? 0)")
        //                Text("issueCount: \(item.issueCount ?? 0)")
        //                Text("starCount: \(item.starCount ?? 0)")
        //                Text("watcherCount: \(item.watcherCount ?? 0)")
        //                Text("downloadCount: \(item.downloadCount ?? 0)")
        //            }
        //        }
        //        .textSelection(.enabled)
    }

    func groupBox<V: View, L: View>(title: Text, trailing: L, @ViewBuilder content: () -> V) -> some View {
        GroupBox(content: {
            content()
        }, label: {
            HStack {
                title
                Spacer()
                trailing
            }
                .font(Font.headline)
                .lineLimit(1)
        })
            .groupBoxStyle(.automatic)
    }

    func catalogPreviewImages() -> some View {
        ScrollView(.horizontal, showsIndicators: true) {
            Image(systemName: "a")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }

    func catalogOverview() -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                groupBox(title: Text("Description"), trailing: EmptyView()) {
                    ScrollView {
                        descriptionSummary()
                            .redacted(reason: wip(.placeholder))
                    }
                }
                .padding()
            }

            VStack(alignment: .leading) {
                groupBox(title: Text("Permissions: ") + item.riskText().fontWeight(.regular), trailing: item.riskLabel()
                            .labelStyle(IconOnlyLabelStyle())
                            .padding(.trailing)) {
                    permissionsList()
                        .frame(minHeight: 20)
                }
                .padding()

                groupBox(title: Text("Details"), trailing: EmptyView()) {
                    detailsView()
                        .frame(minHeight: 20)
                }
                .padding()
            }
        }
    }

    func descriptionSummary() -> some View {
        // TODO: load the content from the README.md
        Text(atx: """
        This is an app that does *stuff*, a whole lot of stuff, and does it really well.

        Installing this app will make you smarter and stronger, and generally better.
        """)
            .font(.body)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity)
    }

    func permissionListItem(permission: AppPermission) -> some View {
        let entitlement = permission.type

        var title = entitlement.localizedInfo.title
        if !permission.usageDescription.isEmpty {
            title = title + Text(" – ") + Text(permission.usageDescription).foregroundColor(.secondary).italic()
        }

        return title.label(symbol: entitlement.localizedInfo.symbol)
            .listItemTint(ListItemTint.monochrome)
            .symbolRenderingMode(SymbolRenderingMode.monochrome)
            .lineLimit(1)
            .truncationMode(.head)
            .textSelection(.enabled)
            .help(entitlement.localizedInfo.info + ": " + permission.usageDescription)
    }

    /// The entitlements that will appear in the list.
    /// These filter out entitlements that are pre-requisites (e.g., sandboxing) as well as harmless entitlements (e.g., JIT).
    var listedPermissions: [AppPermission] {
        item.orderedPermissions(filterCategories: [.harmless, .prerequisite])
    }

    func permissionsList() -> some View {
        List {
            ForEach(listedPermissions, id: \.type, content: permissionListItem)
        }
        .conditionally {
#if os(macOS)
            $0.listStyle(.bordered(alternatesRowBackgrounds: true))
#endif
        }
    }

    func catalogVersionRow() -> some View {
        Text(info.releasedVersion?.versionDescription ?? "")
    }

    func catalogAuthorRow() -> some View {
        Group {
            if info.release.developerName.isEmpty {
                Text("Unknown")
            } else {
                Text(info.release.developerName)
            }
        }
    }

    func numberView(number numberStyle: NumberFormatter.Style? = nil, size sizeStyle: ByteCountFormatStyle.Style? = nil, _ path: KeyPath<AppCatalogItem, Int?>) -> some View {
        let value = info.release[keyPath: path]
        if let value = value {
            if let sizeStyle = sizeStyle {
                return Text(Int64(value), format: .byteCount(style: sizeStyle))
            } else {
                return Text(value, format: .number)
            }
        } else {
            return SwiftUI.Text(Image(systemName: "questionmark.square"))
        }
    }

    func histogramView(_ path: KeyPath<AppCatalogItem, Int?>) -> some View {
        wip(Image(systemName: "chart.bar.xaxis"))
            .resizable()
    }

    func summarySegment<V: View>(@ViewBuilder content: () -> V) -> some View {
        content()
            .lineLimit(1)
            .truncationMode(.middle)
        //.textSelection(.enabled)
            .hcenter()
    }

    func catalogHeader() -> some View {
        HStack(alignment: .center) {
            iconView()
                .padding(.leading, 40)

            VStack(alignment: .center) {
                Text(item.name)
                    .font(Font.largeTitle)
                catalogVersionRow()
                    .font(Font.title)
                Text(item.subtitle ?? item.localizedDescription)
                    .font(Font.title2)
                    .truncationMode(.tail)
                catalogAuthorRow()
                    .redacted(reason: .placeholder)
                    .font(Font.title3)
            }
            .textSelection(.enabled)
            .lineLimit(1)
            .allowsTightening(true)
            .truncationMode(.middle)
            .hcenter()

            categorySymbol()
                .padding(.trailing, 40)
        }
    }

    func catalogActionButtons() -> some View {
        let isCatalogApp = info.release.bundleIdentifier == "app.App-Fair"

        return HStack {
            installButton()
                .disabled(isCatalogApp && !previewMode)
                .hcenter()
            updateButton()
                .hcenter()
            launchButton()
                .disabled(isCatalogApp && !previewMode)
                .hcenter()
            revealButton()
                .hcenter()
            trashButton()
                .disabled(isCatalogApp && !previewMode)
                .hcenter()
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle)
        .controlSize(.regular)
    }

    func installButton() -> some View {
        button(activity: .install, role: nil, needsConfirm: true)
            .disabled(appInstalled && !previewMode)
            .confirmationDialog(Text("Install \(info.release.name)"), isPresented: confirmationBinding(.install), titleVisibility: .visible, actions: {
                Text("Download & Install \(info.release.name)").button {
                    runTask(activity: .install, confirm: true)
                }
                Text("Visit Community Forum").button {
                    openURLAction(info.release.discussionsURL)
                }
                // TODO: only show if there are any open issues
                // Text("Visit App Issues Page").button {
                //    openURLAction(info.release.issuesURL)
                // }
                .help(Text("Opens your web browsers and visits the developer site at \(info.release.baseURL.absoluteString)")) // sadly, tooltips on confirmationDialog buttons don't seem to work
            }, message: installMessage)
            .tint(.green)
    }

    func updateButton() -> some View {
        button(activity: .update)
            .disabled((!appInstalled || appUpdated) && !previewMode)
            .accentColor(.orange)
    }

    func launchButton() -> some View {
        button(activity: .launch)
            .disabled(!appInstalled && !previewMode)
            .accentColor(.green)
    }

    func revealButton() -> some View {
        button(activity: .reveal)
            .disabled(!appInstalled && !previewMode)
            .accentColor(.teal)
    }

    func trashButton() -> some View {
        button(activity: .trash, role: ButtonRole.destructive, needsConfirm: true)
        //.keyboardShortcut(.delete)
            .disabled(!appInstalled && !previewMode)
            .accentColor(.red)
            .confirmationDialog(Text("Really delete this app?"), isPresented: confirmationBinding(.trash), titleVisibility: .visible, actions: {
                Text("Delete").button {
                    runTask(activity: .trash, confirm: true)
                }
            }, message: {
                Text("This will remove the application “\(info.release.name)” from your applications folder and place it in the Trash.")
            })
    }

    func installMessage() -> some View {
        Text(atx: """
            This will download and install the application “\(info.release.name)” from the developer “\(info.release.developerName)” at:

            \(info.release.sourceURL.absoluteString)

            This app has not undergone any formal review, so you will be installing and running it at your own risk.

            Before installing, you should first review the Discussions, Issues, and Documentation pages to learn more about the app.
            """)
    }

    var item: AppCatalogItem {
        info.release
    }

    var doingStuff: Bool {
        currentActivity != nil
    }

    enum Activity : CaseIterable, Equatable {
        case install
        case update
        case trash
        case reveal
        case launch

        var info: (title: LocalizedStringKey, systemSymbol: String, tintColor: Color?, toolTip: LocalizedStringKey) {
            switch self {
            case .install:
                return ("Install", "square.and.arrow.down.fill", Color.blue, "Download and install the app.")
            case .update:
                return ("Update", "square.and.arrow.down.on.square", Color.orange, "Update to the latest version of the app.")
            case .trash:
                return ("Delete", "trash", Color.red, "Delete the app from your computer.")
            case .reveal:
                return ("Reveal", "doc.text.fill.viewfinder", Color.indigo, "Displays the app install location in the Finder.")
            case .launch:
                return ("Launch", "checkmark.seal.fill", Color.green, "Launches the app.")
            }
        }
    }

    /// The plist for the given installed app
    var appPropertyList: Result<Plist, Error>? {
        let installPath = AppManager.appInstallPath(for: item)
        let result = appManager.installedApps[installPath]
        //dbg("install for item:", item, "install path:", AppManager.appInstallPath(for: item).path, "plist:", result != nil, "installedApps:", appManager.installedApps.keys.map(\.path))

        if result == nil {
            //dbg("install path not found:", installPath, "in keys:", appManager.installedApps.keys)
        }
        return result
    }

    /// Returns the URLs that are registered with the system `NSWorkspace` for handling the app's bundle
    var appInstallURLs: [URL] {
        guard let plist = appPropertyList?.successValue else {
            return []
        }
        guard let bundleID = plist.bundleID else {
            return []
        }

#if os(macOS)
        let apps = NSWorkspace.shared.urlsForApplications(withBundleIdentifier: bundleID)
        return apps
#else
        return [] // TODO: iOS install check
#endif
    }

    /// Whether the app is successfully installed
    var appInstalled: Bool {
        return !appInstallURLs.isEmpty
    }

    /// The app is updated if its version is
    var appUpdated: Bool {
        (info.installedVersion ?? .min) >= (info.releasedVersion ?? .min)
    }

    func confirmationBinding(_ activity: Activity) -> Binding<Bool> {
        Binding {
            confirmations[activity] ?? false
        } set: { newValue in
            confirmations[activity] = newValue
        }
    }

    func runTask(activity: Activity, confirm confirmed: Bool) {
        if !confirmed {
            confirmations[activity] = true
        } else {
            confirmations[activity] = false // we have confirmed
            currentActivity = activity
            Task {
                await performAction(activity: activity)
                currentActivity = nil
            }
        }
    }

    func button(activity: Activity, role: ButtonRole? = .none, needsConfirm: Bool = false) -> some View {
        Button(role: role, action: {
            runTask(activity: activity, confirm: !needsConfirm)
        }, label: {
            Label(title: {
                HStack(spacing: 5) {
                    Text(activity.info.title)
                        .truncationMode(.middle)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                    Group {
                        if currentActivity == activity {
                            ProgressView()
                                .progressViewStyle(.circular) // spinner
                                .controlSize(.small) // needs to be small to fit in the button
                                .opacity(currentActivity == activity ? 1 : 0)
                        } else {
                            Image(systemName: "circle")
                        }
                    }
                    .frame(width: 20, height: 15)
                }
            }, icon: {
                Image(systemName: activity.info.systemSymbol)
            })
        })
            .buttonStyle(ActionButtonStyle(primary: true, highlighted: false))
            .accentColor(activity.info.tintColor)
            .disabled(doingStuff)
            .help(activity.info.toolTip)
    }

    func performAction(activity: Activity) async {
        switch activity {
        case .install: await installButtonTapped()
        case .update: await updateButtonTapped()
        case .trash: await deleteButtonTapped()
        case .reveal: await revealButtonTapped()
        case .launch: await launchButtonTapped()
        }
    }

    func fetchREADME() async {
        dbg("fetching README for:", self.info.id)
        
        //        do {
        //            // let await
        //            let contents = ""
        //            // self.readme = try contents.atx()
        //            self.readme = wip(nil) // FIXME: no point in rendering markdown until headers and other formatting are supported
        //        } catch {
        //            self.readme = AttributedString("Error fetching README.md")
        //            appManager.reportError(error)
        //        }
    }

    func iconView() -> some View {
        FairIconView(item.name)
            .frame(width: 100, height: 100)
        //AppIconView(iconName: item.name, baseColor: .yellow)
    }

    func categorySymbol() -> some View {
        let category = (item.appCategories.first?.groupings.first ?? .create)

        return Image(systemName: category.symbolName.description)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .fairTint(color: category.tintColor)
            .symbolVariant(.fill)
            .symbolRenderingMode(.hierarchical)
            .foregroundColor(.secondary)
            .frame(width: 100, height: 100)
    }

    func iconView2() -> some View {
        let baseColor = Color.randomIconColor()
        return ZStack {
            RoundedRectangle(cornerRadius: 15)
                .foregroundStyle(
                    .linearGradient(colors: [Color.gray, .white], startPoint: .bottomLeading, endPoint: .topTrailing))
            RoundedRectangle(cornerRadius: 15)
                .foregroundStyle(
                    .linearGradient(colors: [Color.gray, .white], startPoint: .topTrailing, endPoint: .bottomLeading))
                .padding(4)
            Image(systemName: "trash")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .symbolVariant(.fill)
                .symbolVariant(.square)
                .foregroundStyle(.linearGradient(colors: [baseColor, baseColor.opacity(0.9)], startPoint: .topTrailing, endPoint: .bottomLeading))
                .padding(20)
        }
        .frame(width: 100, height: 100)
    }

    func card<V1: View, V2: View, V3: View>(_ s1: V1, _ s2: V2, _ s3: V3) -> some View {
        VStack(alignment: .center) {
            s1
                .textCase(.uppercase)
                .font(.system(size: 11, weight: .bold, design: .default))
            s2
                .font(.system(size: 20, weight: .heavy, design: .rounded))
            s3
                .padding(.horizontal)
        }
        .foregroundColor(.secondary)
    }

    func installButtonTapped() async {
        dbg("installButtonTapped")
        do {
            try await appManager.install(item: item, progress: progress, update: false)
        } catch {
            appManager.reportError(error)
        }
    }

    func launchButtonTapped() async {
        dbg("launchButtonTapped")
        await appManager.launch(item: item)
    }

    func updateButtonTapped() async {
        dbg("updateButtonTapped")
        do {
            try await appManager.install(item: item, progress: progress, update: true)
        } catch {
            appManager.reportError(error)
        }
    }

    func revealButtonTapped() async {
        dbg("revealButtonTapped")
        await appManager.reveal(item: item)
    }

    func deleteButtonTapped() async {
        dbg("deleteButtonTapped")
        await appManager.trash(item: item)
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct CatalogItemView_Previews: PreviewProvider {
    static var previews: some View {
        CatalogItemView(info: AppInfo(release: AppCatalogItem.sample), previewMode: true)
            .environmentObject(AppManager.default)
            .frame(width: 800)
            .frame(height: 600)
        //.environment(\.locale, Locale(identifier: "fr"))
    }
}


