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
import FairExpo
import WebKit

struct CatalogItemView: View, Equatable {
    /// The regex for hosts that can be accessed directly from the embedded browser
    static let permittedHostsRegex = try! Result {
        try NSRegularExpression(pattern: #"^github.com|.*.github.com|.*.github.io$"#, options: [.anchorsMatchLines])
    }.get()

    let info: AppInfo
    let source: AppSource

    var body: some View {
        CatalogItemHostView(info: info, source: source)
    }
}

private struct CatalogItemHostView: View {
    let info: AppInfo
    let source: AppSource

    @EnvironmentObject var fairManager: FairManager
    @Environment(\.openURL) var openURLAction
    @Environment(\.colorScheme) var colorScheme

    @State private var manualURLFileSize: Int64? = nil
    @State private var manualURLModifiedDate: Date? = nil

    @State private var previewScreenshot: URL? = nil

    private var currentOperation: CatalogOperation? {
        get {
            fairManager.operations[info.id]
        }

        nonmutating set {
            fairManager.operations[info.id] = newValue
        }
    }

    private var currentActivity: CatalogActivity? {
        get {
            currentOperation?.activity
        }

        nonmutating set {
            currentOperation = newValue.flatMap({ CatalogOperation(activity: $0) })
        }
    }

    @StateObject var progress = ObservableProgress()
    @State var confirmations: [CatalogActivity: Bool] = [:]

    @Namespace private var namespace

    @StateObject var projectHomeWebViewState: WebViewState
    @StateObject var appHomeWebViewState: WebViewState

    init(info: AppInfo, source: AppSource, inlineHosts: [NSRegularExpression]? = [CatalogItemView.permittedHostsRegex]) {
        self.info = info
        self.source = source

        let config = WKWebViewConfiguration()

        func createWebViewState(_ url: URL?) -> WebViewState {
            let privateMode = (inlineHosts?.first(where: { $0.hasMatches(in: url?.host ?? "") }) == nil)
            //config.defaultWebpagePreferences.preferredContentMode = .mobile
            config.preferences.javaScriptCanOpenWindowsAutomatically = false
            if privateMode {
                config.processPool = WKProcessPool()
                config.websiteDataStore = .nonPersistent()
            }

            //config.defaultWebpagePreferences.preferredContentMode = .mobile
            config.preferences.javaScriptCanOpenWindowsAutomatically = false
            if privateMode {
                config.processPool = WKProcessPool()
                config.websiteDataStore = .nonPersistent()
            }

            let state = WebViewState(initialRequest: url.flatMap { URLRequest(url: $0) }, configuration: config)
            return state
        }

        self._projectHomeWebViewState = .init(wrappedValue: createWebViewState(info.projectURL))
        self._appHomeWebViewState = .init(wrappedValue: createWebViewState(info.homepage ?? info.app.landingPage))
    }


#if os(macOS) // horizontalSizeClass unavailable on macOS
    func horizontalCompact() -> Bool { false }
#else
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    func horizontalCompact() -> Bool { horizontalSizeClass == .compact }
#endif

    var unavailableIcon: some View {
        // FairSymbol.exclamationmark_triangle_fill.image.symbolRenderingMode(.multicolor)
        FairSymbol.puzzlepiece_fill.image.symbolRenderingMode(.hierarchical)
    }


    var body: some View {
        ZStack {
            catalogStack()
            screenshotPreviewOverlay()
        }
        .onAppear {
            // transfer the progress so we can watch the operation
            progress.progress = currentOperation?.progress ?? progress.progress
        }
    }

    /// Navigates to the given URL;
    /// if it is within the allowed domain of the embedded browser, opens it embedded.
    /// Otherwise, launches the system's default browser.
    @discardableResult func navigate(to url: URL?) -> OpenURLAction.Result {
        if let url = url,
           let host = url.host,
           CatalogItemView.permittedHostsRegex.hasMatches(in: host) {
            dbg("handling embedded url:", url.absoluteString)
            if self.previewTab == .project {
                self.projectHomeWebViewState.load(url)
            } else {
                self.previewTab = .project
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                    // need a small delay since the appearance of the project tab will trigger the load of the initial state, not the navigated state
                        self.projectHomeWebViewState.load(url)
                }
            }
            return .handled
            //return .systemAction(url)
        } else {
            // openURLAction(url)
            dbg("delegating to to system:", url?.absoluteString)
            if let url = url {
                return .systemAction(url)
            } else {
                return .discarded
            }
        }
    }

    @ViewBuilder func catalogStack() -> some View {
        VStack(spacing: 0) {
            catalogHeader()
                .padding(.vertical)
                .background(Material.ultraThinMaterial)
            Divider()
            catalogActionButtons()
                .frame(height: buttonHeight + 12)
                .padding(.vertical)
            Divider()
            catalogSummaryCards()
                .frame(height: 60)
            Divider()
            VSplitView {
                if previewAreaPinned == false {
                    HStack {
                        overviewTabView()
                        metadataTabView()
                    }
                    .padding()
                    //.layoutPriority(1)

                    // a prominent divider so the user can drag to resize the preview area more easily
                    SplitDividerView()
                }
                previewSplitItem()
                    .padding(.top, 6)
                    //.layoutPriority(0)
            }
        }

    }

    @ViewBuilder func starsCard() -> some View {
        HStack {
            starButton().hidden()
            summarySegment {
                card(
                    Text("Stars", bundle: .module, comment: "app catalog entry header box title"),
                    numberView(number: .decimal, \.stats?.starCount),
                    histogramView(\.stats?.starCount)
                )
            }
            starButton()
        }
        .hcenter()
    }

    @ViewBuilder func starButton() -> some View {
        Text("Stargazers", bundle: .module, comment: "accessibility title for the label to browse the stargazers for this project")
            .label(image: FairSymbol.star)
            .labelStyle(.iconOnly)
            .font(.system(size: 18, weight: .regular, design: .default))
            .hoverSymbol(activeVariant: .fill, animation: .default)
            .foregroundStyle(.linearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom))
            .button {
                navigate(to: info.app.stargazersURL)
            }
            .buttonStyle(.plain)
            .help(Text("Star this project on GitHub", bundle: .module, comment: "tooltip for button to open link to star project on GitHub"))
    }

    @ViewBuilder func downloadsCard() -> some View {
        HStack {
            sponsorButton().hidden()
            summarySegment {
                card(
                    Text("Downloads", bundle: .module, comment: "app catalog entry header box title"),
                    numberView(number: .decimal, \.stats?.downloadCount)
                        .help(info.isGitHubHostedApp ? Text("The total number of downloads for this release", bundle: .module, comment: "app catalog entry header box title tooltip text") : Text("The number of downloads of this app in the past 90 days", bundle: .module, comment: "app catalog entry header box title tooltip text")),
                    histogramView(\.stats?.downloadCount)
                )
            }
            sponsorButton()
        }
        .hcenter()
    }

//    @State private var sponsorIconAnimating = false
//    @State private var sponsorIconScale = 1.0

    @ViewBuilder func sponsorButton() -> some View {
        if let sponsorsURL = info.app.sponsorsURL {
            Text("Sponsor", bundle: .module, comment: "accessibility title for the label to sponsor this project")
                .label(image: FairSymbol.heart)
//                .scaleEffect(sponsorIconAnimating ? sponsorIconScale : 1.0)
//                .animation(
//                    .linear(duration: 0.1)
//                        .delay(0.2)
//                        .repeatForever(autoreverses: true),
//                    value: sponsorIconScale)
                .labelStyle(.iconOnly)
                .font(.system(size: 18, weight: .regular, design: .default))
                .hoverSymbol(activeVariant: .fill, animation: .default)
                .foregroundStyle(.linearGradient(colors: [.pink, .red], startPoint: .top, endPoint: .bottom))
                .button {
                    navigate(to: sponsorsURL)
                }
                .buttonStyle(.plain)
                .help(Text("Sponsor this project on GitHub", bundle: .module, comment: "tooltip for button to open link to sponsor project on GitHub"))
        }
    }

    @ViewBuilder func sizeCard() -> some View {
        HStack {
            //starButton()
            summarySegment {
                card(
                    Text("Size", bundle: .module, comment: "app catalog entry header box title"),
                    downloadSizeView(),
                    histogramView(\.fileSize)
                )
            }
        }
        .hcenter()
    }

    @ViewBuilder func downloadSizeView() -> some View {
        Group {
            if let manualURLFileSize = manualURLFileSize, manualURLFileSize > 0 { // sometimes -1 when it isn't found
                numberView(size: .file, value: Int(manualURLFileSize))
            } else if (self.info.app.fileSize ?? 0) <= 0 {
                // show the card view with an empty file size
                //Text("Unknown", bundle: .module, comment: "app catalog entry content box placeholder text for a download size that isn't known")
                    //.redacted(reason: .placeholder)
                numberView(size: .file, \.fileSize)
                    .task(priority: .low) {
                        await fetchDownloadURLStats()
                    }
            } else {
                numberView(size: .file, \.fileSize)
            }
        }
        .transition(.opacity)
    }

    @ViewBuilder func coreSizeCard() -> some View {
        HStack {
            //starButton()
            summarySegment {
                card(
                    Text("Core Size", bundle: .module, comment: "app catalog entry header box title for the core size of the app"),
                    numberView(size: .file, \.stats?.coreSize),
                    histogramView(\.stats?.coreSize)
                )
            }
        }
        .hcenter()
    }

    @ViewBuilder func watchersCard() -> some View {
        HStack {
            //starButton()
            summarySegment {
                card(
                    Text("Watchers", bundle: .module, comment: "app catalog entry header box title for the number of watchers for the app"),
                    numberView(number: .decimal, \.stats?.watcherCount),
                    histogramView(\.stats?.watcherCount)
                )
            }
        }
        .hcenter()
    }

    @ViewBuilder func issuesCard() -> some View {
        HStack {
            issuesButton().hidden()
            summarySegment {
                card(
                    Text("Issues", bundle: .module, comment: "app catalog entry header box title for the number of issues for the app"),
                    numberView(number: .decimal, \.stats?.issueCount),
                    histogramView(\.stats?.issueCount)
                )
            }
            issuesButton()
        }
        .hcenter()
    }

    @ViewBuilder func issuesButton() -> some View {
        Text("Browse Issues", bundle: .module, comment: "accessibility title for the label to browse the available issues")
            .label(image: FairSymbol.ladybug)
            .labelStyle(.iconOnly)
            .font(.system(size: 18, weight: .regular, design: .default))
            .hoverSymbol(activeVariant: .fill, animation: .default)
            .foregroundStyle(.linearGradient(colors: [.indigo, /*.purple, */ .indigo], startPoint: .top, endPoint: .bottom))
            .button {
                navigate(to: info.app.issuesURL)
            }
            .buttonStyle(.plain)
            .help(Text("Browse the issues for this project on GitHub", bundle: .module, comment: "tooltip for button to browse the issues for the project on GitHub"))
    }


    @ViewBuilder func releaseDateCard() -> some View {
        HStack {
            //releaseDateButton()
            summarySegment {
                card(
                    Text("Updated", bundle: .module, comment: "app catalog entry header box title for the date the app was last updated"),
                    releaseDateView(),
                    histogramView(\.stats?.issueCount)
                )
            }
        }
        .hcenter()
    }

    @ViewBuilder func releaseDateView() -> some View {
        Group {
            if let date = metadata.versionDate ?? self.manualURLModifiedDate {
                Text(date, format: .relative(presentation: .numeric, unitsStyle: .wide))
                    //.refreshingEveryMinute()
            } else {
                Text("Unknown", bundle: .module, comment: "app catalog entry header box content for an unknown update date")
                    .redacted(reason: .placeholder)
            }
        }
        .transition(.opacity)
    }

    private func fetchDownloadURLStats() async {
        do {
            //dbg("checking URL HEAD:", metadata.downloadURL.absoluteString)

            let head = try await URLSession.shared.fetchHEAD(url: metadata.downloadURL, cachePolicy: .returnCacheDataElseLoad)

            // in theory, we could also try to pre-flight out expected SHA-256 checksum by checking for a header like "Digest: sha-256=A48E9qOokqqrvats8nOJRJN3OWDUoyWxBf7kbu9DBPE=", but in practice no server ever seems to send it
            withAnimation {
                self.manualURLFileSize = head?.expectedContentLength
                self.manualURLModifiedDate = head?.lastModifiedDate
            }
            //dbg("URL HEAD:", metadata.downloadURL.absoluteString, self.manualURLFileSize?.localizedByteCount(), self.manualURLFileSize, (head as? HTTPURLResponse)?.allHeaderFields as? [String: String])

        } catch {
            // errors are not unexpected when the user leaves this view:
            // NSURLErrorDomain Code=-999 "cancelled"
            dbg("error checking URL size:", metadata.downloadURL.absoluteString, "error:", error)
        }
    }

    @ViewBuilder func catalogSummaryCards() -> some View {
        HStack(alignment: .center) {
            starsCard()
                .opacity(info.isGitHubHostedApp ? 1.0 : 0.0)
            Divider()
            releaseDateCard()
            Divider()
            downloadsCard()
                .opacity(info.isCask || info.isGitHubHostedApp ? 1.0 : 0.0)
            Divider()
            sizeCard()
            Divider()
            issuesCard()
                .opacity(info.isGitHubHostedApp ? 1.0 : 0.0)
        }
    }

    /// The accessory on the trailing section of a `groupBox`
    @ViewBuilder func progressAccessory(_ fetching: Int) -> some View {
        ProgressView()
            .opacity(fetching > 0 ? 1.0 : 0.0).controlSize(.mini)
            .padding(.trailing, 8)
            .animation(Animation.easeInOut, value: fetching)
    }


    func linkTextField(_ title: Text, icon: FairSymbol, url: URL?, linkText: String? = nil) -> some View {
        // the text winds up being un-aligned vertically when rendered like this
        //        TextField(text: .constant(linkText ?? url?.absoluteString ?? "")) {
        //            title
        //                .label(symbol: icon)
        //                .labelStyle(.titleAndIconFlipped)
        //                .link(to: url)
        //                //.font(Font.body)
        //        }
        //        .textFieldStyle(.plain)

        HStack {
            title
                .label(image: icon)
                .lineLimit(1)
                .labelStyle(.titleAndIconFlipped)
                .link(to: url)
                .environment(\.openURL, OpenURLAction(handler: navigate(to:))) // open URLs in embedded browser or external as deemed fit
                .frame(width: 110, alignment: .trailing)

            Text(linkText ?? url?.absoluteString ?? "")
                .lineLimit(1)
                .textSelection(.enabled)
                .font(Font.body.monospacedDigit())
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        //.alignmentGuide(.leading, computeValue: { d in (d.width - 60) })

        //        HStack {
        //
        //            TextField(text: .constant("")) {
        //                title
        //                    .label(symbol: icon)
        //                    .labelStyle(.titleAndIconFlipped)
        //                    .link(to: url)
        //                    .font(Font.body)
        //            }
        //            Text(linkText ?? url.absoluteString)
        //                .font(Font.body.monospaced())
        //                .truncationMode(.middle)
        //                .textSelection(.enabled)
        //        }

        //        TextField(text: .constant(linkText ?? url.absoluteString)) {
        //            title
        //                .label(symbol: icon)
        //                .labelStyle(.titleAndIconFlipped)
        //                .link(to: url)
        //                .font(Font.body)
        //        }


    }

    func detailsListView() -> some View {
        ScrollView {
            Form {
                if let cask = info.cask {
                    if let page = cask.homepage, let homepage = URL(string: page) {
                        linkTextField(Text("Homepage", bundle: .module, comment: "app catalog entry info link title"), icon: .house, url: homepage)
                            .help(Text("Opens link to the home page for this app at: \(homepage.absoluteString)", bundle: .module, comment: "app catalog entry info link tooltip"))
                    }

                    if let downloadURL = cask.url, let downloadURL = URL(string: downloadURL) {
                        linkTextField(Text("Download", bundle: .module, comment: "app catalog entry info link title"), icon: .arrow_down_circle, url: downloadURL)
                            .help(Text("Opens link to the direct download for this app at: \(downloadURL.absoluteString)", bundle: .module, comment: "app catalog entry info link tooltip"))
                    }

                    if let appcast = cask.appcast, let appcast = URL(string: appcast) {
                        linkTextField(Text("Appcast", bundle: .module, comment: "app catalog entry info link title"), icon: .dot_radiowaves_up_forward, url: appcast)
                            .help(Text("Opens link to the appcast for this app at: \(appcast.absoluteString)", bundle: .module, comment: "app catalog entry info link tooltip"))
                    }

                    if let tapToken = cask.tapToken, let tapURL = cask.tapURL {
                        linkTextField(Text("Cask Token", bundle: .module, comment: "app catalog entry info link title"), icon: .esim, url: tapURL, linkText: tapToken)
                            .help(Text("The page for the Homebrew Cask token", bundle: .module, comment: "app catalog entry info link tooltip"))
                    }

                    if let sha256 = cask.checksum ?? "None" {
                        linkTextField(Text("Checksum", bundle: .module, comment: "app catalog entry info link title"), icon: cask.checksum == nil ? .exclamationmark_triangle_fill : .rosette, url: cask.checksum == nil ? nil : URL(string: "https://github.com/Homebrew/formulae.brew.sh/search?q=" + sha256), linkText: sha256)
                            .help(cask.checksum == nil ? Text("The SHA-256 checksum for the app is missing, which means that the integrity cannot be varified when it is downloaded.", bundle: .module, comment: "app catalog entry info link tooltip") : Text("The SHA-256 checksum for the app download", bundle: .module, comment: "app catalog entry info link tooltip"))
                    }

//                    linkTextField(Text("Auto-Updates", bundle: .module, comment: "app catalog entry info auto-update tooltip"), icon: .sparkle, url: nil, linkText: cask.auto_updates == nil ? "Unknown" : cask.auto_updates == true ? "Yes" : "No")
//                        .help(Text("Whether this app handles updating itself", bundle: .module, comment: "tooltip text describing when an app auto-updates"))
                } else if info.isGitHubHostedApp {
                    if let landingPage = info.app.landingPage {
                        linkTextField(Text("Home", bundle: .module, comment: "app catalog entry info link title"), icon: .house, url: landingPage)
                            .help(Text("Opens link to the landing page for this app at: \(landingPage.absoluteString)", bundle: .module, comment: "app catalog entry info link tooltip"))
                    }
                    if let discussionsURL = info.app.discussionsURL {
                        linkTextField(Text("Discussions", bundle: .module, comment: "app catalog entry info link title"), icon: .text_bubble, url: discussionsURL)
                            .help(Text("Opens link to the discussions page for this app at: \(discussionsURL.absoluteString)", bundle: .module, comment: "app catalog entry info link tooltip"))
                    }
                    if let issuesURL = info.app.issuesURL {
                        linkTextField(Text("Issues", bundle: .module, comment: "app catalog entry info link title"), icon: .checklist, url: issuesURL)
                            .help(Text("Opens link to the issues page for this app at: \(issuesURL.absoluteString)", bundle: .module, comment: "app catalog entry info link tooltip"))
                    }
                    if let sourceURL = info.app.sourceURL {
                        linkTextField(Text("Source", bundle: .module, comment: "app catalog entry info link title"), icon: .chevron_left_forwardslash_chevron_right, url: sourceURL)
                            .help(Text("Opens link to source code repository for this app at: \(sourceURL.absoluteString)", bundle: .module, comment: "app catalog entry info link tooltip"))
                    }
                    if let fairsealURL = info.app.fairsealURL {
                        linkTextField(Text("Fairseal", bundle: .module, comment: "app catalog entry info link title"), icon: .rosette, url: fairsealURL, linkText: String(info.app.sha256 ?? ""))
                            .help(Text("Lookup fairseal at: \(info.app.fairsealURL?.absoluteString ?? "")", bundle: .module, comment: "app catalog entry info link tooltip"))
                    }
                    if let developerURL = info.app.developerURL {
                        linkTextField(Text("Developer", bundle: .module, comment: "app catalog entry info link title"), icon: .person, url: developerURL, linkText: metadata.developerName)
                            .help(Text("Searches for this developer at: \(info.app.developerURL?.absoluteString ?? "")", bundle: .module, comment: "app catalog entry info link tooltip"))
                    }
                } else {
                    // TODO: implement more details for non-fairground apps
                    if let homepage = info.app.homepage {
                        linkTextField(Text("Homepage", bundle: .module, comment: "app catalog entry info link title"), icon: .link_circle, url: homepage, linkText: metadata.homepage?.absoluteString)
                    }
                }
            }
            .symbolRenderingMode(SymbolRenderingMode.hierarchical)
            //.font(Font.body.monospaced())
            //.textFieldStyle(.plain)
        }
    }

    func groupBox<V: View, L: View>(title: Text, trailing: L, @ViewBuilder content: () -> V) -> some View {
        GroupBox(content: {
            content()
        }, label: {
            HStack {
                title
                    .font(.headline)
                Spacer()
                trailing
                    .font(.subheadline)
            }
            .lineLimit(1)
        })
            .groupBoxStyle(.automatic)
    }

    @State var overviewTab = OverviewTab.description

    enum OverviewTab : CaseIterable, Hashable {
        case description
        case version
        case caveats

        var title: Text {
            switch self {
            case .description: return Text("Description", bundle: .module, comment: "app catalog cask entry overview tab title")
            case .version: return Text("Version", bundle: .module, comment: "app catalog cask entry overview tab title")
            case .caveats: return Text("Caveats", bundle: .module, comment: "app catalog cask entry preview overview title")
            }
        }
    }

    @State var metadataTab = MetadataTab.details

    enum MetadataTab : CaseIterable, Hashable {
        case details
        case permissions
        case formula
        case security

        var title: Text {
            switch self {
            case .details: return Text("Details", bundle: .module, comment: "app catalog cask entry metadata tab title for app details")
            case .permissions: return Text("Permissions", bundle: .module, comment: "app catalog cask entry metadata tab title for app permissions")
            case .formula: return Text("Scheme", bundle: .module, comment: "app catalog cask entry metadata tab title for app raw formula specification")
            case .security: return Text("Security", bundle: .module, comment: "app catalog cask entry metadata tab title for app secutiry")
            }
        }
    }

    @State private var previewTab: PreviewTab?

    /// The current preview tab, choosing a default based on the metadata
    private var previewTabDefaulted: Binding<PreviewTab> {
        Binding {
            if let previewTab = previewTab {
                return previewTab
            } else if metadata.screenshotURLs?.isEmpty == false {
                return .screenshots
            } else if fairManager.homeBrewInv?.enableCaskHomepagePreview == true {
                return .homepage
            } else {
                return .project
            }
        } set: { newValue in
            self.previewTab = newValue
        }
    }

    enum PreviewTab : CaseIterable, Hashable {
        case screenshots
        case project
        case homepage

        var title: Text {
            switch self {
            case .screenshots: return Text("Screen Shots", bundle: .module, comment: "app catalog app entry preview tab title")
            case .project: return Text("Project", bundle: .module, comment: "app catalog app entry preview tab title")
            case .homepage: return Text("Home Page", bundle: .module, comment: "app catalog app entry preview tab title")
            }
        }
    }

    func previewSplitItem() -> some View {
        ZStack(alignment: .top) {
            previewTabView()
            previewTabButtonsView()
        }
    }

    /// The ``WebViewState`` for the currently selected tab.
    var currentWebViewState: WebViewState? {
        switch self.previewTabDefaulted.wrappedValue {
        case .screenshots:
            return nil
        case .project:
            return projectHomeWebViewState
        case .homepage:
            return appHomeWebViewState
        }
    }

    @ViewBuilder func previewTabButtonsView() -> some View {
        HStack {
            //tabSizingButtonsView()
            Spacer()
            previewBrowserButtonsView()
        }
    }

    @SceneStorage("previewAreaPinned") var previewAreaPinned = false

    @ViewBuilder func XXXtabSizingButtonsView() -> some View {
        GroupBox {
            HStack {
            }
        }
        .background(Material.thick)
        .padding(.horizontal)
    }

    @State var previewBrowserLoadingAnimation = 0.0

    @ViewBuilder func previewBrowserButtonsView() -> some View {
        GroupBox {
            HStack {
                if let webViewState = self.currentWebViewState {
                    Group {
                        webViewState.navigateAction(brief: true, amount: -1, symbol: FairSymbol.arrow_left_circle.image)
                            .hoverSymbol()
                        webViewState.navigateAction(brief: true, amount: +1, symbol: FairSymbol.arrow_right_circle.image)
                            .hoverSymbol()
                        webViewState.reloadButton(rotationBinding: $previewBrowserLoadingAnimation)
                            .hoverSymbol()
                        //Divider().frame(height: 15)
                        webViewState.copyURLButton()
                            .hoverSymbol()
                        webViewState.openInBrowserButton(action: openURLAction)
                            .hoverSymbol()
                    }
                    .buttonStyle(.plain)
                    .labelStyle(.iconOnly)
                }

                Text("Pin", bundle: .module, comment: "button title for pinning embedded browser")
                    .label(image: previewAreaPinned == true ? FairSymbol.pin_fill : FairSymbol.pin)
                    .button {
                        //dbg(wip("maximize"))
                        withAnimation(.none) {
                            previewAreaPinned.toggle()
                        }
                    }
                    .buttonStyle(.plain)
                    .labelStyle(.iconOnly)
                    .hoverSymbol()
                    .help(Text("Maximizes the preview area so it takes all the available space", bundle: .module, comment: "button tooltip for embedded browser maximize"))

            }
        }
        .background(Material.thick)
        .padding(.horizontal)
    }

    /// The preview tabs, including screenshots and the homepage
    func previewTabView() -> some View {
        TabView(selection: previewTabDefaulted) {
            ForEach(PreviewTab.allCases, id: \.self) { tab in
                Group {
                    switch tab {
                    case .screenshots:
                        screenshotsSection()
                    case .project:
                        if info.isCask || info.isGitHubHostedApp {
                            projectBrowserViewSection()
                        }
                    case .homepage:
                        if info.isCask || info.isGitHubHostedApp {
                            homepageBrowserViewSection()
                        }
                    }
                }
                .tag(tab)
                .tabItem {
                    tab.title
                }
            }
        }
    }

    func browserView(_ webViewState: WebViewState) -> some View {
        CatalogItemBrowserView(inlineHosts: fairManager.openLinksInNewBrowser == true ? [CatalogItemView.permittedHostsRegex] : nil)
            .environmentObject(webViewState)
    }

    @ViewBuilder func projectBrowserViewSection() -> some View {
        browserView(projectHomeWebViewState)
    }

    @ViewBuilder func homepageBrowserViewSection() -> some View {
        browserView(appHomeWebViewState)
    }

    func screenshotsSection() -> some View {
        ScrollView(.horizontal) {
            screenshotsStackView()
        }
        .overlay(Group {
            if metadata.screenshotURLs?.isEmpty != false {
                VStack {
                    Spacer()
                    Label {
                        Text("No screenshots available", bundle: .module, comment: "placeholder string for empty screenshot preview section") // ([contribute…](https://www.appfair.app/#customize_app))")
                            .lineLimit(1)
                            .font(Font.callout)
                            .help(Text("This app has not published any screenshots", bundle: .module, comment: "tooltip for empty screenshot preview section"))
                    } icon: {
                        unavailableIcon
                    }
                    .padding()
                    Spacer()


                    Text("(if you own or maintain this app, you can [contribute](https://www.appfair.app/#customize_app) screenshots and other metadata)", bundle: .module, comment: "footer markdown text of screenshots page indicating how to update catalog metadata")
                        .font(Font.caption)
                        .lineLimit(1)
                        .help(Text("Click here for information on customizing screenshots and other metadata for this app.", bundle: .module, comment: "tooltip text for footer of screenshots page indicating how to update catalog metadata"))

                }
                .foregroundColor(.secondary)
            }
        })
    }

    func overviewTabView() -> some View {
        TabView(selection: $overviewTab) {
            ForEach(OverviewTab.allCases, id: \.self) { tab in
                Group {
                    switch tab {
                    case .description:
                        ReadmeBox(info: info)
                    case .version:
                        ReleaseNotesBox(info: info)
                    case .caveats:
                        if let cask = info.cask, let caveats = cask.caveats {
                            textBox(.success(AttributedString(caveats)))
                        }
                    }
                }
                .tag(tab)
                .tabItem {
                    Label {
                        if tab == .version, let version = metadata.version, version.count < 16 {
                            Text(verbatim: version)
                        } else {
                            tab.title
                        }
                    } icon: {
                        //fetchingReadme > 0 ? FairSymbol.hourglass : FairSymbol.atom
                    }
                }
            }
        }
    }

    func metadataTabView() -> some View {
        TabView(selection: $metadataTab) {
            ForEach(MetadataTab.allCases, id: \.self) { tab in
                Group {
                    switch tab {
                    case .details:
                        detailsListView()
                    case .permissions:
                        if info.isGitHubHostedApp {
                            permissionsSection()
                        }
                    case .security:
                        if info.isGitHubHostedApp {
                            //SecurityBox(info: info) // TODO: make this human-readable for presentation instead of showing the raw JSON
                        }
                    case .formula:
                        if let cask = info.cask {
                            CaskFormulaBox(cask: cask, json: false)
                        } else {
                            AppInfoDetailBox(info: info)
                        }
                    }
                }
                .tag(tab)
                .tabItem {
                    tab.title
//                    Label {
//                    } icon: {
//                        // fetchingFormula > 0 ? FairSymbol.hourglass : FairSymbol.atom
//                    }
                }
            }
        }
    }

    // MARK: README


    // MARK: Description / Summary

    func permissionsSection() -> some View {
        let riskLabel = info.isCask ? Text("Risk: Unknown", bundle: .module, comment: "label for unknown rick") : Text("Risk: ", bundle: .module, comment: "prefix string for risk label") + metadata.riskLevel.textLabel().fontWeight(.regular)

        let riskIcon = (info.isCask ? nil : metadata)?.riskLevel.riskLabel()
            .help(metadata.riskLevel.riskSummaryText())
            .labelStyle(IconOnlyLabelStyle())
            .padding(.trailing)

        return groupBox(title: riskLabel, trailing: riskIcon) {
            permissionsList()
                .overlay(Group {
                    if info.isCask {
                        Text("Risk assessment unavailable for Homebrew Casks", bundle: .module, comment: "placeholder string")
                            .label(image: unavailableIcon)
                            .padding()
                            .lineLimit(1)
                            .font(Font.callout)
                            .foregroundColor(.secondary)
                            .help(Text("Risk assessment is only available for App Fair Fairground apps", bundle: .module, comment: "tooltip text"))
                    }
                })
        }
    }

    func permissionListItem(permission: AppEntitlementPermission) -> some View {
        let entitlement = permission.identifier

        var title = entitlement.localizedInfo.title
        if !permission.usageDescription.isEmpty {
            title = Text("\(title) – \(Text(permission.usageDescription))", bundle: .module, comment: "formatting string separating the permission title from the permission description").foregroundColor(.secondary).italic()
        }

        return title.label(image: entitlement.localizedInfo.symbol.image)
            .listItemTint(ListItemTint.monochrome)
            .symbolRenderingMode(SymbolRenderingMode.monochrome)
            .lineLimit(1)
            .truncationMode(.tail)
        //.textSelection(.enabled)
            .help(Text("\(entitlement.localizedInfo.info): \(Text(permission.usageDescription))", bundle: .module, comment: "formatting string separating entitlement info from usage description in tooltip text"))
    }

    func permissionListItem(permission: AppBackgroundModePermission) -> some View {
        Text(permission.identifier.rawValue)
    }

    func permissionListItem(permission: AppUsagePermission) -> some View {
        Text(permission.identifier.rawValue)
    }

    func permissionListItem(permission: AppUnrecognizedPermission) -> some View {
        Text(permission.identifier ?? permission.type)
    }

    func permissionsList() -> some View {
        List {
            if metadata.permissionsEntitlements?.isEmpty == false {
                Section {
                    ForEach((metadata.permissionsEntitlements ?? []).uniquing(by: \.self), id: \.self, content: permissionListItem)
                } header: {
                    Text("Entitlements", bundle: .module, comment: "section header title in permissions section of catalog item")
                }
            }
            if metadata.permissionsUsage?.isEmpty == false {
                Section {
                    ForEach((metadata.permissionsUsage ?? []).uniquing(by: \.self), id: \.self, content: permissionListItem)
                } header: {
                    Text("Usage", bundle: .module, comment: "section header title in permissions section of catalog item")
                }
            }
            if metadata.permissionsBackgroundMode?.isEmpty == false {
                Section {
                    ForEach((metadata.permissionsBackgroundMode ?? []).uniquing(by: \.self), id: \.self, content: permissionListItem)
                } header: {
                    Text("Background Modes", bundle: .module, comment: "section header title in permissions section of catalog item")
                }
            }
            if metadata.permissionsUnrecognized?.isEmpty == false {
                Section {
                    ForEach((metadata.permissionsUnrecognized ?? []).uniquing(by: \.self), id: \.self, content: permissionListItem)
                } header: {
                    Text("Other", bundle: .module, comment: "section header title in permissions section of catalog item")
                }
            }
        }
        .conditionally {
#if os(macOS)
            $0.listStyle(.bordered(alternatesRowBackgrounds: true))
#endif
        }
    }

    func previewImage(_ url: URL) -> some View {
        //CachedImageCache
        URLImage(url: url, resizable: .fit) // fairManager.imageCache)
    }

    func screenshotsStackView() -> some View {
        LazyHStack(alignment: .center) {
            Spacer()
            ForEach(metadata.screenshotURLs ?? [], id: \.self) { url in
                previewImage(url)
                    .matchedGeometryEffect(id: url, in: namespace, properties: self.previewScreenshot == url ? [.frame] : [], anchor: .center, isSource: self.previewScreenshot != url)
                    .contentShape(Rectangle())
                    .button {
                        dbg("open screenshot:", url.relativePath)
                        withAnimation(Animation.spring(response: 0.45, dampingFraction: 0.9)) {
                            self.previewScreenshot = url
                        }
                    }
                    .buttonStyle(.zoomable)
            }
            Spacer()
        }
    }

    func screenshotPreviewOverlay() -> some View {
        ZStack {
            if self.previewScreenshot != nil {
                Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            }

            ForEach(metadata.screenshotURLs ?? [], id: \.self) { url in
                let presenting = self.previewScreenshot == url

                ZStack {
                    URLImage(url: url, resizable: .fit) // fairManager.imageCache)
                        .matchedGeometryEffect(id: url, in: namespace, isSource: presenting)
                        .shadow(color: Color.black.opacity(presenting ? 0.2 : 0), radius: 20, y: 10)
                        .padding(20)

                    // The top button bar
                    VStack {
                        HStack {
                            Spacer()
                            FairSymbol.xmark_circle
                                .image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .hoverSymbol(activeVariant: .none, inactiveVariant: .fill)
                                .button {
                                    withAnimation {
                                        self.previewScreenshot = nil
                                    }
                                }
                                .keyboardShortcut(.escape) // sadly doesn't seem to work
                                .disabled(!presenting)
                                .buttonStyle(.plain)
                                .frame(width: 25, height: 25)
                                .padding()
                        }
                        Spacer()
                    }

                }
                .prefersDefaultFocus(in: namespace)
                .onTapGesture {
                    // tapping anywhere in the view will close the preview
                    withAnimation {
                        self.previewScreenshot = nil
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibility(sortPriority: presenting ? 1 : 0)
                .accessibility(hidden: !presenting)
                .opacity(presenting ? 1 : 0)
            }
        }
    }

    func catalogAuthorRow() -> some View {
        Group {
            let devName = info.app.developerName ?? ""
            if devName.isEmpty {
                Text("Unknown", bundle: .module, comment: "fallback text for unknown developer name")
            } else {
                Text(devName)
            }
        }
    }

    func numberView(number numberStyle: NumberFormatter.Style? = nil, size sizeStyle: ByteCountFormatStyle.Style? = nil, _ path: KeyPath<AppCatalogItem, Int?>) -> some View {
        numberView(number: numberStyle, size: sizeStyle, value: info.app[keyPath: path])
    }

    func numberView(number numberStyle: NumberFormatter.Style? = nil, size sizeStyle: ByteCountFormatStyle.Style? = nil, value: Int?) -> some View {
        if let value = value {
            if let sizeStyle = sizeStyle {
                return Text(Int64(value), format: .byteCount(style: sizeStyle))
            } else {
                return Text(value, format: .number)
            }
        } else {
            return Text(FairSymbol.questionmark.image)
        }
    }

    /// Show a histogram of where the given value lies in the context of other apps in the grouping (TODO)
    func histogramView(_ path: KeyPath<AppCatalogItem, Int?>) -> EmptyView? {
        nil
        //FairSymbol.chart_bar_xaxis.image.resizable()
    }

    func summarySegment<V: View>(@ViewBuilder content: () -> V) -> some View {
        content()
            .lineLimit(1)
            .truncationMode(.middle)
        //.textSelection(.enabled)
        //.hcenter()
    }

    func catalogHeader() -> some View {
        HStack(alignment: .center) {
            fairManager.iconView(for: info, transition: true)
                .frame(width: 60, height: 60)
                .transition(AnyTransition.asymmetric(insertion: AnyTransition.opacity, removal: AnyTransition.scale(scale: 0.75).combined(with: AnyTransition.opacity))) // shrink and fade out the placeholder while fading in the actual icon
                .padding(.leading)

            VStack(alignment: .center) {
                Text(metadata.name)
                    .font(Font.largeTitle)
                    .truncationMode(.middle)
                Text(metadata.subtitle ?? metadata.localizedDescription ?? "")
                    .font(Font.title2)
                    .truncationMode(.tail)
//                catalogAuthorRow()
//                    .font(Font.title3)
//                    .truncationMode(.head)
            }
            //.textSelection(.enabled) // this makes the text turn very dark when it is selected
            .lineLimit(1)
            .allowsTightening(true)
            .hcenter()

            categorySymbol()
                .frame(width: 60, height: 60)
                .padding(.trailing)
        }
    }

    /// The URLs for the app installation
    private var trashAppAuxiliaryURLs: [URL] {
        info.app.installationAuxiliaryURLs(checkExists: true)
    }

    func catalogActionButtons() -> some View {
        let isCatalogApp = info.app.bundleIdentifier == Bundle.main.bundleID

        return GeometryReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    if isCatalogApp {
                        Spacer() // no button to install ourselves
                            .hcenter()
                    } else {
                        installButton()
                            .hcenter()
                    }
                    updateButton()
                        .hcenter()
                    if isCatalogApp || (info.isMobileApp && (fairManager.appSourceInventories.first?.enablePlatformConversion == false || ProcessInfo.isArmMac == false)) {
                        Spacer() // no button to launch ourselves, nor to run an unconverted app
                            .hcenter()
                    } else {
                        launchButton()
                            .hcenter()
                    }
                    revealButton()
                        .hcenter()
                    if isCatalogApp {
                        Spacer() // no button to delete ourselves
                            .hcenter()
                    } else {
                        trashButton()
                            .hcenter()
                    }
                }
                .symbolRenderingMode(.hierarchical)
                .buttonBorderShape(.roundedRectangle)
                .frame(minWidth: proxy.size.width) // cause the buttons to scroll off the view if it is too narrow to hold them all
            }
        }
    }

    func installButton() -> some View {
        button(activity: .install, role: nil, needsConfirm: fairManager.enableInstallWarning)
            .keyboardShortcut(currentActivity == .install ? .cancelAction : .defaultAction)
            .disabled(appInstalled)
            .confirmationDialog(Text("Install \(info.app.name)", bundle: .module, comment: "install button confirmation dialog title"), isPresented: confirmationBinding(.install), titleVisibility: .visible, actions: {
                Text("Download & Install \(info.app.name)", bundle: .module, comment: "install button confirmation dialog confirm button text").button {
                    runTask(activity: .install, confirm: true)
                }
                if let homepage = info.app.homepage {
                    Text("Visit Homepage: \(homepage.host ?? "")", bundle: .module, comment: "install button confirmation dialog visit homepage button text").button {
                        navigate(to: homepage)
                    }
                } else {
                    if let discussionsURL = info.app.discussionsURL {
                        Text("Visit Community Forum", bundle: .module, comment: "install button confirmation dialog visit discussions button text").button {
                            navigate(to: discussionsURL)
                        }
                    }
                }
                // TODO: only show if there are any open issues
                // Text("Visit App Issues Page").button {
                //    openURLAction(info.app.issuesURL)
                // }
                //.help(Text("Opens your web browsers and visits the developer site")) // sadly, tooltips on confirmationDialog buttons don't seem to work
            }, message: installMessage)
            .tint(.green)
    }

    func updateButton() -> some View {
        button(activity: .update)
            .keyboardShortcut(currentActivity == .update ? .cancelAction : .defaultAction)
            .disabled((!appInstalled || !appUpdated))
            .accentColor(.orange)
    }

    func launchButton() -> some View {
        button(activity: .launch)
            .keyboardShortcut(KeyboardShortcut(KeyEquivalent.return, modifiers: .command))
            .disabled(!appInstalled)
            .accentColor(.green)
    }

    func revealButton() -> some View {
        button(activity: .reveal)
            .keyboardShortcut(KeyboardShortcut(KeyEquivalent("i"), modifiers: .command)) // CMD-I
            .disabled(!appInstalled)
            .accentColor(.teal)
    }

    func trashButton() -> some View {
        button(activity: .trash, role: ButtonRole.destructive, needsConfirm: fairManager.enableDeleteWarning)
            .keyboardShortcut(.delete, modifiers: [])
            .disabled(!appInstalled)
        //.accentColor(.red) // coflicts with the red background of the button
            .confirmationDialog(Text("Really delete this app?", bundle: .module, comment: "delete button confirmation dialog title"), isPresented: confirmationBinding(.trash), titleVisibility: .visible, actions: {
                Text("Delete", bundle: .module, comment: "delete button confirmation dialog delete button text").button {
                    runTask(activity: .trash, confirm: true)
                }
            }, message: trashTextView)
    }

    /// The ``Text`` that will appear in the deletion message. This needs to perform formatting by simply appending text, since the message dialog doesn't handle any other types.
    func trashTextView() -> Text {
        var txt = Text("This will remove the application “\(info.app.name)” from your applications folder and place it in the Trash.", bundle: .module, comment: "delete button confirmation dialog body text")
        if !info.isCask {
            let urls = self.trashAppAuxiliaryURLs
            if !urls.isEmpty {
                txt = txt + Text(verbatim: "\n\n")
                txt = txt + Text("This will also remove the following folders that may contain persistent data for the app:", bundle: .module, comment: "delete button confirmation dialog body text for folders to purge")
                txt = txt + Text(verbatim: "\n\n")
                txt = txt + urls
                    .map({ url in
                    Text((url.path as NSString).abbreviatingWithTildeInPath)
                })
                    .joined(separator: Text(verbatim: "\n"))
            }
        }
        return txt
    }

    func installMessage() -> some View {
        let developerName = info.app.developerName ?? ""

        if info.isCask {
            return Text("""
                This will use the Homebrew package manager to download and install the application “\(info.app.name)” from the developer “\(developerName)” at:

                [\(info.app.downloadURL.absoluteString)](\(info.app.downloadURL.absoluteString))

                This app has not undergone any formal review, so you will be installing and running it at your own risk.

                Before installing, you should first review the home page for the app to learn more about it.
                """, bundle: .module, comment: "installation warning for homebrew apps")
        } else {
            let metaURL = info.app.sourceURL?.absoluteString ?? ""
            return Text("""
                This will download and install the application “\(info.app.name)” from the developer “\(developerName)” at:

                \(metaURL)

                This app has not undergone any formal review, so you will be installing and running it at your own risk.

                Before installing, you should first review the Discussions, Issues, and Documentation pages to learn more about the app.
                """, bundle: .module, comment: "installation warning for fairground apps")
        }
    }

    private var metadata: AppCatalogItem {
        info.app
    }

    /// Whether the app is successfully installed
    var appInstalled: Bool {
        fairManager.installedVersion(info) != nil
    }

    /// Whether the given app is up-to-date or not
    var appUpdated: Bool {
        fairManager.appUpdated(info)
    }

    func confirmationBinding(_ activity: CatalogActivity) -> Binding<Bool> {
        Binding {
            confirmations[activity] ?? false
        } set: { newValue in
            confirmations[activity] = newValue
        }
    }

    func cancelTask(activity: CatalogActivity) {
        if currentOperation?.activity == activity {
            currentOperation?.progress.cancel()
            currentOperation = nil
        }
    }

    func runTask(activity: CatalogActivity, confirm confirmed: Bool) {
        if !confirmed {
            confirmations[activity] = true
        } else {
            confirmations[activity] = false // we have confirmed
            currentActivity = activity
            Task(priority: .userInitiated) {
                await performAction(activity: activity)
                currentActivity = nil
            }
        }
    }

    /// The height of the accessory for the buttons
    private let accessoryHeight = 18.0

    private let buttonHeight = 22.0 // a friendly-feeling height

    func button(activity: CatalogActivity, role: ButtonRole? = .none, needsConfirm: Bool = false) -> some View {
        Button(role: role, action: {
            if currentActivity == activity {
                // clicking the button while the operation is being performed will cancel it
                cancelTask(activity: activity)
            } else {
                runTask(activity: activity, confirm: !needsConfirm)
            }
        }, label: {
            HStack(spacing: 0) {
                Group {
                    if currentActivity == activity {
                        ProgressView()
                            .progressViewStyle(.circular) // spinner
                            .controlSize(.mini) // needs to be small to fit in the button
                            .opacity(currentActivity == activity ? 1 : 0)
                    } else {
                        activity.info.systemSymbol
                    }
                }
                .frame(width: 20)
                Group {
                    //GeometryReader { proxy in
                    activity.info.title
                        .font(Font.headline.smallCaps())
                    //.truncationMode(.middle)
                    //.allowsTightening(true)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: true, vertical: true) // needed to prevent text truncation
                    //.opacity(proxy.size.width < 50 ? 0.0 : 1.0) // hide label when the button is too small
                }
                .hcenter()
                Group {
                    if currentActivity == activity {
                        FairSymbol.x_circle
                            .hoverSymbol(activeVariant: .fill, inactiveVariant: .none, animation: .easeInOut) //.symbolRenderingMode(.hierarchical)
                    } else if let activityWarning = warning(for: activity) {
                        EnabledView { enabled in
                            FairSymbol.exclamationmark_triangle_fill
                                .symbolRenderingMode(enabled ? .multicolor : .hierarchical)
                                .help(activityWarning)
                        }
                    } else {
                        FairSymbol.circle
                    }
                }
                .frame(width: 20)
            }
            .frame(height: buttonHeight)
        })
            .buttonStyle(ActionButtonStyle(progress: .constant(currentActivity == activity ? progress.progress.fractionCompleted : 1.0), primary: true, highlighted: false))
            .focusable(true)
            .accentColor(activity.info.tintColor)
            .disabled(currentActivity != nil && currentActivity != activity)
            .animation(.default, value: currentActivity) // make the enabled state of the button animate
            .onHover(perform: { hovering in
                hoverOver(activity: activity, hovering: hovering)
            })
            .help(currentActivity == activity ? (Text("Cancel \(activity.info.title)", bundle: .module, comment: "cancel catalog activity tooltip text")) : activity.info.toolTip)
    }

    func hoverOver(activity: CatalogActivity, hovering: Bool) {
//        switch activity {
//        case .install:
//            self.sponsorIconScale = hovering ? 1.2 : 1.0
//            self.sponsorIconAnimating = hovering
//        case .update:
//            self.sponsorIconScale = hovering ? 2.0 : 1.0
//            self.sponsorIconAnimating = hovering
//        case .trash:
//            self.sponsorIconScale = hovering ? 0.2 : 1.0
//            self.sponsorIconAnimating = hovering
//        case .reveal:
//            break
//        case .launch:
//            break
//        }
    }

    func performAction(activity: CatalogActivity) async {
        switch activity {
        case .install: await installButtonTapped()
        case .update: await updateButtonTapped()
        case .trash: await deleteButtonTapped()
        case .reveal: await revealButtonTapped()
        case .launch: await launchButtonTapped()
        }
    }

    /// Returns a warning if there is likely to be an issue with the given operation
    func warning(for activity: CatalogActivity) -> Text? {
        switch activity {
        case .install, .update:
            if info.app.sha256 == nil {
                return Text("Installation artifact cannot be verified because it has no associated SHA-256 checksum.", bundle: .module, comment: "warning text when installing an item without a checksum")
            }
            return nil

        case .trash:
            return nil
        case .reveal:
            return nil
        case .launch:
            return nil
        }
    }

    func categorySymbol() -> some View {
        //let category = (item.appCategories.first?.groupings.first ?? .create)

        //let img = Image(systemName: category.symbolName.description)
        let img = info.displayCategories.first?.symbol.image ?? FairSymbol.questionmark_square.image
        let baseColor = metadata.itemTintColor()
        return ZStack {
            Circle()
                //.fill(baseColor)
                //.foregroundStyle(.linearGradient(colors: [baseColor, baseColor], startPoint: .top, endPoint: .bottom))
                .foregroundStyle(
                    .linearGradient(colors: [baseColor.opacity(0.8), baseColor], startPoint: .top, endPoint: .bottom)
                )
                .background(Circle().foregroundColor(Color.white)) // need a background of white so the opacity looks right

            img
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(Color.white)
                //.fairTint(simple: true, color: baseColor, scheme: colorScheme)
                .symbolVariant(.fill)
                .symbolRenderingMode(.palette)
                .padding()
                //.brightness(0.4)
            //.foregroundColor(.secondary)
        }
    }

    func card<V1: View, V2: View, V3: View>(_ s1: V1, _ s2: V2, _ s3: V3?) -> some View {
        VStack(alignment: .center) {
            s1
                .textCase(.uppercase)
                .font(.system(size: 11, weight: .bold, design: .default))
            s2
                .font(.system(size: 20, weight: .heavy, design: .rounded))
            if let s3 = s3 {
                s3
                    .padding(.horizontal)
            }
        }
        .foregroundColor(.secondary)
    }

    func startProgress() -> Progress {
        progress.progress = Progress(totalUnitCount: URLSession.progressUnitCount)
        currentOperation?.progress = progress.progress
        return progress.progress
    }

    /// Downcast from ``FairManager`` to ``AppManagement`` protocol.
    private var fairManagement : AppManagement {
        fairManager
    }

    func launchButtonTapped() async {
        dbg("launchButtonTapped")
        await fairManager.trying {
            try await fairManagement.launch(info)
        }
    }

    func installButtonTapped() async {
        dbg("installButtonTapped")
        await fairManager.trying {
            try await fairManagement.install(info, progress: startProgress(), update: false, verbose: true)
        }
    }

    func updateButtonTapped() async {
        dbg("updateButtonTapped")
        await fairManager.trying {
            try await fairManagement.install(info, progress: startProgress(), update: true, verbose: true)
        }
    }

    func revealButtonTapped() async {
        dbg("revealButtonTapped")
        await fairManager.trying {
            try await fairManagement.reveal(info)
        }
    }

    func deleteButtonTapped() async {
        dbg("deleteButtonTapped")
        return await fairManager.trying {
            try await fairManagement.delete(info, verbose: true)
            // also trash any URLs that may be
            for url in self.trashAppAuxiliaryURLs {
                try FileManager.default.trash(url: url)
            }
        }
    }
}

//private let readmeRegex = Result {
//    try NSRegularExpression(pattern: #".*## Description\n(?<description>[^#]+)\n#.*"#, options: .dotMatchesLineSeparators)
//}


/// Regular expression to replace headers with bold text (since markdown doesn't yet support headers)
private let headerRegex = Result {
    try NSRegularExpression(pattern: #"^#+ (?<text>.*)$"#, options: [.anchorsMatchLines])
}

private let githubDownloadRegex = Result {
    try NSRegularExpression(pattern: "https://github.com/[-A-Za-z0-9]*/[-A-Za-z0-9]*/releases/download")
}

fileprivate extension View {
    func textBox(_ text: Result<AttributedString, Error>?) -> some View {
        let astr: AttributedString
        switch text {
        case .none: astr = AttributedString()
        case .success(let str): astr = str
        case .failure(let error): astr = AttributedString(error.localizedDescription, attributes: .init([NSAttributedString.Key.obliqueness: 8]))
        }

        return ZStack {
            ScrollView {
                Text(astr)
                    .textSelection(.enabled) // there's a weird bug here that causes multi-line text to stop wrapping lined when the text box is selected; this seems to be fixed in recent
                    //.fixedSize() // doesn't help
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxHeight: .infinity)

            if text == nil {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    func fetchMarkdownResource(url: URL, info: AppInfo) async throws -> AttributedString {
        let data = try await URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData)
            .fetch(validateFragmentHash: true)
        var atx = String(data: data, encoding: .utf8) ?? ""

//        // extract the portion of text between the "# Description" and following "#" sections
//        if let match = try readmeRegex.get().firstMatch(in: atx, options: [], range: atx.span)?.range(withName: "description") {
//            atx = (atx as NSString).substring(with: match)
//        } else {
//            if !info.isCask { // casks don't have this requirement; permit full READMEs
//                atx = ""
//            }
//        }

        // replace headers (which are unsupported in AttributedString) with simply bold styling
        for match in try headerRegex.get().matches(in: atx, options: [], range: atx.span).reversed() {
            let textRange = match.range(withName: "text")
            let text = (atx as NSString).substring(with: textRange)

            //dbg("replacing header range:", match.range, " with bold text:", text)
            atx = (atx as NSString).replacingCharacters(in: match.range, with: ["**", text, "**"].joined())
        }

        // the README.md relative location is 2 paths down from the repository base, so for relative links to Issues and Discussions to work the same as they do in the web version, we need to append the path that the README would be rendered in the browser

        // note this this differs with casks
        let baseURL = info.app.projectURL?.appendingPathComponent("blob/main/")
        return try AttributedString(markdown: atx.trimmed(), options: .init(allowsExtendedAttributes: true, interpretedSyntax: .inlineOnlyPreservingWhitespace, failurePolicy: .returnPartiallyParsedIfPossible, languageCode: nil), baseURL: baseURL)
    }


}

struct ReadmeBox : View {
    let info: AppInfo

    @State var readmeText: Result<AttributedString, Error>? = nil
    @State var fetchingReadme = 0

    var body: some View {
        descriptionSection()
    }

    func descriptionSection() -> some View {
        textBox(self.readmeText)
            .font(Font.body)
            .task(priority: .low) {
                if fetchingReadme == 0 {
                    fetchingReadme += 1
                    await fetchReadme()
                    fetchingReadme -= 1
                }
            }
    }


    private func fetchReadme() async {
        let readmeURL = info.app.readmeURL
        do {
            //dbg("fetching README for:", info.app.id, readmeURL?.absoluteString)
            if let readmeURL = readmeURL {
                let txt = try await fetchMarkdownResource(url: readmeURL, info: info)
                //withAnimation { // the effect here is weird: it expands from zero width
                    self.readmeText = .success(txt)
                //}
            } else {
                // throw AppError(loc("No description found."))
                self.readmeText = .success(AttributedString(info.app.localizedDescription ?? NSLocalizedString("No description found", bundle: .module, comment: "error message when no app description could be found")))
            }
        } catch {
            dbg("error handling README:", error)
            //if let readmeURL = readmeURL {
                self.readmeText = .failure(error)
            //}
        }
    }


}

struct SecurityBox : View {
    let info: AppInfo

    @State private var securitySummary: Result<AttributedString, Error>? = nil
    @State private var fetchingSecurity = 0

    var body: some View {
        artifactSecuritySection()
    }

    func artifactSecuritySection() -> some View {
        textBox(self.securitySummary)
            .font(Font.body.monospaced())
            .task(priority: .low) {
                if fetchingSecurity == 0 && securitySummary == nil {
                    fetchingSecurity += 1
                    self.securitySummary = await fetchArtifactSecurity(checkFileHash: true)
                    fetchingSecurity -= 1
                }
            }

    }

    func fetchArtifactSecurity(checkFileHash: Bool = true, reparseJSON: Bool = false) async -> Result<AttributedString, Error>? {

        let url: URL?
        if checkFileHash == false {
            let sourceURL = self.info.cask?.url ?? self.info.app.downloadURL.absoluteString
            let urlChecksum = sourceURL.utf8Data.sha256().hex()

            url = URL(string: urlChecksum, relativeTo: URL(string: "https://www.appfair.net/fairscan/urls/"))?.appendingPathExtension("json")

        } else { // use the artifact URL hash
            guard let checksum = self.info.cask?.checksum ?? self.info.app.sha256 else {
                dbg("no checksum for artifact")
                return nil
            }

            if checksum == "no_check" {
                dbg("checksum for artifact is no_check")
                return nil
            }

            url = URL(string: checksum, relativeTo: URL(string: "https://www.appfair.net/fairscan/files/"))?.appendingPathExtension("json") // e.g.: https://www.appfair.net/fairscan/urls/ffea53299849ef43ee26927cbf3ff0342fa6e9a1421059c368fe91a992c9a3a1.json
        }

        guard let url = url else {
            dbg("no URL for info", info.app.name)
            return nil
        }

        do {
            dbg("checking security URL:", url.absoluteString)
            let scanResult = try await URLSession.shared.fetch(request: URLRequest(url: url))
            if !reparseJSON {
                return .success(AttributedString(scanResult.data.utf8String ?? ""))
            } else {
                do {
                    let ob = try JSum(json: scanResult.data)
                    let pretty = try ob.json(outputFormatting: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
                    return .success(AttributedString(pretty.utf8String ?? ""))
                } catch {
                    return .success(AttributedString(scanResult.data.utf8String ?? ""))
                }
            }
        } catch {
            // errors are not unexpected when the user leaves this view:
            // NSURLErrorDomain Code=-999 "cancelled"
            dbg("error checking cask security:", url.absoluteString, "error:", error)
            return .failure(error)
        }
    }
}

struct ReleaseNotesBox : View {
    let info: AppInfo
    @State var releaseNotesText: Result<AttributedString, Error>? = nil
    @State var fetchingReleaseNotes = 0
    @EnvironmentObject var fairManager: FairManager

    var body: some View {
        versionSection()
    }


    @ViewBuilder func versionSection() -> some View {
//        let desc = info.isCask ? info.cask?.caveats : self.info.app.versionDescription
        textBox(self.releaseNotesText)
            .font(.body)
            .task(priority: .low) {
                if fetchingReleaseNotes == 0 {
                    fetchingReleaseNotes += 1
                    await fetchReleaseNotes()
                    fetchingReleaseNotes -= 1
                }
            }
    }

    func fetchReleaseNotes() async {
        do {
            dbg("fetching release notes for app:", info.app.id, info.app.releaseNotesURL?.absoluteString)
            if let versionDescription = info.app.versionDescription {
                self.releaseNotesText = Result { try AttributedString(markdown: versionDescription) }
            } else if let releaseNotesURL = info.app.releaseNotesURL {
                let notes = try await fetchMarkdownResource(url: releaseNotesURL, info: info)
                //withAnimation { // the effect here is weird: it expands from zero width
                    self.releaseNotesText = .success(notes)
                //}
            } else if let cask = info.cask {
                guard let (strategy, appcastURL) = try await fairManager.homeBrewInv?.fetchLivecheck(for: cask.token) else {
                    self.releaseNotesText = .success(AttributedString("Missing release notes"))
                    return
                }

                if !strategy.hasPrefix(":sparkle") {
                    self.releaseNotesText = .success(AttributedString("Incompatible release notes"))
                    return
                }

                let (contents, _) = try await URLSession.shared.fetch(request: URLRequest(url: appcastURL))
                let webFeed = try AppcastFeed(xmlData: contents)

                guard let channel = webFeed.channels.first else {
                    self.releaseNotesText = .success(AttributedString("No release channel"))
                    return
                }
                self.releaseNotesText = .success(AttributedString(channel.title ?? "No title"))
            } else {
                self.releaseNotesText = .success(AttributedString("No release notes"))
            }
        } catch {
            dbg("error handling release notes:", error)
            //if let readmeURL = readmeURL {
                self.releaseNotesText = .failure(error)
            //}
        }
    }

//    func releaseVersionAccessoryView() -> Text? {
//        if let versionDate = info.app.versionDate ?? self.manualURLModifiedDate {
//            return Text(versionDate, format: .dateTime)
//        } else {
//            return nil
//        }
//    }
}

struct AppInfoDetailBox : View, Equatable {
    let info: AppInfo

    var body: some View {
        textBox(.success(AttributedString(info.app.prettyJSON)))
            .font(Font.body.monospaced())
    }
}

struct CaskFormulaBox : View {
    let cask: CaskItem
    let json: Bool

    @EnvironmentObject var fairManager: FairManager

    @State private var caskSummary: Result<AttributedString, Error>? = nil
    @State private var fetchingFormula = 0

    var body: some View {
        caskFormulaSection(cask: cask)
    }

    func caskFormulaSection(cask: CaskItem) -> some View {
        textBox(self.caskSummary)
            .font(Font.body.monospaced())
            .task(priority: .low) {
                if fetchingFormula == 0 {
                    fetchingFormula += 1
                    await fetchCaskSummary(json: json)
                    fetchingFormula -= 1
                }
            }
    }

    private func fetchCaskSummary(json jsonSource: Bool) async {
        if self.caskSummary == nil, let url = jsonSource ? fairManager.homeBrewInv?.caskMetadata(name: cask.token) : fairManager.homeBrewInv?.caskSource(name: cask.token) {
            // self.caskSummary = NSLocalizedString("Loading…", bundle: .module, comment: "") // makes unnecessary flashes
            do {
                dbg("checking cask summary:", url.absoluteString)
                let metadata = try await URLSession.shared.fetch(request: URLRequest(url: url))
                if jsonSource {
                    do {
                        let ob = try JSum(json: metadata.data)
                        let pretty = try ob.json(outputFormatting: [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys])
                        self.caskSummary = .success(AttributedString(pretty.utf8String ?? ""))
                    } catch {
                        self.caskSummary = .success(AttributedString(metadata.data.utf8String ?? ""))
                    }
                } else {
                    self.caskSummary = .success(AttributedString(metadata.data.utf8String ?? ""))
                }
            } catch {
                // errors are not unexpected when the user leaves this view:
                // NSURLErrorDomain Code=-999 "cancelled"
                dbg("error checking cask metadata:", url.absoluteString, "error:", error)
                self.caskSummary = .failure(error)
            }
        }
    }
}

extension CatalogActivity {
    var info: (title: Text, systemSymbol: FairSymbol, tintColor: Color?, toolTip: Text) {
        switch self {
        case .install:
            return (Text("Install", bundle: .module, comment: "catalog entry button title for install action"), .square_and_arrow_down_fill, Color.blue, Text("Download and install the app.", bundle: .module, comment: "catalog entry button tooltip for install action"))
        case .update:
            return (Text("Update", bundle: .module, comment: "catalog entry button title for update action"), .square_and_arrow_down_on_square, Color.orange, Text("Update to the latest version of the app.", bundle: .module, comment: "catalog entry button tooltip for update action")) // TODO: when pre-release, change to "Update to the latest pre-release version of the app"
        case .trash:
            return (Text("Delete", bundle: .module, comment: "catalog entry button title for delete action"), .trash, Color.red, Text("Delete the app from your computer.", bundle: .module, comment: "catalog entry button tooltip for delete action"))
        case .reveal:
            return (Text("Reveal", bundle: .module, comment: "catalog entry button title for reveal action"), .doc_viewfinder_fill, Color.indigo, Text("Displays the app install location in the Finder.", bundle: .module, comment: "catalog entry button tooltip for reveal action"))
        case .launch:
            return (Text("Launch", bundle: .module, comment: "catalog entry button title for launch action"), .checkmark_seal, Color.green, Text("Launches the app.", bundle: .module, comment: "catalog entry button tooltip for launch action"))
        }
    }
}

extension AppInfo {
    var projectURL: URL? {
        if isCask {
            if let homepage = self.cask?.homepage,
               homepage.hasPrefix("https://github.com/") {
                return URL(string: homepage)
            } else {
                return nil
            }
        } else {
            return app.projectURL // TODO: check non-fairground apps
        }
    }

    /// We are idenfitied as a cask item if we have no version date (which casks don't include in their metadata)
    /// - TODO: @available(*, deprecated, message: "check source catalog instead")
    var isCask: Bool {
        cask != nil
    }

    /// Returns `true` if this is an app whose path extension is `.ipa`
    var isGitHubHostedApp: Bool {
        (try! githubDownloadRegex.get()).hasMatches(in: app.downloadURL.absoluteString) == true
    }

    /// Returns `true` if this is an app whose path extension is `.ipa`
    var isMobileApp: Bool {
        app.isMobileApp
    }
}


extension AppCatalogItem {
    /// Returns `true` if this is an app whose path extension is `.ipa`
    var isMobileApp: Bool {
        // TODO: self.platforms.contains(.ios)
        wipipa(self.downloadURL.pathExtension == "ipa")
    }

    /// The specified tint color, falling back on the default tint for the app name
    func itemTintColor() -> Color {
        self.tintColor() ?? FairIconView.iconColor(name: self.appNameHyphenated)
    }


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

#if os(macOS)
/// Repliction of iOS's `PageTabViewStyle` for macOS
typealias PaginatedTabViewStyle = DefaultTabViewStyle

//struct PaginatedTabViewStyle : TabViewStyle {
//    static func _makeView<SelectionValue>(value: _GraphValue<_TabViewValue<PaginatedTabViewStyle, SelectionValue>>, inputs: _ViewInputs) -> _ViewOutputs where SelectionValue : Hashable {
//        //_ViewOutputs(value)
//        // inputs.outputs
//    }
//
//    static func _makeViewList<SelectionValue>(value: _GraphValue<_TabViewValue<PaginatedTabViewStyle, SelectionValue>>, inputs: _ViewListInputs) -> _ViewListOutputs where SelectionValue : Hashable {
//        // inputs
//    }
//}

extension TabViewStyle where Self == PaginatedTabViewStyle {

    /// The page `TabView` style.
    static var paginated: PaginatedTabViewStyle { PaginatedTabViewStyle() }
}
#endif

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
            configuration.icon.frame(width: 16) // otherwise, icons are not aligned
        }
    }
}

struct ZoomableButtonStyle: ButtonStyle {
    var zoomLevel = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? zoomLevel : 1, anchor: .center)
    }
}

extension ButtonStyle where Self == ZoomableButtonStyle {
    static var zoomable: ZoomableButtonStyle {
        ZoomableButtonStyle()
    }

    static func zoomable(level: Double = 0.95) -> ZoomableButtonStyle {
        ZoomableButtonStyle(zoomLevel: level)
    }
}

extension NSRegularExpression {
    /// Returns true if the given regular expression has any matches with the specified string
    func hasMatches(in string: String) -> Bool {
        numberOfMatches(in: string, range: string.span) > 0
    }
}

struct CatalogItemBrowserView : View {
    /// If non-nil, only domain
    let inlineHosts: [NSRegularExpression]?
    @Environment(\.openURL) var openURLAction
    @EnvironmentObject var webViewState: WebViewState

    /// Returns `true` if the given URL should be opened in an external browser
    func shouldOpenInExternalBrowser(url: URL) -> Bool {
        guard let inlineHosts = inlineHosts else {
            return false // free-form browser
        }

        if let host = url.host {
            for exp in inlineHosts {
                if exp.numberOfMatches(in: host, options: [], range: host.span) > 0 {
                    return false
                }
            }
        }
        return true
    }

    var body: some View {
        WebView(state: webViewState)
            .webViewNavigationActionPolicy(decide: { action, state in
                //dbg("navigation:", action, "type:", action.navigationType)
                // clicking on links will open in a new browser
                if let url = action.request.url,
                   action.navigationType == .linkActivated,
                   shouldOpenInExternalBrowser(url: url) == true {
                    dbg("lanching url in new browser:", url.absoluteString)
                    openURLAction(url)
                    return (.cancel, nil)
                } else {
                    //dbg("traversing url in browser:", action.request.url?.absoluteString)
                    return (.allow, nil)
                }
            })
    }
}

////struct CatalogItemView_Previews: PreviewProvider {
//    static var previews: some View {
//        CatalogItemView(info: AppInfo(source: .appSourceFairgroundMacOS, app: AppCatalogItem.sample), source: .appSourceFairgroundMacOS)
//            //.environmentObject(AppSourceInventory.default)
//            .frame(width: 700)
//            .frame(height: 800)
//        //.environment(\.locale, Locale(identifier: "fr"))
//    }
//}
