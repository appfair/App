import FairApp



extension AppCatalogItem {

    /// We are idenfitied as a cask item if we have no version date (which casks don't include in their metadata)
    var isCask: Bool {
        bundleIdentifier.isCaskApp
        //starCount == nil && forkCount == nil && versionDate == nil
    }

    /// The home page for this cask
    var caskHomepage: URL? {
        guard isCask else { return nil }
        // developerName is overloaded as the URL
        return URL(string: developerName)
    }

    /// The basename of the local cache file for this item's download URL
    fileprivate var cacheBasePath: String {
        let url = self.downloadURL
        let urlHash = url.absoluteString.utf8Data.sha256().hex()
        let baseName = url.lastPathComponent
        let cachePath = urlHash + "--" + baseName
        return cachePath
    }
}


/// A unique identifier for a bundle. Note that this overloads the "BundleIdentifier" concept, which may make more sense
typealias CaskIdentifier = BundleIdentifier

extension CaskIdentifier {
    /// Returns true if this is a homebrew cask (vs. a fairapp)
    var isCaskApp: Bool {
        rawValue.hasPrefix("homebrew/cask/")
    }

    var caskToken: String? {
        if rawValue.hasPrefix("homebrew/cask/") {
            return String(rawValue.dropFirst(14))
        } else {
            return nil
        }
    }
}

#if CASK_SUPPORT // declared in Package.swift

/// These functions are placed in an extension so they do not become subject to the `MainActor` restrictions.
extension InstallationManager where Self : CaskManager {

    /// The default install prefix for homebrew: “This script installs Homebrew to its preferred prefix (/usr/local for macOS Intel, /opt/homebrew for Apple Silicon and /home/linuxbrew/.linuxbrew for Linux) so that you don’t need sudo when you brew install. It is a careful script; it can be run even if you have stuff installed in the preferred prefix already. It tells you exactly what it will do before it does it too. You have to confirm everything it will do before it starts.”
    ///
    /// Note that on Intel, `/usr/local/bin/brew -> /usr/local/Homebrew/bin/brew`, but we shouldn't use `/usr/local/Homebrew/` as the brew root since `/usr/local/Caskroom` exists but `/usr/local/Homebrew/Caskroom` does not.
    static var brewInstallRoot: URL { URL(fileURLWithPath: ProcessInfo.isArmMac ? "/opt/homebrew" : "/usr/local") }

    /// The path to the `homebrew` command
    static var localBrewCommand: URL {
        URL(fileURLWithPath: "bin/brew", relativeTo: brewInstallRoot)
    }

    /// Installation is check simply by seeing if the brew install root exists.
    /// This will be used as the seed for the `includeCasks` app preference so we default to having it enabled if homebrew is seen as being installed
    static var isHomebrewInstalled: Bool {
        FileManager.default.isExecutableFile(atPath: localBrewCommand.path)
    }

}

/// A manager for [Homebrew casks](https://formulae.brew.sh/docs/api/)
@available(macOS 12.0, iOS 15.0, *)
@MainActor public final class CaskManager: ObservableObject, InstallationManager {
    /// The arranged list of app info items
    @Published private(set) var appInfos: [AppInfo] = []

    /// The current catalog of casks
    @Published private var casks: [CaskItem] = [] { didSet { updateAppInfo() } }

    /// Map of installed apps from `[token: [versions]]`
    @Published private(set) var installedCasks: [CaskItem.ID: Set<String>] = [:] { didSet { updateAppInfo() } }

    /// The latest statistics about the apps
    @Published private var stats: CaskStats? { didSet { updateAppInfo() } }

    @Published private var sortOrder = [KeyPathComparator(\AppInfo.release.downloadCount, order: .reverse)] { didSet { updateAppInfo() } }

    @AppStorage("quarantineCasks") private var quarantineCasks = true
    @AppStorage("forceInstallCasks") private var forceInstallCasks = true
    @AppStorage("preCacheCasks") private var preCacheCasks = true

    // private static let installCommand = #"/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"#

    /// Command that is expected to return `/usr/local` for macOS Intel and `/opt/homebrew` for Apple Silicon
    private static let checkBrewCommand = #"brew --prefix"#

    /// The source of the brew command for [manual installation](https://docs.brew.sh/Installation#untar-anywhere)
    private static let brewArchiveURL = URL(string: "https://github.com/Homebrew/brew/archive/refs/heads/master.zip")!


    private static let endpoint = URL(string: "https://formulae.brew.sh/api/")!

    private static let formulaList = URL(string: "formula.json", relativeTo: endpoint)!
    private static let caskList = URL(string: "cask.json", relativeTo: endpoint)!

    private static let caskStats30 = URL(string: "analytics/cask-install/homebrew-cask/30d.json", relativeTo: endpoint)!
    private static let caskStats90 = URL(string: "analytics/cask-install/homebrew-cask/90d.json", relativeTo: endpoint)!
    private static let caskStats365 = URL(string: "analytics/cask-install/homebrew-cask/365d.json", relativeTo: endpoint)!

    /// The source to the cask ruby definition file
    private static func caskSource(name: String) -> URL? {
        URL(string: "cask-source/\(name).rb", relativeTo: endpoint)!
    }

    /// The path where cask metadata and links are stored
    static var localCaskroom: URL {
        URL(fileURLWithPath: "Caskroom", relativeTo: brewInstallRoot)
    }

    static let `default`: CaskManager = CaskManager()

    private var fsobserver: FileSystemObserver? = nil

    internal init() {
        if Self.isHomebrewInstalled == true &&
            FileManager.default.isDirectory(url: Self.localCaskroom) == true {
            // set up a file-system observer for the install folder, which will refresh the installed apps whenever any changes are made; this allows external processes like homebrew to update the installed app
            self.fsobserver = FileSystemObserver(URL: Self.localCaskroom, queue: .main) {
                dbg("changes detected in cask folder:", Self.localCaskroom.path)
                // we need a small delay here because brew seems to create the directory eagerly before it unpacks and moves the app, which means there is often a signifcant delay between when the change occurs and the app version is available there
                for delay in [0, 1, 5] {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay)) {
                        try? self.scanInstalledCasks()
                    }
                }
            }
        }

    }

    func refreshAll() async throws {
        async let a1: Void = fetchCasks()
        async let a2: Void = fetchStats()
        async let a3 = Task { try await scanInstalledCasks() }
        let (_, _, _) = try await (a1, a2, a3) // execute them all at the same time
    }

    /// Fetches the cask list and populates it in the `casks` property
    func fetchCasks() async throws {
        dbg("loading cask list")
        let url = Self.caskList
        let data = try await URLRequest(url: url).fetch()
        dbg("loaded cask list", data.count.localizedByteCount(), "from url:", url)
        self.casks = try Array<CaskItem>(json: data)
    }

    /// Fetches the cask stats and populates it in the `stats` property
    func fetchStats(statsURL: URL? = nil) async throws {
        let url = statsURL ?? Self.caskStats90
        dbg("loading cask stats:", url.absoluteString)
        let data = try await URLRequest(url: url).fetch()

        dbg("loaded cask stats", data.count.localizedByteCount(), "from url:", url)
        try self.stats = CaskStats(json: data)
    }

    func scanInstalledCasks() throws {
        // manually scan the installed files in /opt/homebrew/Caskroom/*/* to get the names and versions of the installed apps. E.g.,
        // /opt/homebrew/Caskroom/bon-mot/0.2.25/Bon Mot.app
        // /opt/homebrew/Caskroom/cloud-cuckoo-prerelease/0.8.150/Cloud Cuckoo.app
        // /opt/homebrew/Caskroom/discord/0.0.264/Discord.app
        // /opt/homebrew/Caskroom/figma/104.1.0/Figma.app
        // /opt/homebrew/Caskroom/firefox/94.0.1/Firefox.app

        let fm = FileManager.default

        // E.g.: ["firefox": ["94.0.1", "95.0.2"]]
        // ["telegram": Set(["8.4.1,225774"]), "app-fair": Set(["0.7.31"]), "visual-studio-code": Set(["1.62.2"]), "discord": Set(["0.0.264"]), "sita-sings-the-blues": Set(["0.0.24"]), "tune-out": Set(["0.8.349"]), "app-fair-prerelease": Set(["0.6.216"]), "slack": Set(["4.22.0"]), "transmission": Set(["3.00"]), "bon-mot-prerelease": Set(["1.1.16"]), "firefox": Set(["94.0.1", "95.0.2"]), "tune-out-prerelease": Set(["0.8.352"]), "minecraft": Set(["973,1"]), "microsoft-auto-update": Set(["4.40.21101001"]), "bon-mot": Set(["0.2.25"]), "vlc": Set(["3.0.16"]), "figma": Set(["107.1.0"]), "microsoft-edge": Set(["95.0.1020.44"]), "next-edit-prerelease": Set(["0.1.10"]), "cloud-cuckoo-prerelease": Set(["0.8.150"]), "zoom": Set(["5.8.3.2240"])]

        var tokenVersions: [CaskItem.ID: Set<String>] = [:]

        let dir = Self.localCaskroom
        if fm.isDirectory(url: dir) == true {
            for caskFolder in try dir.fileChildren(deep: false, skipHidden: true) {
                let dirName = caskFolder.lastPathComponent // the name of the file is the token

                // get the list of child versions. E.g.:
                // /opt/homebrew/Caskroom/firefox/.metadata/
                // /opt/homebrew/Caskroom/firefox/94.0.1/
                // /opt/homebrew/Caskroom/firefox/95.0.2/

                let subfiles = try caskFolder.fileChildren(deep: false, skipHidden: false)
                    .filter { fm.isDirectory(url: $0) == true }
                var names = Set(subfiles.map(\.lastPathComponent)) // e.g.: .metadata, 94.0.1, 95.0.2
                if names.remove(".metadata") != nil { // only handle folders with a metadata dir
                    // TODO: how to handle non-homebrew (e.g., appfair/app) casks? All the taps seem to go into /opt/homebrew/Caskroom/, so there doesn't seem to be a way to distinguish between cask sources?
                    let token = "homebrew/cask/" + dirName
                    tokenVersions[token] = names
                }
            }
        }

        dbg("scanned installed casks:", tokenVersions)
        self.installedCasks = tokenVersions
    }

    func run(command: String, toolName: String, askPassAppInfo: AppCatalogItem? = nil) throws -> String {
        // without SUDO_ASKPASS, priviedged operations can fail with: sudo: a terminal is required to read the password; either use the -S option to read from standard input or configure an askpass helper
        // sudo: a password is required
        // Error: Failure while executing; `/usr/bin/sudo -E -- /bin/rm -f -- /Library/LaunchDaemons/com.microsoft.autoupdate.helper.plist` exited with 1. Here's the output:
        // sudo: a terminal is required to read the password; either use the -S option to read from standard input or configure an askpass helper

        // from https://github.com/Homebrew/homebrew-cask/issues/77258#issuecomment-588552316

        var cmd = command
        var scpt: URL? = nil

        if let askPassAppName = askPassAppInfo?.name {
            let title = "Administrator Password Required (Homebrew)"
            let prompt = """
            The Homebrew \(toolName) for the “\(askPassAppName)” package needs an administrator password to complete the requested operation:

              \(command)

            Enter the password only if you trust this application to perform system-level installation operations.

            Alternatively, you can manually run the command in a Terminal.app shell.
            """

            let askPassScript = """
#!/usr/bin/osascript
return text returned of (display dialog "\(prompt)" with title "\(title)" default answer "" buttons {"Cancel", "OK"} default button "OK" with hidden answer)
"""
            let scriptFile = URL.tmpdir
                .appendingPathComponent("askpass-" + cmd.utf8Data.sha256().hex())
                .appendingPathExtension("scpt")
            scpt = scriptFile
            try askPassScript.write(to: scriptFile, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: NSNumber(value: 0o777)], ofItemAtPath: scriptFile.path) // set the executable bit
            cmd = "SUDO_ASKPASS=" + scriptFile.path + " " + cmd
        }

        defer {
            // clean up any askpass script we may have generated
            if let scpt = scpt, FileManager.default.isWritableFile(atPath: scpt.path) {
                //dbg("cleaning up:", scpt.path)
                try? FileManager.default.removeItem(at: scpt)
            }
        }

        dbg("performing command:", cmd)
        do {
            guard let result = try NSAppleScript.fork(command: cmd) else {
                throw AppError("No output from brew command")
            }

            dbg("command output:", result)

            return result
        } catch {
            dbg("error performing command:", cmd, error)
            throw error
        }
    }

    /// Processes the installed apps (too slow)
    @available(*, deprecated, message: "")
    func refreshInstalledApps() throws {
        dbg("loading installed casks")
        // outputs the installed apps list

        // annoyingly, this will return both the `formulae` and `casks` properties, even when we request it to only show casks; we ignore the property, but it can make the command take a long time to execute when there are a lot of formulae installed
        let cmd = Self.localBrewCommand.path + " info --quiet --installed --json=v2 --casks"
        let json = try run(command: cmd, toolName: .init("refresher"))

        struct BrewInstallOutput : Decodable {
            // var formulae: [Formulae] // unused but seems to always be included
            var casks: [CaskItem]
        }

        let _ = try BrewInstallOutput(json: json.utf8Data)
        // self.installed = output.casks
    }

    /// Installs the given `AppCatalogItem` using the `brew` command. The release must be a valid Homebrew release.
    ///
    /// - Parameters:
    ///   - item: the catalog item to install
    ///   - parentProgress: optional progress for reporting download progress
    ///   - preCache: use the in-process downloader (which provides progress reporting and cancellation) rather than brew's downloader (which uses a `curl` command). This works by figuring out the cache file to which homebrew would have downloaded the file and placting it there. SHA-256 checksums will be validated both by the in-process downloader and then again by the brew command.
    ///   - update: whether the action should be an update or an initial install
    ///   - quarantine: whether the installation process should quarantine the installed app(s), which will trigger a Gatekeeper check and user confirmation dialog when the app is first launched.
    ///   - force: whether we should force install the package, which will overwrite any other version that is currently installed regardless of its source.
    ///   - verbose: whether to verbosely report progress
    func install(item: AppCatalogItem, progress parentProgress: Progress?, preCache: Bool? = nil, update: Bool = true, quarantine: Bool? = nil, force: Bool? = nil, verbose: Bool = true) async throws {
        dbg(item.id)

        let quarantine = quarantine ?? self.quarantineCasks
        let force = force ?? self.forceInstallCasks
        let preCache = preCache ?? self.preCacheCasks

        /**
         When we download maually, we fetch the artifact with a cancellable progress and validate the SHA256 hash
         then we store it in the cache that homebrew checks for install artifacts:

         HOMEBREW_CACHE/"downloads/#{url_sha256}--#{resolved_basename}"

         If all goes well, the cached download will be used by homebrew like so:

         ```
         2022-01-07 01:04:17.410937-0500 App Fair[95350:5086973] CaskManager:221 install: moved: ~/Library/Caches/46E58C89-3E59-4EEC-B0A5-8DA962DFFA17/iTerm2-3_4_15.zip to: ~/Library/Caches/Homebrew/a8b31e8025c88d4e76323278370a2ae1a6a4b274a53955ef5fe76b55d5a8a8fe--iTerm2-3_4_15.zip
         2022-01-07 01:04:19.556840-0500 App Fair[95350:5086973] AppManager:718 fork: successfully executed script: /opt/homebrew/bin/brew reinstall --force --verbose --quarantine --casks homebrew/cask/iterm2
         2022-01-07 01:04:19.556906-0500 App Fair[95350:5086973] CaskManager:238 install: result: ==> Downloading https://iterm2.com/downloads/stable/iTerm2-3_4_15.zip
         Already downloaded: ~/Library/Caches/Homebrew/downloads/a8b31e8025c88d4e76323278370a2ae1a6a4b274a53955ef5fe76b55d5a8a8fe--iTerm2-3_4_15.zip
         ==> Verifying checksum for cask 'iterm2'
         ==> Installing Cask iterm2
         ==> Moving App 'iTerm.app' to '/Applications/iTerm.app'
         🍺  iterm2 was successfully installed!
         ```
         */

        // default config is to use: HOMEBREW_CACHE=$HOME/Library/Caches/Homebrew
        // TODO: should be have our own separate caches folder? That would allow us to avoid interfering with simultaneous non-App-Fair `brew` commands, but OTOH it would mean that the two behaviors of the tool would not be kept in sync with regards to caching
        let cachePaths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = cachePaths
            .map {
                URL(fileURLWithPath: "Homebrew/downloads", relativeTo: $0)
            }
            .first {
                FileManager.default.isDirectory(url: $0) == true
            }

        if preCache == true, let cacheDir = cacheDir {
            try Task.checkCancellation()
            // iterate through all the user cache directories (I've never seen more than one, but maybe it's possible)
            dbg("checking cache:", cacheDir.path)

            /// `HOMEBREW_CACHE/"downloads/#{url_sha256}--#{resolved_basename}"`
            let targetURL = URL(fileURLWithPath: item.cacheBasePath, relativeTo: cacheDir)

            // TODO: should we try to replicate Homebrew's curl command? It looks something like:
            // /opt/homebrew/Library/Homebrew/shims/shared/curl --disable --cookie /dev/null --globoff --show-error --user-agent 'Homebrew/3.3.9 (Macintosh; arm64 Mac OS X 12.1) curl/7.77.0' --header 'Accept-Language: en' --fail --silent --retry 3 --location --remote-time --output ~/Library/Caches/Homebrew/downloads/'2eea097118f44268d2fe62d69e2a7fb1d8d4d7f29c2da0ec262061199b600525--Wireshark 3.6.1 Arm 64.dmg.incomplete' 'https://2.na.dl.wireshark.org/osx/Wireshark 3.6.1 Arm 64.dmg'

            let headers: [String: String] = [
                :
                //"User-Agent" : "Homebrew/3.3.9 (Macintosh; arm64 Mac OS X 12.1) curl/7.77.0",
            ]

            let downloadURL = item.downloadURL
            dbg("downloading:", downloadURL.absoluteString, "to cache target:", targetURL.path)

            //let size = try await URLSession.shared.fetchExpectedContentLength(url: downloadURL)
            //dbg("fetchExpectedContentLength:", size)

            let (downloadedArtifact, _) = try await downloadArtifact(url: downloadURL, headers: headers, progress: parentProgress)

            // dbg("moving:", downloadedArtifact.path, "to:", targetURL.path)
            // overwrite any previous cached version
            let _ = try? FileManager.default.trash(url: targetURL)
            try FileManager.default.moveItem(at: downloadedArtifact, to: targetURL)
            dbg("moved:", downloadedArtifact.path, "to:", targetURL.path)
            try Task.checkCancellation()
        }

        /**
         Installers and updaters may sometimes require a password, but we don't want to run every brew command as an administrator (via AppleScript's `with administrator privileges`), since most installations should not require root (see: https://docs.brew.sh/FAQ#why-does-homebrew-say-sudo-is-bad)

         ```
         2022-01-07 10:22:31.254389-0500 App Fair[28885:5516809] CaskManager:326 install: result: ==> Downloading https://devimages-cdn.apple.com/design/resources/download/SF-Symbols-3.2.dmg
         Already downloaded: ~/Library/Caches/Homebrew/downloads/6a782fb8dbad8adc8ce3d9328e4f15d0881b35e387792777f9add877c4d50946--SF-Symbols-3.2.dmg
         ==> Verifying checksum for cask 'sf-symbols'
         ==> Installing Cask sf-symbols
         ==> Running installer for sf-symbols; your password may be necessary.
         Package installers may write to any location; options such as `--appdir` are ignored.
         installer: Package name is SF Symbols
         installer: Installing at base path /
         installer:PHASE:Preparing for installation…
         installer:PHASE:Preparing the disk…
         installer:PHASE:Preparing SF Symbols…
         installer:PHASE:Waiting for other installations to complete…
         installer:PHASE:Configuring the installation…
         installer:STATUS:
         installer:%12.114101
         installer:PHASE:Writing files…
         installer:%30.627893
         installer:PHASE:Writing files…
         installer:%43.445133
         installer:PHASE:Writing files…
         installer:%79.244900
         installer:PHASE:Registering updated components…
         installer:PHASE:Validating packages…
         installer:%97.750000
         installer:STATUS:Running installer actions…
         installer:STATUS:
         installer:PHASE:Finishing the Installation…
         installer:STATUS:
         installer:%100.000000
         installer:PHASE:The software was successfully installed.
         installer: The install was successful.
         🍺  sf-symbols was successfully installed!
         ```
         */
        var cmd = Self.localBrewCommand.path
        let op = update ? "upgrade" : "reinstall"
        cmd += " " + op
        if force { cmd += " --force" }
        if verbose { cmd += " --verbose" }
        if quarantine {
            cmd += " --quarantine"
        } else {
            cmd += " --no-quarantine"
        }
        cmd += " --casks " + item.id.rawValue
        let result = try run(command: cmd, toolName: update ? .init("updater") : .init("installer"), askPassAppInfo: item)
        dbg("result:", result)
    }

    func delete(item: AppCatalogItem, update: Bool = true, zap: Bool = false, force: Bool = true, verbose: Bool = true) async throws {
        dbg(item.id)
        var cmd = Self.localBrewCommand.path
        let op = "remove"
        cmd += " " + op
        if force { cmd += " --force" }
        if verbose { cmd += " --verbose" }
        if zap { cmd += " --zap" }
        cmd += " --casks " + item.id.rawValue
        let result = try run(command: cmd, toolName: .init("uninstaller"), askPassAppInfo: item)
        dbg("result:", result)
    }

    func icon(for item: AppCatalogItem) -> Image? {
        if let path = try? self.installPath(for: item) {
            // note: “The returned image has an initial size of 32 pixels by 32 pixels.”
            let icon = NSWorkspace.shared.icon(forFile: path.path)
            return Image(uxImage: icon)
        }
        return nil
    }

    func installPath(for item: AppCatalogItem) throws -> URL? {
        let token = item.bundleIdentifier.caskToken ?? ""
        let caskDir = URL(fileURLWithPath: token, relativeTo: Self.localCaskroom)
        let versionDir = URL(fileURLWithPath: item.version ?? "", relativeTo: caskDir)
        if FileManager.default.isDirectory(url: versionDir) != true {
            dbg("not a folder:", versionDir)
            return nil
        }

        let children = try versionDir.fileChildren(deep: false, skipHidden: true)
        for appURL in children {
            dbg("checking install child:", appURL.path)
            if appURL.pathExtension == "app"
                && FileManager.default.isExecutableFile(atPath: appURL.path) {
                // try to resolve the symbolic link (e.g., /opt/homebrew/Caskroom/discord/0.0.264/Discord.app -> /Applications/Discord.app so revealing the app will show it in the destination context
                let linkPath = try? FileManager.default.destinationOfSymbolicLink(atPath: appURL.path)
                dbg("executable:", appURL.path, linkPath)

                if let linkPath = linkPath {
                    return URL(fileURLWithPath: linkPath)
                } else {
                    return appURL
                }
            }
        }

        dbg("no app found in:", versionDir.path, "children:", children.map(\.lastPathComponent))
        return nil
    }

    func reveal(item: AppCatalogItem) async throws {
        let installPath = try self.installPath(for: item)
        dbg(item.id, installPath?.path)
        if let installPath = installPath, FileManager.default.isExecutableFile(atPath: installPath.path) {
            dbg("revealing:", installPath.path)
            NSWorkspace.shared.activateFileViewerSelecting([installPath])
        } else {
            throw AppError("Could not find install path for “\(item.name)”")
        }
    }

    func launch(item: AppCatalogItem) async throws {
        let installPath = try self.installPath(for: item)
        dbg(item.id, installPath?.path)
        if let installPath = installPath, FileManager.default.isExecutableFile(atPath: installPath.path) {
            dbg("launching:", installPath.path)

            let cfg = NSWorkspace.OpenConfiguration()
            cfg.activates = true

            try await NSWorkspace.shared.openApplication(at: installPath, configuration: cfg)
        } else {
            // only packages that contain dmg/zips of .app files are linked to the /Applications/Name.app; applications installed using package installers don't reference their target app installation, except possibly in the delete stanza of the my-app.rb file. E.g.:
            // pkg "My App.pkg"
            // uninstall pkgutil: "app.MyApp.plist",
            //           delete:  "/Applications/My App.app"
            //
            // how should we try to identify the app to launch? we don't want to have to try to parse the

            throw AppError("Could not find install path for “\(item.name)”")
        }

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
    /// Re-builds the AppInfo collection.
    private func updateAppInfo() {
        let analyticsMap = stats?.formulae ?? [:]

        // dbg("casks:", caskMap.keys.sorted())

        var infos: [AppInfo] = []

        //dbg("checking installed casks:", installedCasks.keys.sorted())
        //dbg("checking all casks:", casks.map(\.id).sorted())

        for cask in self.casks {
            guard let downloadURL = cask.url.flatMap(URL.init(string:)) else {
                continue
            }
            let id = cask.id
            let installed = installedCasks[id]?.first
            // TODO: extract installed Plist and check bundle identifier?

            // analytics are keyed on the un-expanded name
            let downloads = analyticsMap[cask.full_token]?.first?.installCount

            let name = cask.name.first ?? id

            //if let _ = installed {
            // dbg("found installed cask:", id, name, cask.version)
            //}

            // dbg("downloads for:", name, downloads)

            let homepage = cask.homepage.flatMap(URL.init(string:))
            guard let homepage = homepage else {
                dbg("skipping cask with no home page:", cask.homepage)
                continue
            }

            // without parsing the homepage for something like `<link href="/static/img/favicon.png" rel="shortcut icon" type="image/x-icon">`, we can't know that the real favicon is, so go old-school and get the "/favicon.ico" resource (which seems to be successful for about 2/3rds of the casks)
            let iconURL = URL(string: "/favicon.ico", relativeTo: homepage)

            // TODO: for installed apps, we could try to use the system icon for the app via `NSWorkspace.shared.icon(forFile: appPath)`, but the icon is an image rather than a file


            let versionDate: Date? = nil // how to obtain this? we could look at the mod date on, e.g., /opt/homebrew/Library/Taps/homebrew/homebrew-cask/Casks/signal.rb, but they seem to only be synced with the last update

            let categories: [String]? = nil // sadly, casks are un-categorized

            let item = AppCatalogItem(name: name, bundleIdentifier: CaskIdentifier(id), subtitle: cask.desc ?? "", developerName: homepage.absoluteString, localizedDescription: cask.desc ?? "", size: 0, version: cask.version, versionDate: versionDate, downloadURL: downloadURL, iconURL: iconURL, screenshotURLs: [], versionDescription: nil, tintColor: nil, beta: false, sourceIdentifier: nil, categories: categories, downloadCount: downloads, starCount: nil, watcherCount: nil, issueCount: nil, sourceSize: nil, coreSize: nil, sha256: cask.sha256, permissions: nil, metadataURL: nil, readmeURL: nil)

            var plist: Plist? = nil
            if let installed = installed {
                plist = Plist(rawValue: [
                    InfoPlistKey.CFBundleIdentifier.rawValue: id, // not really a bundle ID!
                    InfoPlistKey.CFBundleShortVersionString.rawValue: installed,
                ])
            }
            let info = AppInfo(release: item, installedPlist: plist)
            infos.append(info)
        }

        
        let sortedInfos = infos.sorted(using: self.sortOrder)
        //dbg("sorted:", infos.count, "first:", sortedInfos.first?.id.rawValue, "last:", sortedInfos.last?.id.rawValue)

        // avoid triggering unnecessary changes
        if self.appInfos != sortedInfos {
            withAnimation {
                self.appInfos = sortedInfos
            }
        }

        //        if self.sortOrder != sortOrder {
        //            self.sortOrder = sortOrder
        //        }
    }

    func arrangedItems(sidebarSelection: SidebarSelection?, sortOrder: [KeyPathComparator<AppInfo>], searchText: String) -> [AppInfo] {
        let infos = appInfos
            .filter({ matchesSelection(item: $0, sidebarSelection: sidebarSelection) })
            .filter({ matchesSearch(item: $0, searchText: searchText) })

        if sidebarSelection?.item.isLocalFilter == true {
            // installed and updated apps are sorted by name
            return infos.sorted(using: [KeyPathComparator(\AppInfo.release.name, order: .forward)])
        } else {
            return infos
        }
        //.sorted(using: sortOrder + [KeyPathComparator(\AppInfo.release.downloadCount, order: .reverse)]) // sorting each time is very slow; we should instead update a cache of the sorted changes
    }

    func matchesSearch(item: AppInfo, searchText: String) -> Bool {
        let txt = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return txt.count < minimumSearchLength
        || item.release.name.localizedCaseInsensitiveContains(txt) == true
        || item.release.developerName.localizedCaseInsensitiveContains(txt) == true
        || item.release.subtitle?.localizedCaseInsensitiveContains(txt) == true
        || item.release.localizedDescription.localizedCaseInsensitiveContains(txt) == true
    }

    func matchesSelection(item: AppInfo, sidebarSelection: SidebarSelection?) -> Bool {
        switch sidebarSelection?.item {
        case .installed:
            return item.installedVersionString != nil
        case .updated:
            if let releaseVersion = item.release.version,
               let installedVersions = installedCasks[item.release.id.rawValue] {
                // dbg(item.release.id, "releaseVersion:", releaseVersion, "installedVersions:", installedVersions)
                return installedVersions.contains(releaseVersion) == false
            } else {
                return false
            }
        default:
            return true
        }
    }

    func versionNotInstalled(cask: CaskItem) -> Bool {
        if let installedVersions = installedCasks[cask.id] {
            return !installedVersions.contains(cask.version)
        } else {
            return false
        }
    }

    func updateCount() -> Int {
        return casks.filter({
            self.versionNotInstalled(cask: $0)
        }).count
    }

    func badgeCount(for item: AppManager.SidebarItem) -> Text? {
        switch item {
        case .popular:
            return nil
        case .updated:
            return Text(updateCount(), format: .number)
        case .installed:
            return Text(installedCasks.count, format: .number)
        case .recent:
            return nil
        case .category(_):
            return nil
        }
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

extension CaskItem : Identifiable {

    /// The ID of a `CaskItem` is the `tapToken`
    var id: String { tapToken }

    /// Returns the fully-qualified token. E.g., `homebrew/cask/iterm2`
    var tapToken: String {
        if full_token.contains("/") {
            return full_token
        } else {
            return (tap ?? "") + "/" + full_token
        }
    }
}

#endif
