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

    @EnvironmentObject var appManager: AppManager
    @Environment(\.openURL) var openURLAction
    @AppStorage("showPreReleases") private var showPreReleases = false

    @State var currentActivity: Activity? = nil
    @State var progress = Progress(totalUnitCount: 1)
    @State var confirmations: [Activity: Bool] = [:]

    var body: some View {
        catalogBody()
    }

    func catalogBody() -> some View {
        // testing whether to have a scrolling or fixed-position catalog
        catalogBodyFixed()
        //catalogBodyScrolling()
    }

    func headerView() -> some View {
        pinnedHeaderView()
            .padding(.top)
            //.background(item.tintColor()?.opacity(0.1))
            //.background(Material.thick)
            //.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8)) // doesn't apply the material effect
            //.overlay(Material.thinMaterial)
            //.overlay(Material.thinMaterial))
    }

    func catalogBodyFixed() -> some View {
        VStack {
            headerView()
            catalogSummaryCards()
            Divider()
            catalogOverview()
            appPreviewImages()
        }
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
                    headerView()
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

    func linkTextField(_ title: Text, icon: String, url: URL, linkText: String? = nil) -> some View {
        TextField(text: .constant(linkText ?? url.absoluteString)) {
            title
                .label(symbol: icon)
                .labelStyle(.titleAndIconFlipped)
                .link(to: url)
                .font(Font.body)
        }
    }

    func detailsView() -> some View {
        ScrollView(.vertical, showsIndicators: true) {
            Form {
                linkTextField(Text("Discussions"), icon: "text.bubble", url: info.release.discussionsURL)
                    .help(Text("Opens link to the discussions page for this app at: \(info.release.discussionsURL.absoluteString)"))
                linkTextField(Text("Issues"), icon: "checklist", url: info.release.issuesURL)
                    .help(Text("Opens link to the issues page for this app at: \(info.release.issuesURL.absoluteString)"))
                linkTextField(Text("Source Code"), icon: "chevron.left.forwardslash.chevron.right", url: info.release.sourceURL)
                    .help(Text("Opens link to source code repository for this app at: \(info.release.sourceURL.absoluteString)"))
                linkTextField(Text("Seal"), icon: "rosette", url: info.release.fairsealURL, linkText: String(info.release.sha256 ?? ""))
                    .help(Text("Lookup fairseal at: \(info.release.fairsealURL)"))
                linkTextField(Text("Developer"), icon: "person", url: info.release.developerURL, linkText: item.developerName)
                    .help(Text("Searches for this developer at: \(info.release.developerURL)"))
            }
            .symbolRenderingMode(SymbolRenderingMode.multicolor)
            .font(Font.body.monospaced())
            .textFieldStyle(.plain)
            .truncationMode(.middle)
        }
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
        ScrollView {
            LazyVGrid(columns: [
                GridItem(GridItem.Size.adaptive(minimum: 300, maximum: 2000)),
            ]) {
                groupBox(title: Text("Permissions: ") + item.riskText().fontWeight(.regular), trailing: item.riskLabel()
                            .labelStyle(IconOnlyLabelStyle())
                            .padding(.trailing)) {
                    permissionsList()
                        .frame(height: 100)
                }
                .padding()


                groupBox(title: Text("Description"), trailing: EmptyView()) {
                    descriptionSummary()
                        //.redacted(reason: wip(.placeholder))
                        .frame(height: 100, alignment: .top)
                }
                .padding()

                groupBox(title: Text("Details"), trailing: EmptyView()) {
                    detailsView()
                        .frame(height: 200)
                }
                .padding()


                groupBox(title: Text("Preview"), trailing: EmptyView()) {
                    ScrollView(.horizontal) {
                        previewView()
                            .frame(height: 200)
                    }
                }
                .padding()

            }
        }
    }

    func catalogOverviewOLD() -> some View {
        Group {
            VStack(alignment: .leading) {
                groupBox(title: Text("Details"), trailing: EmptyView()) {
                    detailsView()
                        .frame(minHeight: 20)
                }
                .padding()

                groupBox(title: Text("Permissions: ") + item.riskText().fontWeight(.regular), trailing: item.riskLabel()
                            .labelStyle(IconOnlyLabelStyle())
                            .padding(.trailing)) {
                    permissionsList()
                        .frame(minHeight: 20)
                }
                            .padding()
            }
        }
        .stack(.horizontal, proportion: 3.0/5.0) {
            VStack(alignment: .leading) {
                groupBox(title: Text("Description"), trailing: EmptyView()) {
                    ScrollView(.vertical) {
                        descriptionSummary()
                            //.redacted(reason: wip(.placeholder))
                    }
                }
                .padding()

                groupBox(title: Text("Preview"), trailing: EmptyView()) {
                    ScrollView(.horizontal) {
                        previewView()
                            .frame(minHeight: 20)
                    }
                }
                .padding()

            }
        }
    }

    func descriptionSummary() -> some View {
        Text(self.appManager.readme(for: self.info.release) ?? .init(""))
            .font(.body)
            .textSelection(.enabled)
            .multilineTextAlignment(.leading)
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
            .truncationMode(.tail)
            //.textSelection(.enabled)
            .help(entitlement.localizedInfo.info + Text(": ") + Text(permission.usageDescription))
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

    func previewView() -> some View {
        LazyHStack {
            ForEach(item.screenshotURLs ?? [], id: \.self) { url in
                URLImage(sync: false, url: url, resizable: .fit, showProgress: true)
            }
        }
    }
    
    func catalogVersionRow() -> some View {
        Text(info.releasedVersion?.versionDescriptionExtended ?? "")
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

    /// Show a histogram of where the given value lies in the context of other apps in the grouping
    func histogramView(_ path: KeyPath<AppCatalogItem, Int?>) -> some View {
        Image(systemName: "chart.bar.xaxis")
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
                .frame(width: 100, height: 100)
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
                    //.redacted(reason: .placeholder)
                    .font(Font.title3)
            }
            .textSelection(.enabled)
            .lineLimit(1)
            .allowsTightening(true)
            .truncationMode(.middle)
            .hcenter()

            categorySymbol()
                .frame(width: 100, height: 100)
                .padding(.trailing, 40)
        }
    }

    func catalogActionButtons() -> some View {
        let isCatalogApp = info.release.bundleIdentifier == "app.App-Fair"

        return HStack {
            installButton()
                .disabled(isCatalogApp)
                .hcenter()
            updateButton()
                .hcenter()
            launchButton()
                .disabled(isCatalogApp)
                .hcenter()
            revealButton()
                .hcenter()
            trashButton()
                .disabled(isCatalogApp)
                .hcenter()
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle)
        .controlSize(.regular)
    }

    func installButton() -> some View {
        button(activity: .install, role: nil, needsConfirm: true)
            .disabled(appInstalled)
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
            .disabled((!appInstalled || !info.appUpdated))
            .accentColor(.orange)
    }

    func launchButton() -> some View {
        button(activity: .launch)
            .disabled(!appInstalled)
            .accentColor(.green)
    }

    func revealButton() -> some View {
        button(activity: .reveal)
            .disabled(!appInstalled)
            .accentColor(.teal)
    }

    func trashButton() -> some View {
        button(activity: .trash, role: ButtonRole.destructive, needsConfirm: true)
        //.keyboardShortcut(.delete)
            .disabled(!appInstalled)
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

    func iconView() -> some View {
        Group {
            if let iconURL = item.iconURL {
                URLImage(url: iconURL, resizable: .fit)
            } else {
                FairIconView(item.name)
            }
        }
    }

    func categorySymbol() -> some View {
        let category = (item.appCategories.first?.groupings.first ?? .create)

        return Image(systemName: category.symbolName.description)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .fairTint(color: item.tintColor() ?? FairIconView.iconColor(name: item.appNameHyphenated))
            .symbolVariant(.fill)
            .symbolRenderingMode(.hierarchical)
            .foregroundColor(.secondary)
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

extension AppCatalogItem {
    func tintColor() -> Color? {
        func hexColor(hex: Int, opacity: Double = 1.0) -> Color {
            let red = Double((hex & 0xff0000) >> 16) / 255.0
            let green = Double((hex & 0xff00) >> 8) / 255.0
            let blue = Double((hex & 0xff) >> 0) / 255.0
            return Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
        }

        guard var tint = self.tintColor else {
            return nil
        }

        if tint.hasPrefix("#") {
            tint.removeFirst()
        }

        if let intValue = Int(tint, radix: 16) {
            return hexColor(hex: intValue)
        }

        return nil
    }
}

extension LabelStyle where Self == TitleAndIconFlippedLabelStyle {
    /// The same as `titleAndIcon` with the icon at the end
    public static var titleAndIconFlipped: TitleAndIconFlippedLabelStyle {
        TitleAndIconFlippedLabelStyle()
    }
}

public struct TitleAndIconFlippedLabelStyle : LabelStyle {
    public func makeBody(configuration: TitleAndIconLabelStyle.Configuration) -> some View {
        HStack(alignment: .firstTextBaseline) {
            configuration.title
            configuration.icon
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct CatalogItemView_Previews: PreviewProvider {
    static var previews: some View {
        CatalogItemView(info: AppInfo(release: AppCatalogItem.sample))
            .environmentObject(AppManager.default)
            .frame(width: 600)
            .frame(height: 800)
        //.environment(\.locale, Locale(identifier: "fr"))
    }
}
