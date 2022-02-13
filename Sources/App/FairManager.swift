import FairApp

@available(macOS 12.0, iOS 15.0, *)
@MainActor public final class FairManager: SceneManager {
    /// The appManager, which should be extracted as a separate `EnvironmentObject`
    let fairAppInv = FairAppInventory()
    /// The caskManager, which should be extracted as a separate `EnvironmentObject`
    let homeBrewInv = HomebrewInventory()

    @AppStorage("themeStyle") var themeStyle = ThemeStyle.system

    @AppStorage("enableInstallWarning") public var enableInstallWarning = true
    @AppStorage("enableDeleteWarning") public var enableDeleteWarning = true

    /// The base domain of the provider for the hub
    @AppStorage("hubProvider") public var hubProvider = "github.com"
    /// The organization name of the hub
    @AppStorage("hubOrg") public var hubOrg = appfairName
    /// The name of the base repository for the provider
    @AppStorage("hubRepo") public var hubRepo = AppNameValidation.defaultAppName

    /// An optional authorization token for direct API usagefor the organization
    @AppStorage("hubToken") public var hubToken = ""

    // list rendering on ARM is very slow when there are more than 1000 results, so just show the first few hundred
    @AppStorage("maxDisplayItems") public var maxDisplayItems = 1_000

    /// The fetched readmes for the apps
    @Published private var readmes: [URL: Result<AttributedString, Error>] = [:]

    private static let readmeRegex = Result {
        try NSRegularExpression(pattern: #".*## Description\n(?<description>[^#]+)\n#.*"#, options: .dotMatchesLineSeparators)
    }

    required internal init() {
        super.init()

        /// The gloal quick actions for the App Fair
        self.quickActions = [
            QuickAction(id: "refresh-action", localizedTitle: loc("Refresh Catalog")) { completion in
                dbg("refresh-action")
                Task {
                    //await self.appManager.fetchApps(cache: .reloadIgnoringLocalAndRemoteCacheData)
                    completion(true)
                }
            }
        ]
    }

    func refresh() async throws {
        async let v1: () = fairAppInv.refreshAll()
        async let v2: () = homeBrewInv.refreshAll()
        let _ = try await (v1, v2) // perform the two refreshes in tandem
    }

    /// Attempts to perform the given action and adds any errors to the error list if they fail.
    func trying(block: () async throws -> ()) async {
        do {
            try await block()
        } catch {
            fairAppInv.errors.append(error as? AppError ?? AppError(error))
        }
    }

    func updateCount() -> Int {
        return fairAppInv.updateCount()
            + (homeBrewInv.enableHomebrew ? homeBrewInv.updateCount() : 0)
    }

    @ViewBuilder func iconView(for info: AppInfo) -> some View {
        if info.isCask == true {
            homeBrewInv.icon(for: info.release, useInstalledIcon: false)
        } else {
            info.release.iconImage()
        }
    }

    func readme(for info: AppInfo) -> AttributedString? {
        guard let readmeURL = info.release.readmeURL else {
            return nil
        }

        if let result = self.readmes[readmeURL] {
            switch result {
            case .success(let string): return string
            case .failure(let error): return AttributedString("Error: \(error)")
            }
        }

        Task {
            do {
                dbg("fetching README for:", info.release.id, readmeURL.absoluteString)
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
                self.readmes[readmeURL] = Result {
                    try AttributedString(markdown: atx.trimmed(), options: .init(allowsExtendedAttributes: true, interpretedSyntax: .inlineOnlyPreservingWhitespace, failurePolicy: .returnPartiallyParsedIfPossible, languageCode: nil), baseURL: baseURL)
                }
            } catch {
                dbg("error handling README:", error)
                self.readmes[readmeURL] = .failure(error)
            }
        }

        return nil
    }




}

extension Error {
    /// Returns true if this error indicates that the user cancelled an operaiton
    var isURLCancelledError: Bool {
        (self as NSError).domain == NSURLErrorDomain && (self as NSError).code == -999
    }
}
