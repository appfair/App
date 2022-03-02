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

    @EnvironmentObject var fairManager: FairManager
    @EnvironmentObject var fairAppInv: FairAppInventory
    @EnvironmentObject var homeBrewInv: HomebrewInventory
    @Environment(\.openURL) var openURLAction
    @Environment(\.colorScheme) var colorScheme

    @State private var caskURLFileSize: Int64? = nil
    @State private var caskURLModifiedDate: Date? = nil

    @State private var previewScreenshot: URL? = nil

    private var currentOperation: CatalogOperation? {
        get {
            fairAppInv.operations[info.id]
        }

        nonmutating set {
            fairAppInv.operations[info.id] = newValue
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

    func catalogStack() -> some View {
        VStack {
            VStack(spacing: 0) {
                catalogHeader()
                    .padding(.vertical)
                    .background(Material.ultraThinMaterial)
                Divider()
            }
            catalogActionButtons()
                .frame(height: buttonHeight + 12)
            Divider()
            catalogSummaryCards()
                .frame(height: 40)
            Divider()
            catalogOverview()
        }
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
                numberView(number: .decimal, \.downloadCount)
                    .help(info.isCask ? Text("The number of downloads of this cask in the past 90 days") : Text("The total number of downloads for this release")),
                histogramView(\.downloadCount)
            )
        }
    }

    func sizeCard() -> some View {
        summarySegment {
            card(
                Text("Size"),
                downloadSizeView(),
                histogramView(\.fileSize)
            )
        }
    }

    func downloadSizeView() -> some View {
        Group {
            if info.isCask {
                if let caskURLFileSize = caskURLFileSize, caskURLFileSize > 0 { // sometimes -1 when it isn't found
                    numberView(size: .file, value: Int(caskURLFileSize))
                } else {
                    // show the card view with an empty file size
                    Text("Unknown")
                        .redacted(reason: .placeholder)
                        .task {
                            await fetchDownloadURLStats()
                        }
                }
            } else {
                numberView(size: .file, \.fileSize)
            }
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
                releaseDateView(),
                histogramView(\.issueCount)
            )
        }
    }

    func releaseDateView() -> some View {
        Group {
            if let date = item.versionDate ?? self.caskURLModifiedDate {
                Text(date, format: .relative(presentation: .numeric, unitsStyle: .wide))
            } else {
                Text("Unknown")
                    .redacted(reason: .placeholder)
            }
        }
    }

    private func fetchCaskSummary(jsonSource: Bool = false) async {
        if let cask = self.info.cask, self.caskSummary == nil, let url = jsonSource ? homeBrewInv.caskMetadata(name: cask.token) : homeBrewInv.caskSource(name: cask.token) {
            // self.caskSummary = NSLocalizedString("Loading…", comment: "") // makes unnecessary flashes
            do {
                dbg("checking cask summary:", url.absoluteString)
                let metadata = try await URLSession.shared.fetch(request: URLRequest(url: url))
                if jsonSource {
                    do {
                        let ob = try JSONSerialization.jsonObject(with: metadata.data, options: .topLevelDictionaryAssumed)
                        let pretty = try JSONSerialization.data(withJSONObject: ob, options: [.prettyPrinted, .sortedKeys])
                        self.caskSummary = pretty.utf8String
                    } catch {
                        self.caskSummary = metadata.data.utf8String
                    }
                } else {
                    self.caskSummary = metadata.data.utf8String
                }
            } catch {
                // errors are not unexpected when the user leaves this view:
                // NSURLErrorDomain Code=-999 "cancelled"
                dbg("error checking cask metadata:", url.absoluteString, "error:", error)
            }
        }
    }

    private func fetchDownloadURLStats() async {
        if homeBrewInv.manageCaskDownloads == true {
            do {
                dbg("checking URL HEAD:", item.downloadURL.absoluteString)
                let head = try await URLSession.shared.fetchHEAD(url: item.downloadURL, cachePolicy: .reloadRevalidatingCacheData)
                // in theory, we could also try to pre-flight out expected SHA-256 checksum by checking for a header like "Digest: sha-256=A48E9qOokqqrvats8nOJRJN3OWDUoyWxBf7kbu9DBPE=", but in practice no server ever seems to send it
                self.caskURLFileSize = head.expectedContentLength
                self.caskURLModifiedDate = head.lastModifiedDate
                dbg("URL HEAD:", item.downloadURL.absoluteString, self.caskURLFileSize?.localizedByteCount(), self.caskURLFileSize, (head as? HTTPURLResponse)?.allHeaderFields as? [String: String])

            } catch {
                // errors are not unexpected when the user leaves this view:
                // NSURLErrorDomain Code=-999 "cancelled"
                dbg("error checking URL size:", item.downloadURL.absoluteString, "error:", error)
            }
        }
    }

    func catalogSummaryCards() -> some View {
        HStack(alignment: .center) {
            starsCard()
                .opacity(info.isCask ? 0.0 : 1.0)
            Divider()
            releaseDateCard()
            Divider()
            downloadsCard()
            Divider()
            sizeCard()
            Divider()
            issuesCard()
                .opacity(info.isCask ? 0.0 : 1.0)
            //watchersCard()
        }
        //.frame(height: 54)
    }

    func linkTextField(_ title: Text, icon: String, url: URL?, linkText: String? = nil) -> some View {
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
                .label(symbol: icon)
                .lineLimit(1)
                .labelStyle(.titleAndIconFlipped)
                .link(to: url)
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

    func detailsView() -> some View {
        ScrollView {
            Form {
                if let cask = info.cask {
                    if let page = cask.homepage, let homepage = URL(string: page) {
                        linkTextField(Text("Homepage"), icon: FairSymbol.house.symbolName, url: homepage)
                            .help(Text("Opens link to the home page for this app at: \(homepage.absoluteString)"))
                    }

                    if let downloadURL = cask.url, let downloadURL = URL(string: downloadURL) {
                        linkTextField(Text("Download"), icon: FairSymbol.arrow_down_circle.symbolName, url: downloadURL)
                            .help(Text("Opens link to the direct download for this app at: \(downloadURL.absoluteString)"))
                    }

                    if let appcast = cask.appcast, let appcast = URL(string: appcast) {
                        linkTextField(Text("Appcast"), icon: FairSymbol.dot_radiowaves_up_forward.symbolName, url: appcast)
                            .help(Text("Opens link to the appcast for this app at: \(appcast.absoluteString)"))
                    }

                    if let sha256 = cask.checksum ?? "None" {
                        linkTextField(Text("Checksum"), icon: FairSymbol.rosette.symbolName, url: cask.checksum == nil ? nil : URL(string: "https://github.com/Homebrew/formulae.brew.sh/search?q=" + sha256), linkText: sha256)
                            .help(Text("The SHA-256 checksum for the app download"))
                    }

                    if let tapToken = cask.tapToken, let tapURL = cask.tapURL {
                        linkTextField(Text("Cask Token"), icon: FairSymbol.esim.symbolName, url: tapURL, linkText: tapToken)
                            .help(Text("The page for the Homebrew Cask token"))
                    }

                    linkTextField(Text("Auto-Updates"), icon: FairSymbol.sparkle.symbolName, url: nil, linkText: cask.auto_updates == nil ? "Unknown" : cask.auto_updates == true ? "Yes" : "No")
                        .help(Text("Whether this app handles updating itself"))

                } else {
                    if let landingPage = info.release.landingPage {
                        linkTextField(Text("Home"), icon: FairSymbol.house.symbolName, url: landingPage)
                            .help(Text("Opens link to the landing page for this app at: \(landingPage.absoluteString)"))
                    }
                    if let discussionsURL = info.release.discussionsURL {
                        linkTextField(Text("Discussions"), icon: FairSymbol.text_bubble.symbolName, url: discussionsURL)
                            .help(Text("Opens link to the discussions page for this app at: \(discussionsURL.absoluteString)"))
                    }
                    if let issuesURL = info.release.issuesURL {
                        linkTextField(Text("Issues"), icon: FairSymbol.checklist.symbolName, url: issuesURL)
                            .help(Text("Opens link to the issues page for this app at: \(issuesURL.absoluteString)"))
                    }
                    if let sourceURL = info.release.sourceURL {
                        linkTextField(Text("Source"), icon: FairSymbol.chevron_left_forwardslash_chevron_right.symbolName, url: sourceURL)
                            .help(Text("Opens link to source code repository for this app at: \(sourceURL.absoluteString)"))
                    }
                    if let fairsealURL = info.release.fairsealURL {
                        linkTextField(Text("Fairseal"), icon: FairSymbol.rosette.symbolName, url: fairsealURL, linkText: String(info.release.sha256 ?? ""))
                            .help(Text("Lookup fairseal at: \(info.release.fairsealURL?.absoluteString ?? "")"))
                    }
                    if let developerURL = info.release.developerURL {
                        linkTextField(Text("Developer"), icon: FairSymbol.person.symbolName, url: developerURL, linkText: item.developerName)
                            .help(Text("Searches for this developer at: \(info.release.developerURL?.absoluteString ?? "")"))
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

        var title: Text {
            switch self {
            case .description: return Text("Description")
            case .version: return Text("Version")
            }
        }
    }

    @State var metadataTab = MetadataTab.details

    enum MetadataTab : CaseIterable, Hashable {
        case details
        case risk
        case formula
        case security

        var title: Text {
            switch self {
            case .details: return Text("Details")
            case .risk: return Text("Risk")
            case .formula: return Text("Formula")
            case .security: return Text("Security")
            }
        }
    }


    func catalogOverview() -> some View {
        VStack {
            HStack {
                overviewTabView()
                metadataTabView()
            }

            groupBox(title: Text("Screenshots"), trailing: EmptyView()) {
                ScrollView(.horizontal) {
                    previewView()
                }
                .overlay(Group {
                    if item.screenshotURLs?.isEmpty != false {
                        Text("No screenshots available") // ([contribute…](https://www.appfair.app/#customize_app))")
                            .label(image: unavailableIcon)
                            .padding()
                            .lineLimit(1)
                            .font(Font.callout)
                            .foregroundColor(.secondary)
                            .help(Text("This app has not published any screenshots"))
                    }
                })
            }
        }
        .padding()

    }

    func overviewTabView() -> some View {
        TabView(selection: $overviewTab) {
            ForEach(OverviewTab.allCases, id: \.self) { tab in
                Group {
                    switch tab {
                    case .description:
                        descriptionSection()
                    case .version:
                        versionSection()
                    }
                }
                .tag(tab)
                .tabItem {
                    Label {
                        if tab == .version, let version = item.version, version.count < 16 {
                            Text(verbatim: version)
                        } else {
                            tab.title
                        }
                    } icon: {
                        fetchingReadme > 0 ? FairSymbol.hourglass : FairSymbol.atom
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
                        detailsView()
                    case .risk:
                        if info.cask == nil {
                            riskSection()
                        }
                    case .formula:
                        if let cask = info.cask {
                            caskFormulaSection(cask: cask)
                        }
                    case .security:
                        artifactSecuritySection()
                    }
                }
                .tag(tab)
                .tabItem {
                    Label {
                        tab.title
                    } icon: {
                        fetchingFormula > 0 ? FairSymbol.hourglass : FairSymbol.atom
                    }
                }
            }
        }
    }

    // MARK: README

    @State var readmeText: Result<AttributedString, Error>? = nil
    @State var fetchingReadme = 0

    func descriptionSection() -> some View {
        ScrollView {
            Group {
                Text(readmeText?.successValue ?? "")
                    .task {
                        if fetchingReadme == 0 {
                            fetchingReadme += 1
                            await fetchReadme()
                            fetchingReadme -= 1
                        }
                    }
                    .font(Font.body)
                    .redacting(when: self.readmeText == nil)
                    .font(Font.body.monospaced())
            }
            .textSelection(.enabled)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private static let readmeRegex = Result {
        try NSRegularExpression(pattern: #".*## Description\n(?<description>[^#]+)\n#.*"#, options: .dotMatchesLineSeparators)
    }

    private func fetchReadme() async {
        let readmeURL = info.release.readmeURL
        do {
            dbg("fetching README for:", info.release.id, readmeURL?.absoluteString)
            if let readmeURL = readmeURL {
                let data = try await URLRequest(url: readmeURL, cachePolicy: .reloadRevalidatingCacheData)
                    .fetch(validateFragmentHash: true)
                var atx = String(data: data, encoding: .utf8) ?? ""
                // extract the portion of text between the "# Description" and following "#" sections
                if let match = try Self.readmeRegex.get().firstMatch(in: atx, options: [], range: atx.span)?.range(withName: "description") {
                    atx = (atx as NSString).substring(with: match)
                } else {
                    if !info.isCask { // casks don't have this requirement; permit full READMEs
                        atx = ""
                    }
                }

                // the README.md relative location is 2 paths down from the repository base, so for relative links to Issues and Discussions to work the same as they do in the web version, we need to append the path that the README would be rendered in the browser

                // note this this differs with casks
                let baseURL = info.release.baseURL?.appendingPathComponent("blob/main/")
                self.readmeText = Result {
                    try AttributedString(markdown: atx.trimmed(), options: .init(allowsExtendedAttributes: true, interpretedSyntax: .inlineOnlyPreservingWhitespace, failurePolicy: .returnPartiallyParsedIfPossible, languageCode: nil), baseURL: baseURL)
                }
            }
        } catch {
            dbg("error handling README:", error)
            //if let readmeURL = readmeURL {
                self.readmeText = .failure(error)
            //}
        }
    }

    /// The accessory on the trailing section of a `groupBox`
    @ViewBuilder func progressAccessory(_ fetching: Int) -> some View {
        ProgressView()
            .opacity(fetching > 0 ? 1.0 : 0.0).controlSize(.mini)
            .padding(.trailing, 8)
            .animation(Animation.easeInOut, value: fetching)
    }

    // MARK: Description / Summary

    @State var caskSummary: String? = nil
    @State var fetchingFormula = 0

    func caskFormulaSection(cask: CaskItem) -> some View {
        ScrollView {
            caskSummaryText()
                .textSelection(.enabled)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: .infinity)
    }

    func caskSummaryText() -> some View {
        Text(self.caskSummary ?? "")
            .task {
                if fetchingFormula == 0 {
                    fetchingFormula += 1
                    await fetchCaskSummary()
                    fetchingFormula -= 1
                }
            }
            .font(Font.body.monospaced())
            .redacting(when: self.caskSummary == nil)
    }

    func versionSection() -> some View {
        ScrollView {
            versionSummary()
        }
        .frame(maxHeight: .infinity)
    }

    func releaseVersionAccessoryView() -> Text? {
        if let versionDate = info.release.versionDate ?? self.caskURLModifiedDate {
            return Text(versionDate, format: .dateTime)
        } else {
            return nil
        }
    }

    func riskSection() -> some View {
        let riskLabel = info.isCask ? Text("Risk: Unknown") : Text("Risk: ") + item.riskLevel.textLabel().fontWeight(.regular)

        let riskIcon = (info.isCask ? nil : item)?.riskLevel.riskLabel()
            .help(item.riskLevel.riskSummaryText())
            .labelStyle(IconOnlyLabelStyle())
            .padding(.trailing)

        return groupBox(title: riskLabel, trailing: riskIcon) {
            permissionsList()
                .overlay(Group {
                    if info.isCask {
                        Text("Risk assessment unavailable for Homebrew Casks")
                            .label(image: unavailableIcon)
                            .padding()
                            .lineLimit(1)
                            .font(Font.callout)
                            .foregroundColor(.secondary)
                            .help(Text("Risk assessment is only available for App Fair Fairground apps"))
                    }
                })
        }
    }

    @State var securitySummary: String? = nil
    @State var fetchingSecurity = 0

    func artifactSecuritySection() -> some View {
        ScrollView {
            Text(self.securitySummary ?? "")
                .task {
                    if fetchingSecurity == 0 && securitySummary == nil {
                        fetchingSecurity += 1
                        var summary = ""

                        // the url check doesn't seem to actually scan the file, but rather checks the URL itself for dydgy behavior
//                        if let urlSec = await fetchArtifactSecurity(checkFileHash: false) {
//                            summary += urlSec
//                        }

                        if let hashSec = await fetchArtifactSecurity(checkFileHash: true) {
                            summary += hashSec
                        }

                        if summary.isEmpty {
                            summary = loc("No security information available for artifact")
                        }

                        self.securitySummary = summary
                        fetchingSecurity -= 1
                    }
                }
                .font(Font.body.monospaced())
                .textSelection(.enabled)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: .infinity)
    }

    func fetchArtifactSecurity(checkFileHash: Bool = true, reparseJSON: Bool = false) async -> String? {

        let url: URL?
        if checkFileHash == false {
            let sourceURL = self.info.cask?.url ?? self.info.release.downloadURL.absoluteString
            let urlChecksum = sourceURL.utf8Data.sha256().hex()

            url = URL(string: urlChecksum, relativeTo: URL(string: "https://www.appfair.net/fairscan/urls/"))?.appendingPathExtension("json")

        } else { // use the artifact URL hash
            guard let checksum = self.info.cask?.checksum ?? self.info.release.sha256 else {
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
            dbg("no URL for info", info.release.name)
            return nil
        }

        do {
            dbg("checking security URL:", url.absoluteString)
            let scanResult = try await URLSession.shared.fetch(request: URLRequest(url: url))
            if !reparseJSON {
                return scanResult.data.utf8String
            } else {
                do {
                    let ob = try JSONSerialization.jsonObject(with: scanResult.data, options: .topLevelDictionaryAssumed)
                    let pretty = try JSONSerialization.data(withJSONObject: ob, options: [.prettyPrinted, .sortedKeys])
                    return pretty.utf8String
                } catch {
                    return scanResult.data.utf8String
                }
            }
        } catch {
            // errors are not unexpected when the user leaves this view:
            // NSURLErrorDomain Code=-999 "cancelled"
            dbg("error checking cask security:", url.absoluteString, "error:", error)
            return nil
        }
    }

    func versionSummary() -> some View {
        // casks don't report their versions, so instead we use any caveats in the metadata
        let desc = info.isCask ? info.cask?.caveats : self.info.release.versionDescription
        return Text(atx: desc ?? "")
            .font(.body)
            .textSelection(.enabled)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    func permissionListItem(permission: AppPermission) -> some View {
        let entitlement = permission.type

        var title = entitlement.localizedInfo.title
        if !permission.usageDescription.isEmpty {
            title = title + Text(" – ") + Text(permission.usageDescription).foregroundColor(.secondary).italic()
        }

        return title.label(symbol: entitlement.localizedInfo.symbol.symbolName)
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

    func previewImage(_ url: URL) -> some View {
        URLImage(url: url, resizable: .fit)
    }

    func previewView() -> some View {
        LazyHStack {
            ForEach(item.screenshotURLs ?? [], id: \.self) { url in
                previewImage(url)
                    .matchedGeometryEffect(id: url, in: namespace, isSource: self.previewScreenshot != url)
                    .contentShape(Rectangle())
                    .button {
                        dbg("open screenshot:", url.relativePath)
                        withAnimation(Animation.spring(response: 0.45, dampingFraction: 0.9)) {
                            self.previewScreenshot = url
                        }
                    }
                    .buttonStyle(.zoomable)
            }
        }
    }

    func screenshotPreviewOverlay() -> some View {
        ZStack {
            if self.previewScreenshot != nil {
                Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            }

            ForEach(item.screenshotURLs ?? [], id: \.self) { url in
                let presenting = self.previewScreenshot == url

                ZStack {
                    URLImage(url: url, resizable: ContentMode.fit, showProgress: false)
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
            let devName = info.release.developerName ?? ""
            if devName.isEmpty {
                Text("Unknown")
            } else {
                Text(devName)
            }
        }
    }

    func numberView(number numberStyle: NumberFormatter.Style? = nil, size sizeStyle: ByteCountFormatStyle.Style? = nil, _ path: KeyPath<AppCatalogItem, Int?>) -> some View {
        numberView(number: numberStyle, size: sizeStyle, value: info.release[keyPath: path])
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
            .hcenter()
    }

    func catalogHeader() -> some View {
        HStack(alignment: .center) {
            fairManager.iconView(for: info)
                .frame(width: 60, height: 60)
                .padding(.leading)

            VStack(alignment: .center) {
                Text(item.name)
                    .font(Font.largeTitle)
                    .truncationMode(.middle)
                Text(item.subtitle ?? item.localizedDescription ?? "")
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

    func catalogActionButtons() -> some View {
        let isCatalogApp = info.release.bundleIdentifier.rawValue == Bundle.main.bundleID

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
                    if isCatalogApp {
                        Spacer() // no button to launch ourselves
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
            .confirmationDialog(Text("Install \(info.release.name)"), isPresented: confirmationBinding(.install), titleVisibility: .visible, actions: {
                Text("Download & Install \(info.release.name)").button {
                    runTask(activity: .install, confirm: true)
                }
                if let cask = info.cask {
                    if let page = cask.homepage, let homepage = URL(string: page) {
                        (Text("Visit Homepage: ") + Text(homepage.host ?? "")).button {
                            openURLAction(homepage)
                        }
                    }
                } else {
                    if let discussionsURL = info.release.discussionsURL {
                        Text("Visit Community Forum").button {
                            openURLAction(discussionsURL)
                        }
                    }
                }
                // TODO: only show if there are any open issues
                // Text("Visit App Issues Page").button {
                //    openURLAction(info.release.issuesURL)
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
            .confirmationDialog(Text("Really delete this app?"), isPresented: confirmationBinding(.trash), titleVisibility: .visible, actions: {
                Text("Delete").button {
                    runTask(activity: .trash, confirm: true)
                }
            }, message: {
                Text("This will remove the application “\(info.release.name)” from your applications folder and place it in the Trash.")
            })
    }

    func installMessage() -> some View {
        if info.isCask {
            return Text(atx: """
                This will use the Homebrew package manager to download and install the application “\(info.release.name)” from the developer “\(info.release.developerName ?? "")” at:

                [\(info.release.downloadURL.absoluteString)](\(info.release.downloadURL.absoluteString))

                This app has not undergone any formal review, so you will be installing and running it at your own risk.

                Before installing, you should first review the home page for the app to learn more about it.
                """)
        } else {
            return Text(atx: """
                This will download and install the application “\(info.release.name)” from the developer “\(info.release.developerName ?? "")” at:

                \(info.release.sourceURL?.absoluteString ?? "")

                This app has not undergone any formal review, so you will be installing and running it at your own risk.

                Before installing, you should first review the Discussions, Issues, and Documentation pages to learn more about the app.
                """)
        }
    }

    private var item: AppCatalogItem {
        info.release
    }

    /// The plist for the given installed app
    var appPropertyList: Result<Plist, Error>? {
        let installPath = FairAppInventory.appInstallPath(for: item)
        let result = fairAppInv.installedApps[installPath]
        //dbg("install for item:", item, "install path:", fairAppInv.appInstallPath(for: item).path, "plist:", result != nil, "installedApps:", fairAppInv.installedApps.keys.map(\.path))

        if result == nil {
            //dbg("install path not found:", installPath, "in keys:", fairAppInv.installedApps.keys)
        }
        return result
    }

    /// Returns the URLs that are registered with the system `NSWorkspace` for handling the app's bundle
    @available(*, deprecated, message: "unsuitable for use with bindings because NSWorkspace.shared.urlsForApplications sometimes has a delay")
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
        // dbg("token:", info.id.rawValue, "plist:", appPropertyList?.successValue)
        if info.isCask {
            return homeBrewInv.installedCasks[info.id.rawValue]?.isEmpty == false
        }

        return appPropertyList?.successValue?.bundleID == info.id.rawValue
        //!appInstallURLs.isEmpty // this is more accurate, but NSWorkspace.shared.urlsForApplications has a delay in returning the correct information sometimes
    }

    /// Whether the given app is up-to-date or not
    var appUpdated: Bool {
        if info.isCask {
            let versions = homeBrewInv.installedCasks[info.id.rawValue] ?? []
            return info.release.version.flatMap(versions.contains) != true
        }

        return (appPropertyList?.successValue?.appVersion ?? .max) < (info.releasedVersion ?? .min)
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
    let accessoryHeight = 18.0

    let buttonHeight = 22.0 // a friendly-feeling height

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
            .animation(.easeIn(duration: 0.25), value: currentActivity) // make the enabled state of the button animate
            .help(currentActivity == activity ? (Text("Cancel ") + activity.info.title) : activity.info.toolTip)
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
            if info.release.sha256 == nil {
                return Text("Installation artifact cannot be verified because it has no associated SHA-256 checksum.")
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
        let img = item.appCategories.first?.symbol.image ?? (info.isCask ? AppSource.homebrew.symbol.image : AppSource.fairapps.symbol.image)
        let baseColor = item.itemTintColor()
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

    func installButtonTapped() async {
        dbg("installButtonTapped")
        await fairAppInv.trying {
            if let cask = info.cask {
                try await homeBrewInv.install(cask: cask, progress: startProgress(), update: false)
            } else {
                try await fairAppInv.install(item: item, progress: startProgress(), update: false)
            }
        }
    }

    func launchButtonTapped() async {
        dbg("launchButtonTapped")
        if info.isCask == true {
            await fairManager.trying {
                try await homeBrewInv.launch(item: item, gatekeeperCheck: true)
            }
        } else {
            await fairAppInv.launch(item: item)
        }
    }

    func updateButtonTapped() async {
        dbg("updateButtonTapped")
        await fairAppInv.trying {
            if let cask = info.cask {
                try await homeBrewInv.install(cask: cask, progress: startProgress(), update: true)
            } else {
                try await fairAppInv.install(item: item, progress: startProgress(), update: true)
            }
        }
    }

    func revealButtonTapped() async {
        dbg("revealButtonTapped")
        if info.isCask == true {
            await fairManager.trying {
                try await homeBrewInv.reveal(item: item)
            }
        } else {
            await fairAppInv.reveal(item: item)
        }
    }

    func deleteButtonTapped() async {
        dbg("deleteButtonTapped")
        if let cask = info.cask {
            return await fairManager.trying {
                try await homeBrewInv.delete(cask: cask)
            }
        } else {
            await fairAppInv.trash(item: item)
        }
    }
}

private extension CatalogActivity {
    var info: (title: Text, systemSymbol: FairSymbol, tintColor: Color?, toolTip: Text) {
        switch self {
        case .install:
            return (Text("Install"), .square_and_arrow_down_fill, Color.blue, Text("Download and install the app."))
        case .update:
            return (Text("Update"), .square_and_arrow_down_on_square, Color.orange, Text("Update to the latest version of the app.")) // TODO: when pre-release, change to "Update to the latest pre-release version of the app"
        case .trash:
            return (Text("Delete"), .trash, Color.red, Text("Delete the app from your computer."))
        case .reveal:
            return (Text("Reveal"), .doc_viewfinder_fill, Color.indigo, Text("Displays the app install location in the Finder."))
        case .launch:
            return (Text("Launch"), .checkmark_seal_fill, Color.green, Text("Launches the app."))
        }
    }
}

///// Internal cache to prevent icons from needing to reload so much
//private let iconCache = NSCache<NSURL, ImageInfo>()
//
//private final class ImageInfo {
//    let image: SwiftUI.Image
//
//    init(image: SwiftUI.Image) {
//        self.image = image
//    }
//}

extension AppCatalogItem {
    @ViewBuilder func iconImage() -> some View {
        if let iconURL = self.iconURL {
            AsyncImage(url: iconURL, scale: 1.0, transaction: Transaction(animation: .easeIn)) { phase in
                switch phase {
                case .success(let image):
                    //let _ = iconCache.setObject(ImageInfo(image: image), forKey: iconURL as NSURL)
                    image
                        .resizable(resizingMode: .stretch)
                        .aspectRatio(contentMode: .fit)
                case .failure(let error):
                    let _ = dbg("error fetching icon from:", iconURL.absoluteString, "error:", error.isURLCancelledError ? "Cancelled" : error.localizedDescription)
                    fallbackIcon()
                        .grayscale(0.9)
                        .help(error.localizedDescription)
                case .empty:
//                    if let image = iconCache.object(forKey: iconURL as NSURL) {
//                        image.image
//                            .resizable(resizingMode: .stretch)
//                            .aspectRatio(contentMode: .fit)
//                    } else {
                    fallbackIcon()
                        .grayscale(0.5)
//                    }
                @unknown default:
                    fallbackIcon()
                        .grayscale(0.8)
                }
            }
        } else {
            fallbackIcon()
                .grayscale(1.0)
        }
    }

    @ViewBuilder func fallbackIcon() -> some View {
        // fall-back to the generated image for the app, but with no title or sub-title
        //        if id.isCaskApp {
        //            // cask apps use a blank icon
        //        } else {
        //FairIconView(self.name, subtitle: self.id.rawValue, iconColor: itemTintColor())
        //
        let baseColor = itemTintColor()
        Circle()
            .fill(baseColor)
            .opacity(0.5)
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
            .scaleEffect(configuration.isPressed ? zoomLevel : 1)
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

@available(macOS 12.0, iOS 15.0, *)
struct CatalogItemView_Previews: PreviewProvider {
    static var previews: some View {
        CatalogItemView(info: AppInfo(release: AppCatalogItem.sample))
            .environmentObject(FairAppInventory())
            .frame(width: 700)
            .frame(height: 800)
        //.environment(\.locale, Locale(identifier: "fr"))
    }
}
