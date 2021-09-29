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
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(pinnedViews: [.sectionHeaders]) {
                Section {
                    catalogSummaryCards()
                    Divider()
                    catalogOverview()
                    appPreviewImages()
                } header: {
                    VStack {
                        catalogHeader()
                        Divider()
                        catalogActionButtons()
                        Divider()
                    }
                    .padding()
                    .background(Material.thinMaterial)
                }
            }
        }
    }

    func appPreviewImages() -> some View {
        EmptyView()
//        groupBox(title: Text("Previews", bundle: .module)) {
//            catalogPreviewImages()
//        }
    }

    func starsCard() -> some View {
        summarySegment {
            card(
                Text("Stars", bundle: .module),
                numberView(number: .decimal, \.starCount),
                histogramView(\.starCount)
            )
        }
    }

    func downloadsCard() -> some View {
        summarySegment {
            card(
                Text("Downloads", bundle: .module),
                numberView(number: .decimal, \.downloadCount),
                histogramView(\.downloadCount)
            )
        }
    }

    func sizeCard() -> some View {
        summarySegment {
            card(
                Text("Size", bundle: .module),
                numberView(size: .file, \.fileSize),
                histogramView(\.fileSize)
            )
        }
    }

    func coreSizeCard() -> some View {
        summarySegment {
            card(
                Text("Core Size", bundle: .module),
                numberView(size: .file, \.coreSize),
                histogramView(\.coreSize)
            )
        }
    }

    func watchersCard() -> some View {
        summarySegment {
            card(
                Text("Watchers", bundle: .module),
                numberView(number: .decimal, \.watcherCount),
                histogramView(\.watcherCount)
            )
        }
    }

    func issuesCard() -> some View {
        summarySegment {
            card(
                Text("Issues", bundle: .module),
                numberView(number: .decimal, \.issueCount),
                histogramView(\.issueCount)
            )
        }
    }

    func releaseDateCard() -> some View {
        summarySegment {
            card(
                Text("Updated", bundle: .module),
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
    }

    func detailsView() -> some View {
        VStack {
            Group {
                SwiftUI.Text("Developer: \(item.developerName)")
                SwiftUI.Text("Size: \(item.size)")
                SwiftUI.Text("BundleIdentifier: \(item.bundleIdentifier)")
                //SwiftUI.Text("Categories: \(item.categories ?? [])")
                SwiftUI.Text("SHA256: \(item.sha256 ?? "")")
            }
            Group {
                SwiftUI.Text("ForkCount: \(item.forkCount ?? 0)")
                SwiftUI.Text("issueCount: \(item.issueCount ?? 0)")
                SwiftUI.Text("starCount: \(item.starCount ?? 0)")
                SwiftUI.Text("watcherCount: \(item.watcherCount ?? 0)")
                SwiftUI.Text("downloadCount: \(item.downloadCount ?? 0)")
            }
        }
        .textSelection(.enabled)
    }

    func groupBox<V: View>(title: Text, @ViewBuilder content: () -> V) -> some View {
        GroupBox(content: {
            ScrollView {
                content()
            }
        }, label: {
            title.font(.title2)
        })
            .groupBoxStyle(.automatic)
            .padding()
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
                groupBox(title: Text("Description", bundle: .module)) {
                    ScrollView {
                        descriptionSummary()
                    }
                }
            }

            VStack(alignment: .leading) {
                groupBox(title: Text("Permissions", bundle: .module)) {
                    entitlementsList()
                        .frame(height: 150)
                }

                groupBox(title: Text("Details", bundle: .module)) {
                    detailsView()
                        .frame(height: 200)
                }
            }
            .frame(width: 300)
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

    func entitlementsList() -> some View {
        List {
            ForEach(item.orderedEntitlements) { entitlement in
                entitlement.localizedInfo.title.label(symbol: entitlement.localizedInfo.symbol)
                    .listItemTint(ListItemTint.monochrome)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                    .symbolRenderingMode(SymbolRenderingMode.monochrome)
                    .help(entitlement.localizedInfo.info)
            }
        }
        //.listStyle(.bordered(alternatesRowBackgrounds: true)) // not in iOS
    }

    func catalogVersionRow() -> some View {
        Text(info.releasedVersion?.versionDescription ?? "")
            .font(.title)
            .foregroundColor(.secondary)
    }

    func catalogAuthorRow() -> some View {
        Group {
            if info.release.developerName.isEmpty {
                Text("Unknown", bundle: .module)
            } else {
                Text(info.release.developerName)
            }
        }
        .textSelection(.enabled)
        .lineLimit(1)
        .truncationMode(.middle)
        .font(.callout.monospaced())
        .foregroundColor(.secondary)
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
    }

    func summarySegment<V: View>(@ViewBuilder content: () -> V) -> some View {
        content()
            .lineLimit(1)
            .truncationMode(.middle)
            .textSelection(.enabled)
            .hcenter()
    }

    func catalogHeader() -> some View {
        HStack(alignment: .center) {
            iconView()
                .padding(.leading, 40)
            Spacer()
            VStack(alignment: .center) {
                Text(item.name)
                    .font(Font.largeTitle.bold())
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)

                catalogVersionRow()

                Text(item.subtitle ?? item.localizedDescription)
                    .font(.body)
                    .textSelection(.enabled)
                    .truncationMode(.tail)

                catalogAuthorRow()
            }
            .textSelection(.enabled)
            .lineLimit(1)
            .allowsTightening(true)
            .truncationMode(.middle)

            Spacer()
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
            .confirmationDialog(Text("Install \(info.release.name)", bundle: .module), isPresented: confirmationBinding(.install), titleVisibility: .visible, actions: {
                Bundle.module.button("Download & Install \(info.release.name)") {
                    runTask(activity: .install, confirm: true)
                }
                Bundle.module.button("Visit Community Forum") {
                    openURLAction(info.release.discussionsURL)
                }
                // TODO: only show if there are any open issues
                // Bundle.module.button("Visit App Issues Page") {
                //    openURLAction(info.release.issuesURL)
                // }
                .help(Text("Opens your web browsers and visits the developer site at \(info.release.baseURL.absoluteString)", bundle: .module)) // sadly, tooltips on confirmationDialog buttons don't seem to work
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
            .confirmationDialog(Text("Really delete this app?", bundle: .module), isPresented: confirmationBinding(.trash), titleVisibility: .visible, actions: {
                Bundle.module.button("Delete") {
                    runTask(activity: .trash, confirm: true)
                }
            }, message: {
                Text("This will remove the application “\(info.release.name)” from your applications folder and place it in the Trash.", bundle: .module)
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
                    Text(activity.info.title, bundle: .module)
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
        dbg("fetching")
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
        let symbol = (item.appCategories.first?.groupings.first ?? .create)
            .symbolName

        return Image(systemName: symbol.description)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .labelStyle(.iconOnly)
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
        VStack {
            s1
                .textCase(.uppercase)
                .font(.system(size: 10, weight: .bold, design: .default))
                .foregroundColor(.secondary)
            s2
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.secondary)
            s3
                .foregroundColor(.secondary)
        }
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
    static let sampleCatalogEntry = AppCatalogItem(name: "App Fair", bundleIdentifier: "app.App-Fair", subtitle: "The App Fair catalog browser app", developerName: "appfair@appfair.net", localizedDescription: "This app allows you to browse, download, and install apps from the App Fair. The App Fair catalog browser is the nexus for finding and installing App Fair apps", size: 1_234_567, version: "1.2.3", versionDate: Date(timeIntervalSinceNow: -60*60*24*2), downloadURL: URL(string: "https://github.com/appfair/App/releases/download/App-Fair/App-Fair-macOS.zip")!, iconURL: URL(string: "https://github.com/appfair/App/releases/download/App-Fair/App-Fair.png")!, screenshotURLs: nil, versionDescription: nil, tintColor: "#AABBCC", beta: false, sourceIdentifier: nil, categories: [AppCategory.games.topicIdentifier], downloadCount: 23_456, starCount: 123, watcherCount: 43, issueCount: 12, sourceSize: 2_210_000, coreSize: 223_197, sha256: nil, permissions: AppEntitlement.bitsetRepresentation(for: Set(AppEntitlement.allCases)))

    static var previews: some View {
        CatalogItemView(info: AppInfo(release: Self.sampleCatalogEntry), previewMode: true)
            .environmentObject(AppManager.default)
        .frame(width: 800)
        .frame(height: 1000)
        //.environment(\.locale, Locale(identifier: "fr"))
    }
}


