import FairApp


/// A manager for [Homebrew casks](https://formulae.brew.sh/docs/api/)
@available(macOS 12.0, iOS 15.0, *)
@MainActor public final class CaskManager: ObservableObject {
    private static let endpoint = URL(string: "https://formulae.brew.sh/api/")!

    private static let formulaList = URL(string: "formula.json", relativeTo: endpoint)!
    private static let caskList = URL(string: "cask.json", relativeTo: endpoint)!

    private static let caskStats30 = URL(string: "analytics/cask-install/homebrew-cask/30d.json", relativeTo: endpoint)!
    private static let caskStats90 = URL(string: "analytics/cask-install/homebrew-cask/90d.json", relativeTo: endpoint)!
    private static let caskStats365 = URL(string: "analytics/cask-install/homebrew-cask/365d.json", relativeTo: endpoint)!

    // private static let installCommand = #"/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"#

    /// Command that is expected to return `/usr/local` for macOS Intel and `/opt/homebrew` for Apple Silicon
    private static let checkBrewCommand = #"brew --prefix"#

    /// The default install prefix for homebrew: “This script installs Homebrew to its preferred prefix (/usr/local for macOS Intel, /opt/homebrew for Apple Silicon and /home/linuxbrew/.linuxbrew for Linux) so that you don’t need sudo when you brew install. It is a careful script; it can be run even if you have stuff installed in the preferred prefix already. It tells you exactly what it will do before it does it too. You have to confirm everything it will do before it starts.”
    private static let brewInstallRoot = URL(fileURLWithPath: ProcessInfo.isArmMac ? "/opt/homebrew" : "/usr/local")

    /// The source of the brew command for [manual installation](https://docs.brew.sh/Installation#untar-anywhere)
    private static let brewArchiveURL = URL(string: "https://github.com/Homebrew/brew/archive/refs/heads/master.zip")!

    /// The source to the cask ruby definition file
    private static func caskSource(name: String) -> URL? {
        URL(string: "cask-source/\(name).rb", relativeTo: endpoint)!
    }

    /// The path to the `homebrew` command
    static var localBrewCommand: String {
        URL(fileURLWithPath: "bin/brew", relativeTo: brewInstallRoot).path
    }

    static let `default`: CaskManager = CaskManager()

    /// The current catalog of casks
    @Published var casks: [CaskItem] = []

    /// The installed casks
    @Published var installed: [CaskItem] = []

    /// The latest statistics about the apps
    @Published var stats: CaskStats?

    func refreshAll() async throws {
        async let a1: Void = fetchCasks()
        async let a2: Void = fetchStats()
        async let a3 = Task { try await refreshInstalledApps() }
        let (_, _, _) = try await (a1, a2, a3) // execute at the same time
    }

    /// Fetches the cask list and populates it in the `casks` property
    func fetchCasks() async throws {
        let url = Self.caskList
        let data = try await URLRequest(url: url).fetch()
        dbg("loaded cask list", data.count.localizedByteCount(), "from url:", url)
        self.casks = try Array<CaskItem>(json: data)
    }

    /// Fetches the cask stats and populates it in the `stats` property
    func fetchStats(statsURL: URL? = nil) async throws {
        let url = statsURL ?? Self.caskStats30
        let data = try await URLRequest(url: url).fetch()

        dbg("loaded cask stats", data.count.localizedByteCount(), "from url:", url)
        try self.stats = CaskStats(json: data)
    }

    /// Processes the installed apps
    func refreshInstalledApps() throws {
        // outputs the installed apps list
        let cmd = Self.localBrewCommand + " info --quiet --cask --installed --json=v2"
        guard let json = try NSAppleScript.fork(command: cmd) else {
            throw AppError("No output from brew command")
        }

        struct BrewInstallOutput : Decodable {
            // var formulae: [Formulae] // unused
            var casks: [CaskItem]
        }

        let output = try BrewInstallOutput(json: json.utf8Data)
        self.installed = output.casks
    }

    // NOTE: the docs recommend to use “the default prefix. Some things may not build when installed elsewhere” and “Pick another prefix at your peril!”
    @available(*, deprecated, message: "not yet implemented")
    static func installBrew(at rootURL: URL) async throws {
        // 1. Download and unzip: https://github.com/Homebrew/brew/archive/refs/heads/master.zip
        let request = URLRequest(url: brewArchiveURL)

        let (downloadedArtifact, response) = try await URLSession.shared.download(request: request, memoryBufferSize: 1024 * 64, consumer: nil, parentProgress: nil)

        dbg("downloaded brew package from:", request, "response:", response)

        try FileManager.default.unzipItem(at: downloadedArtifact, to: rootURL)

        dbg("unpackaged brew package at:", rootURL)

        // 2. execute: `eval "$(homebrew/bin/brew shellenv)"`

        // 3. execute: `brew update --force --quiet`
    }

}

extension CaskManager {
    func arrangedItems(category: AppManager.SidebarItem?, sortOrder: [KeyPathComparator<AppInfo>], searchText: String) -> [AppInfo] {
        let installMap = installed.grouping(by: \.full_token)
        let analyticsMap = stats?.formulae ?? [:]

        // dbg("casks:", caskMap.keys.sorted())

        var infos: [AppInfo] = []
        for cask in casks {

            if let downloadURL = cask.url.flatMap(URL.init(string:)) {
                let id = cask.full_token
                let downloads = analyticsMap[id]?.first?.installCount
                let name = cask.name.first ?? id
                // dbg("downloads for:", name, downloads)
                let installed = installMap[cask.full_token]?.first // TODO: convert installed into a Plist?

                let versionDate: Date? = wip(nil)
                let item = AppCatalogItem(name: name, bundleIdentifier: BundleIdentifier(id), subtitle: cask.desc ?? "", developerName: cask.homepage ?? "", localizedDescription: cask.desc ?? "", size: 0, version: cask.version, versionDate: versionDate, downloadURL: downloadURL, iconURL: wip(nil), screenshotURLs: [], versionDescription: nil, tintColor: nil, beta: wip(false), sourceIdentifier: wip(id), categories: wip([]), downloadCount: downloads, starCount: wip(nil), watcherCount: wip(nil), issueCount: wip(nil), sourceSize: wip(nil), coreSize: wip(nil), sha256: cask.sha256, permissions: wip(nil), metadataURL: wip(nil), readmeURL: wip(nil))

                var plist: Plist? = nil
                if let installed = installed {
                    plist = Plist(rawValue: [InfoPlistKey.CFBundleVersion.rawValue: installed])
                }
                let info = AppInfo(release: item, installedPlist: plist)
                infos.append(info)
            }
        }

        return infos
            .sorted(using: sortOrder + [KeyPathComparator(\AppInfo.release.downloadCount, order: .reverse)])
    }

    func badgeCount(for item: AppManager.SidebarItem) -> Text? {
        wip(nil)
    }
}

private extension ProcessInfo {
    /// Returns `true` if we are running on an ARM Mac, even if we are running under Rosetta emulation
    static let isArmMac: Bool = {
        var cpu_type: cpu_type_t = 0
        var cpu_type_size = MemoryLayout.size(ofValue: cpu_type)
        if -1 == sysctlbyname("hw.cputype", &cpu_type, &cpu_type_size, nil, 0) {
            return false // should not happen
        }

        if (cpu_type & CPU_TYPE_ARM) == CPU_TYPE_ARM {
            return true
        }

        // When the app is running under Rosetta, hw.cputype reports an Intel CPU
        // We want to know the real CPU type, so we have to check for Rosetta
        // If we detect Rosetta, we are running on ARM
        var is_translated: Int = 0;
        var is_translated_size = MemoryLayout.size(ofValue: is_translated)
        if -1 == sysctlbyname("sysctl.proc_translated", &is_translated, &is_translated_size, nil, 0) {
            // if this call fails we are probably running on Intel
            return false
        }
        else if is_translated != 0 {
            // process is translated with Rosetta -> we must be on ARM
            return true
        }
        else {
            return false
        }
    }()
}

/// ```{"category":"cask_install","total_items":6190,"start_date":"2021-12-05","end_date":"2022-01-04","total_count":894812,"items":[{"number":1,"cask":"google-chrome","count":"34,530","percent":"3.86"},{"number":2,"cask":"iterm2","count":"31,096","percent":"3.48"},{"number":6190,"cask":"zulufx11","count":"1","percent":"0"}]}```
/// https://formulae.brew.sh/docs/api/#list-analytics-events-for-all-cask-formulae
struct CaskStats : Equatable, Decodable {
    /// E.g., `cask_install`
    let category: String

    /// E.g., `6190`
    let total_items: Int

    /// E.g., `2021-12-05`
    let start_date: String

    /// E.g., `2022-01-04`
    let end_date: String

    /// E.g., `894812`
    let total_count: Int

    /// Note that the docs call this `items`(see [API Docs](https://formulae.brew.sh/docs/api/#response-5)), but the API returns `formulae`.
    let formulae: [String: [Stat]]

    /// `{"number":1,"cask":"google-chrome","count":"34,530","percent":"3.86"}`
    struct Stat : Equatable, Decodable {
        let cask: String
        /// This is a numeric string (US localized with commas), but since it ought to be a number and maybe someday will be, also permit a number
        let count: XOr<String>.Or<Int>

        /// Handles parsing number; we should probably do this with custom de-serialization code instead
        var installCount: Int {
            switch count {
            case .p(let p):
                return Self.formatter.number(from: p)?.intValue ?? 0
            case .q(let q):
                return q
            }
        }

        private static let formatter: NumberFormatter = {
            let fmt = NumberFormatter()
            fmt.numberStyle = .decimal
            fmt.isLenient = true
            fmt.locale = Locale(identifier: "en_US")
            return fmt
        }()
    }
}

/*
 ```
 {
   "token": "alfred",
   "full_token": "alfred",
   "tap": "homebrew/cask",
   "name": [
     "Alfred"
   ],
   "desc": "Application launcher and productivity software",
   "homepage": "https://www.alfredapp.com/",
   "url": "https://cachefly.alfredapp.com/Alfred_4.6.1_1274.dmg",
   "appcast": null,
   "version": "4.6.1,1274",
   "versions": {},
   "installed": null,
   "outdated": false,
   "sha256": "2851a6da00e8ad85bb000931a1d9dbda00d27402d4e3b7c8fbd77d8956b009b3",
   "artifacts": [
     {
       "quit": "com.runningwithcrayons.Alfred",
       "signal": {}
     },
     [
       "Alfred 4.app"
     ],
     {
       "trash": [
         "~/Library/Application Support/Alfred",
         "~/Library/Caches/com.runningwithcrayons.Alfred",
         "~/Library/Cookies/com.runningwithcrayons.Alfred.binarycookies",
         "~/Library/Preferences/com.runningwithcrayons.Alfred.plist",
         "~/Library/Preferences/com.runningwithcrayons.Alfred-Preferences.plist",
         "~/Library/Saved Application State/com.runningwithcrayons.Alfred-Preferences.savedState"
       ],
       "signal": {}
     }
   ],
   "caveats": null,
   "depends_on": {},
   "conflicts_with": null,
   "container": null,
   "auto_updates": true
 }
 ```
*/
struct CaskItem : Equatable, Decodable {
    /// The token of the cask. E.g., `alfred`
    let token: String

    /// E.g., `4.6.1,1274`
    let version: String

    /// E.g., `["Alfred"]`
    let name: [String]

    /// E.g., `"Application launcher and productivity software"`
    let desc: String?

    /// E.g., `https://www.alfredapp.com/`
    let homepage: String?

    /// E.g., `https://cachefly.alfredapp.com/Alfred_4.6.1_1274.dmg`
    let url: String?

    /// E.g., `alfred` or `appfair/app/bon-mot`
    let full_token: String

    /// E.g., `homebrew/cask` or `appfair/app`
    let tap: String?

    /// E.g., `https://nucleobytes.com/4peaks/index.html`
    let appcast: String?

    /// E.g., `5.8.3.2240`
    let installed: String? // always nil whe taked from API

    // TODO
    // let versions": {},

    // let outdated: false // not relevent for API

    /// The SHA-256 hash of the artiface
    let sha256: String

    /// E.g.: `app has been officially discontinued upstream`
    let caveats: String?

    let auto_updates: Bool?

    // TODO
    //    let artifacts": [
    //      {
    //        "quit": "com.runningwithcrayons.Alfred",
    //        "signal": {}
    //      },
    //      [
    //        "Alfred 4.app"
    //      ],
    //      {
    //        "trash": [
    //          "~/Library/Application Support/Alfred",
    //          "~/Library/Caches/com.runningwithcrayons.Alfred",
    //          "~/Library/Cookies/com.runningwithcrayons.Alfred.binarycookies",
    //          "~/Library/Preferences/com.runningwithcrayons.Alfred.plist",
    //          "~/Library/Preferences/com.runningwithcrayons.Alfred-Preferences.plist",
    //          "~/Library/Saved Application State/com.runningwithcrayons.Alfred-Preferences.savedState"
    //        ],
    //        "signal": {}
    //      }
    //    ],

    /// E.g., `{"macos":{">=":["10.12"]}}`
    // let depends_on": {},

    /// E.g.: `"conflicts_with":{"cask":["homebrew/cask-versions/1password-beta"]}`
    // let conflicts_with: null
    
    /// E.g.: `"container":"{:type=>:zip}"`
    // let container": null,

}

