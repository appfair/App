import FairApp
import Foundation
import TabularData

/// The minimum number of characters before we will perform a search; helps improve performance for synchronous searches
let minimumSearchLength = 1

/// These functions are placed in an extension so they do not become subject to the `MainActor` restrictions.
private extension AppInventory where Self : HomebrewInventory {

    /// Installation is check simply by seeing if the brew install root exists.
    /// This will be used as the seed for the `enableHomebrew` app preference so we default to having it enabled if homebrew is seen as being installed
    static func homebrewCommandExists(at brewInstallRoot: URL) -> Bool {
        let cmd = brewCommand(at: brewInstallRoot).path
        let installed = FileManager.default.isExecutableFile(atPath: cmd)
        //dbg("installed:", cmd, installed)
        return installed
    }

    static func brewCommand(at brewInstallRoot: URL) -> URL {
        URL(fileURLWithPath: "bin/brew", relativeTo: brewInstallRoot)
    }

    /// The default install prefix for homebrew: “This script installs Homebrew to its preferred prefix (/usr/local for macOS Intel, /opt/homebrew for Apple Silicon and /home/linuxbrew/.linuxbrew for Linux) so that you don’t need sudo when you brew install. It is a careful script; it can be run even if you have stuff installed in the preferred prefix already. It tells you exactly what it will do before it does it too. You have to confirm everything it will do before it starts.”
    ///
    /// Note that on Intel, `/usr/local/bin/brew -> /usr/local/Homebrew/bin/brew`, but we shouldn't use `/usr/local/Homebrew/` as the brew root since `/usr/local/Caskroom` exists but `/usr/local/Homebrew/Caskroom` does not.
    static var globalBrewPath: URL {
        URL(fileURLWithPath: ProcessInfo.isArmMac ? "/opt/homebrew" : "/usr/local")
    }

}

/// A manager for [Homebrew casks](https://formulae.brew.sh/docs/api/)
@available(macOS 12.0, iOS 15.0, *)
@MainActor public final class HomebrewInventory: ObservableObject, AppInventory {

    /// Whether to enable Homebrew Cask installation
    @AppStorage("enableHomebrew") var enableHomebrew = true {
        didSet {
            Task {
                // whenever the enableHomebrew setting is changed, perform a scan of the casks
                try await refreshAll()
            }
        }
    }

    /// The base endpoint for the cask API; this can be used to test different cask endpoints
    @AppStorage("caskAPIEndpoint") var caskAPIEndpoint = URL(string: "https://formulae.brew.sh/api/")!

    /// Whether to allow Homebrew Cask installation; overriding this from the default path is un-tested and should only be changed for debugging Homebrew behavior
    @AppStorage("brewInstallRoot") var brewInstallRoot = HomebrewInventory.localBrewFolder

    /// Whether to use the system-installed Homebrew
    @AppStorage("useSystemHomebrew") var useSystemHomebrew = false

    /// Whether the quarantine flag should be applied to newly-installed casks
    @AppStorage("quarantineCasks") var quarantineCasks = true

    /// Whether delete apps should be "zapped"
    @AppStorage("zapDeletedCasks") var zapDeletedCasks = false

    /// Whether to ignore casks that mark themselves as "autoupdates" from being shown in the "Updated" section
    @AppStorage("ignoreAutoUpdatingAppUpdates") var ignoreAutoUpdatingAppUpdates = true

    /// Whether to require a checksum before downloading; many brew casks don't publish a checksum, so disabled by default
    @AppStorage("requireCaskChecksum") var requireCaskChecksum = false

    /// Whether to force overwrite other installations
    @AppStorage("forceInstallCasks") var forceInstallCasks = false

    /// Whether to use the in-app downloader to pre-cache the download file (which allows progress monitoring and user cancellation)
    @AppStorage("manageCaskDownloads") var manageCaskDownloads = true

    /// Whether to permit the `brew` command to send activitiy analytics. This controls whether to set Homebrew's flag [HOMEBREW_NO_ANALYTICS](https://docs.brew.sh/Analytics#opting-out)
    @AppStorage("enableBrewAnalytics") var enableBrewAnalytics = false

    /// Allow brew to update itself when performing operations
    @AppStorage("enableBrewSelfUpdate") var enableBrewSelfUpdate = false

    /// The arranged list of app info itemsl this is synthesized from the `casks`, `stats`, and `appcasks` properties
    @Published private(set) var appInfos: [AppInfo] = []

    /// The current catalog of casks
    @Published private(set) var casks: [CaskItem] = [] { didSet { updateAppInfo() } }

    /// Map of installed apps from `[token: [versions]]`
    @Published private(set) var installedCasks: [CaskItem.ID: Set<String>] = [:] { didSet { updateAppInfo() } }

    /// Enhanced metadata about individual apps
    @Published private(set) var appcasks: FairAppCatalog? { didSet { updateAppInfo() } }

    @Published private var sortOrder: [KeyPathComparator<AppInfo>] = [
        // don't have any initial sort so we can sort by the ranking
        // KeyPathComparator(\AppInfo.release.downloadCount, order: .reverse)
    ] { didSet { updateAppInfo() } }

    /// Whether the are currently performing an update
    @Published var updateInProgress = 0

    /// The list of casks
    private var caskList: URL { URL(string: "cask.json", relativeTo: caskAPIEndpoint)! }
    private var formulaList: URL { URL(string: "formula.json", relativeTo: caskAPIEndpoint)! }

    private var caskSourceBase: URL { URL(string: "cask-source/", relativeTo: caskAPIEndpoint)! }
    private var caskMetadataBase: URL { URL(string: "cask/", relativeTo: caskAPIEndpoint)! }

    /// The local brew archive if it is embedded in the app
    private let brewArchiveURLLocal = Bundle.module.url(forResource: "appfair-homebrew", withExtension: "zip", subdirectory: "Bundle")

    private static let appfairBase = URL(string: "https://github.com/App-Fair/")

    /// The source of the brew command for [manual installation](https://docs.brew.sh/Installation#untar-anywhere)
    private let brewArchiveURLRemote = URL(string: "brew/zipball/HEAD", relativeTo: HomebrewInventory.appfairBase)! // fork of https://github.com/Homebrew/brew/zipball/HEAD, same as: https://github.com/Homebrew/brew/archive/refs/heads/master.zip

    /// The source to the cask ruby definition file
    func caskSource(name: String) -> URL? {
        URL(string: name, relativeTo: caskSourceBase)?.appendingPathExtension("rb")
    }

    func caskMetadata(name: String) -> URL? {
        URL(string: name, relativeTo: caskMetadataBase)?.appendingPathExtension("json")
    }

    private static func cacheFolder(named name: String) -> URL {
        URL(fileURLWithPath: name, isDirectory: true, relativeTo: try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
    }

    /// ~/Library/Caches/appfair-homebrew/
    static let localCacheFolder: URL = cacheFolder(named: "appfair-homebrew/")

    /// ~/Library/Caches/Homebrew/downlods/
    static let downloadCacheFolder: URL = cacheFolder(named: "Homebrew/downloads/")

    /// ~/Library/Caches/Homebrew/Cask/
    static let caskCacheFolder: URL = cacheFolder(named: "Homebrew/Cask/")

    /// ~/Library/Caches/appfair-homebrew/Homebrew/
    static let localBrewFolder: URL = {
        URL(fileURLWithPath: "Homebrew/", isDirectory: true, relativeTo: localCacheFolder)
    }()

    /// The path where cask metadata and links are stored
    var localCaskroom: URL {
        URL(fileURLWithPath: "Caskroom", relativeTo: brewInstallRoot)
    }

    /// Whether there is a global installation of Homebrew available
    @available(*, deprecated, message: "use local brew install instead")
    static var globalBrewInstalled: Bool {
        FileManager.default.isExecutableFile(atPath: brewCommand(at: globalBrewPath).path)
    }

    /// Whether the configured location is installed
    func isInstalled() -> Bool {
        FileManager.default.isExecutableFile(atPath: Self.brewCommand(at: self.brewInstallRoot).path)
    }

    /// The home installation path for homebrew.
    @available(*, deprecated, message: "only differs when brew is installed from the install script")
    var brewInstallHome: URL {
        ProcessInfo.isArmMac ? brewInstallRoot : brewInstallRoot.appendingPathComponent("Homebrew")
    }


    /// Either `/opt/homebrew/.git` (ARM) or `/usr/local/Homebrew/.git` (Intel)
    @available(*, deprecated, message: "only works when brew is installed with .git folder")
    var brewGitFolder: URL? {
        URL(fileURLWithPath: ".git", relativeTo: brewInstallHome)
    }

    /// Returns the currently installed version of Homebrew, simply by scanning the git tags folder and using the most recent element.
    ///
    /// For example, `3.1.7` will be returned for the latest tag: `"/opt/homebrew/./.git/refs/tags/3.1.7"`
    @available(*, deprecated, message: "only works when brew is installed with .git folder")
    func installedBrewVersion() throws -> (version: String, updated: Date)? {
        // from brew.sh:
        // HOMEBREW_VERSION="$("${HOMEBREW_GIT}" -C "${HOMEBREW_REPOSITORY}" describe --tags --dirty --abbrev=7 2>/dev/null)"

        // we just scan the git tags folder manually and use the latest one
        // e.g.: "/opt/homebrew/./.git/refs/tags/3.1.7"
        let tagsFolder = URL(fileURLWithPath: "refs/tags", relativeTo: brewGitFolder)
        let children = try tagsFolder.fileChildren(deep: false, skipHidden: true, keys: [.contentModificationDateKey])
        if let mostRecent = children.sorting(by: \.contentModificationDateKey).last {
            return (mostRecent.lastPathComponent, mostRecent.modificationDate ?? .distantPast)
        } else {
            // no child folder elements
            return nil
        }
    }

    static let `default`: HomebrewInventory = HomebrewInventory()

    private var fsobserver: FileSystemObserver? = nil

    internal init() {
        watchCaskroomFolder()
    }

    /// The path to the `homebrew` command
    var localBrewCommand: URL {
        URL(fileURLWithPath: "bin/brew", relativeTo: useSystemHomebrew ? Self.globalBrewPath : brewInstallRoot)
    }

    /// Fetch the available casks and stats, and integrate them with the locally-installed casks
    func refreshAll() async throws {
        if enableHomebrew == false {
            dbg("skipping cask refresh because not isEnabled")
            return
        }

        self.updateInProgress += 1
        defer { self.updateInProgress -= 1 }
        async let installedCasks = scanInstalledCasks()
        async let casks = fetchCasks()
        async let appcasks = fetchAppCasks()

        //(self.stats, self.appcasks, self.installedCasks, self.casks) = try await (stats, appcasks, installedCasks, casks)
        self.installedCasks = try await installedCasks
        self.appcasks = try await appcasks
        self.casks = try await casks
    }

    /// Fetches the cask list and populates it in the `casks` property
    func fetchCasks() async throws -> Array<CaskItem> {
        dbg("loading cask list")
        let url = self.caskList
        let data = try await URLRequest(url: url).fetch()
        dbg("loaded cask JSON", data.count.localizedByteCount(), "from url:", url)
        let casks = try Array<CaskItem>(json: data)
        dbg("loaded", casks.count, "casks")
        return casks
    }

    func fetchAppCasks() async throws -> FairAppCatalog {
        dbg("loading appcasks")
        let url = appfairCaskAppsURL
        let data = try await URLRequest(url: url).fetch()
        dbg("loaded cask JSON", data.count.localizedByteCount(), "from url:", url)
        let appcasks = try FairAppCatalog(json: data, dateDecodingStrategy: .iso8601)
        dbg("loaded appcasks:", appcasks.apps.count)
        return appcasks
    }

    func scanInstalledCasks() throws -> [CaskItem.ID : Set<String>] {
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

        let dir = self.localCaskroom
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
                    // TODO: how to handle non-homebrew (e.g., appfair/app) casks? All the taps seem to go into /opt/homebrew/Caskroom/, so there doesn't seem to be a way to distinguish between different cask sources?
                    let token = "homebrew/cask/" + dirName
                    tokenVersions[token] = names
                }
            }
        }

        dbg("scanned installed casks:", tokenVersions.keys.sorted()) // tokenVersions)
        return tokenVersions
    }

    /// Performs a homebrew installation action by launching a Terminal.app window and issuing a shell command.
    func manageInstallation(install: Bool, downloadInstallerScript: Bool = true) async throws {
        let cacheFolder = Self.localCacheFolder

        let cmdFile = URL(fileURLWithPath: "homebrew-" + (install ? "installer" : "updater"), relativeTo: cacheFolder).appendingPathExtension("sh")

        if install == true {
            let installScript = URL(string: "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh")!
            if downloadInstallerScript {
                // download the installer script directly and execute it; perhaps a little safer than forking `curl`
                let scriptData = try await URLRequest(url: installScript).fetch()
                try scriptData.write(to: cmdFile)
            } else {
                // otherwise use the complete download command, which uses `curl` to execute the script
                /// The recommended install command from https://brew.sh
                let cmd = "/bin/bash -c \"$(curl -fsSL \(installScript.absoluteString))\""
                try (cmd + "\n").write(to: cmdFile, atomically: true, encoding: .utf8)
            }
        } else { // update
            let cmd = self.localBrewCommand.path + " update"
            try (cmd + "\n").write(to: cmdFile, atomically: true, encoding: .utf8)
        }

        try FileManager.default.setAttributes([.posixPermissions: NSNumber(value: 0o777)], ofItemAtPath: cmdFile.path) // set the executable bit

        // (echo 'tell application "com.apple.Terminal"'; echo ' do script("echo hello")'; echo 'end tell') | osascript
        let scriptFile = URL(fileURLWithPath: "homebrew-script.scpt", relativeTo: cacheFolder)

        // we might like "with administrator privileges" for the initial homebrew install, but it doesn't seem to work with tell to the terminal, so we would need to 
        /// `do shell script \"\(command)\" with administrator privileges`

        // otherwise, the script will prompt for sudo password if needed

        let script = """
        tell application "Terminal"
            activate
            do script("\(cmdFile.path)")
        end tell
        """

        dbg("running script:", script)
        
        try script.write(to: scriptFile, atomically: false, encoding: .utf8)

        // defer { try? FileManager.default.removeItem(at: scriptFile) }

        dbg("wrote to:", scriptFile.path)
        let task = try NSUserAppleScriptTask(url: scriptFile)
        let desc: NSAppleEventDescriptor = try await task.execute(withAppleEvent: nil)
        dbg("executed:", desc)
    }

    func caskEnvironment() -> String {
        var cmd = ""

        //#if DEBUG // always leave on debugging output to help with error reporting
        cmd += "HOMEBREW_DEBUG=1 "
        //#endif

        // we always use the API for fetching casks to avoid having to check out the entire cask repo
        cmd += "HOMEBREW_INSTALL_FROM_API=1 "

        // don't lookup failure reasons on GitHub
        cmd += "HOMEBREW_NO_GITHUB_API=1 "

        // don't be cute
        cmd += "HOMEBREW_NO_EMOJI=1 "

        if self.requireCaskChecksum == true {
            // this probably only affects curl options for non-integrated downloading
            cmd += "HOMEBREW_NO_INSECURE_REDIRECT=1 "
        }

        if self.enableBrewAnalytics == false {
            // see: https://docs.brew.sh/Analytics#opting-out
            cmd += "HOMEBREW_NO_ANALYTICS=1 "
        }

        if self.enableBrewSelfUpdate == false {
            // see: https://docs.brew.sh/Manpage
            cmd += "HOMEBREW_NO_AUTO_UPDATE=1 "
        }


        return cmd
    }

    func run(command: String, toolName: String, askPassAppInfo: CaskItem? = nil) async throws -> String {

        // Installers and updaters may sometimes require a password, but we don't want to run every brew command as an administrator (via AppleScript's `with administrator privileges`), since most installations should not require root (see: https://docs.brew.sh/FAQ#why-does-homebrew-say-sudo-is-bad)

        // without SUDO_ASKPASS, priviedged operations can fail with: sudo: a terminal is required to read the password; either use the -S option to read from standard input or configure an askpass helper
        // sudo: a password is required
        // Error: Failure while executing; `/usr/bin/sudo -E -- /bin/rm -f -- /Library/LaunchDaemons/com.microsoft.autoupdate.helper.plist` exited with 1. Here's the output:
        // sudo: a terminal is required to read the password; either use the -S option to read from standard input or configure an askpass helper

        // from https://github.com/Homebrew/homebrew-cask/issues/77258#issuecomment-588552316
        var cmd = command
        var scpt: URL? = nil

        if let askPassAppInfo = askPassAppInfo {
            let appName = askPassAppInfo.name.first ?? askPassAppInfo.token

            let title = "Administrator Password Required (Homebrew)"
                .replacingOccurrences(of: "\"", with: "'")
            let prompt = """
            The Homebrew \(toolName) for the “\(appName)” package needs an administrator password to complete the requested operation:

              \(command)

            Enter the password only if you trust this application to perform system-level installation operations.

            Alternatively, you can manually run the above command in a Terminal.app shell.
            """
                .replacingOccurrences(of: "\"", with: "'")

            let askPassScript = """
#!/usr/bin/osascript
return text returned of (display dialog "\(prompt)" with title "\(title)" default answer "" buttons {"Cancel", "OK"} default button "OK" with hidden answer)
"""

            dbg("creating sudo script:", askPassScript)
            let scriptFile = URL.tmpdir
                .appendingPathComponent("askpass-" + cmd.utf8Data.sha256().hex())
                .appendingPathExtension("scpt")
            scpt = scriptFile
            try askPassScript.write(to: scriptFile, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: NSNumber(value: 0o777)], ofItemAtPath: scriptFile.path) // set the executable bit
            cmd = "SUDO_ASKPASS=" + scriptFile.path + " " + cmd
        }

        cmd = caskEnvironment() + cmd

        defer {
            // clean up any askpass script we may have generated
            if let scpt = scpt, FileManager.default.isWritableFile(atPath: scpt.path) {
                //dbg("cleaning up:", scpt.path)
                try? FileManager.default.removeItem(at: scpt)
            }
        }

        dbg("performing command:", cmd)
        do {
            guard let result = try await NSUserScriptTask.fork(command: cmd) else {
                throw AppError("No output from brew command")
            }
            dbg("command output:", result)
            return result
        } catch {
            dbg("error performing command:", cmd, error)
            throw error
        }
    }

    func downloadCaskInfo(_ downloadURL: URL, _ cask: CaskItem, _ candidateURL: URL, _ expectedHash: String?, progress: Progress?) async throws {
        dbg("downloading:", downloadURL.absoluteString)

        let cacheDir = Self.downloadCacheFolder
        dbg("checking cache:", cacheDir.path)
        try? FileManager.default.createDirectory(at: Self.caskCacheFolder, withIntermediateDirectories: true, attributes: nil)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true, attributes: nil) // do not create the folder – if we do so, homebrew won't seem to set up its own directory structure and we'll see errors like: `Download failed on Cask 'iterm2' with message: No such file or directory @ rb_file_s_symlink - (../downloads/a8b31e8025c88d4e76323278370a2ae1a6a4b274a53955ef5fe76b55d5a8a8fe--iTerm2-3_4_15.zip, ~/Library/Caches/Homebrew/Cask/iterm2--3.4.15.zip`

        /// `HOMEBREW_CACHE/"downloads/#{url_sha256}--#{resolved_basename}"`
        let targetURL = URL(fileURLWithPath: cask.cacheBasePath(for: candidateURL), relativeTo: cacheDir)

        //let size = try await URLSession.shared.fetchExpectedContentLength(url: downloadURL)
        //dbg("fetchExpectedContentLength:", size)

        async let (downloadedArtifact, downloadSha256) = downloadArtifact(url: downloadURL, headers: [:], progress: progress)
        let actualHash = try await downloadSha256.hex()

        dbg("comparing SHA-256 expected:", expectedHash, "with actual:", expectedHash)
        if let expectedHash = expectedHash, expectedHash != actualHash {
            throw AppError("Invalid SHA-256 Hash", failureReason: "The downloaded SHA-256 (\(expectedHash) hash did not match the expected hash (\(expectedHash)).")
        }

        // dbg("moving:", downloadedArtifact.path, "to:", targetURL.path)
        // overwrite any previous cached version
        let artifact = try await downloadedArtifact
        let _ = try? FileManager.default.trash(url: targetURL)
        try FileManager.default.moveItem(at: artifact, to: targetURL)
        dbg("moved:", artifact.path, "to:", targetURL.path)
        try Task.checkCancellation()
    }

    /// Installs the given `AppCatalogItem` using the `brew` command. The release must be a valid Homebrew release.
    ///
    /// - Parameters:
    ///   - item: the catalog item to install
    ///   - parentProgress: optional progress for reporting download progress
    ///   - manageDownloads: use the in-process downloader (which provides progress reporting and cancellation) rather than brew's downloader (which uses a `curl` command). This works by figuring out the cache file to which homebrew would have downloaded the file and placting it there. SHA-256 checksums will be validated both by the in-process downloader and then again by the brew command.
    ///   - update: whether the action should be an update or an initial install
    ///   - quarantine: whether the installation process should quarantine the installed app(s), which will trigger a Gatekeeper check and user confirmation dialog when the app is first launched.
    ///   - force: whether we should force install the package, which will overwrite any other version that is currently installed regardless of its source.
    ///   - verbose: whether to verbosely report progress
    func install(cask: CaskItem, progress parentProgress: Progress?, manageDownloads: Bool? = nil, update: Bool = true, quarantine: Bool? = nil, force: Bool? = nil, verbose: Bool = true) async throws {
        dbg(cask)

        // fetch the cask info so we can determine the actual URL to download (the catalog URL will not always contain the correct URL and checksum due to https://github.com/Homebrew/brew/issues/12786)
        guard var candidateURL = cask.url.flatMap(URL.init) else {
            return dbg("no URL for cask")
        }
        var sha256 = cask.checksum
        var caskArg = cask.token

        // make sure Homebrew is installed; if not, install it locally from the embedded appfair-homebrew.zip
        let _ = try await installHomebrew(retainCasks: true)

        // evaluate the cask to assess what the actual URL & checksum will be (working around https://github.com/Homebrew/brew/issues/12786)
        if let sourceURL = self.caskSource(name: cask.token) {
            do {
                try await fetchCaskInfo(sourceURL, cask, &candidateURL, &sha256, &caskArg)
            } catch {
                // this is non-fatal: we will just use the default URL
                dbg("error trying to fetch and parse cask info:", error)
            }
        }

        let quarantine = quarantine ?? self.quarantineCasks
        let force = force ?? self.forceInstallCasks
        let manageDownloads = manageDownloads ?? self.manageCaskDownloads

        let (downloadURL, expectedHash) = (candidateURL, sha256)

        if expectedHash == nil && self.requireCaskChecksum == true {
            throw AppError("Missing cryptographic checksum", failureReason: "The download has no SHA-256 checksum set and so its authenticity cannot be verified.")
        }

        // default config is to use: HOMEBREW_CACHE=$HOME/Library/Caches/Homebrew

        if manageDownloads == true {
            try Task.checkCancellation()
            try await downloadCaskInfo(downloadURL, cask, candidateURL, expectedHash, progress: parentProgress)
        }

        var cmd = (self.localBrewCommand.path as NSString).abbreviatingWithTildeInPath

        let op = update ? "upgrade" : "install" // could use "reinstall", but it doesn't seem to work with `HOMEBREW_INSTALL_FROM_API` when there is no local .git checkout
        cmd += " " + op
        if force { cmd += " --force" }
        if verbose { cmd += " --verbose" }
        if quarantine {
            cmd += " --quarantine"
        } else {
            cmd += " --no-quarantine"
        }

        if requireCaskChecksum != false {
            cmd += " --require-sha"
        }

        cmd += " --cask " + caskArg

        let result = try await run(command: cmd, toolName: update ? .init("updater") : .init("installer"), askPassAppInfo: cask)

        // count the install
        if let installCounter = URL(string: "appcasks/releases/download/cask-\(cask.token)/cask-install", relativeTo: Self.appfairBase) {
            dbg("counting install:", installCounter.absoluteString)
            let _ = try? await URLSession.shared.fetch(request: URLRequest(url: installCounter, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 600))
        }

        dbg("result of command:", cmd, ":", result)
    }

    /// Downloads the cash info for the given URL and parses it, extracting the `url` and `checksum` properties.
    fileprivate func fetchCaskInfo(_ sourceURL: URL, _ cask: CaskItem, _ candidateURL: inout URL, _ sha256: inout String?, _ caskArg: inout String) async throws {
        // must be downloaded exactly here or `brew --info --cask <path>` will fail
        let downloadFolder = URL(fileURLWithPath: "Library/Taps/homebrew/homebrew-cask/Casks/", isDirectory: true, relativeTo: brewInstallRoot)
        try FileManager.default.createDirectory(at: downloadFolder, withIntermediateDirectories: true, attributes: nil) // ensure it exists

        // the cask path is the same as down download name
        let caskPath = URL(fileURLWithPath: sourceURL.lastPathComponent, relativeTo: downloadFolder)

        dbg("downloading cask info from:", sourceURL.absoluteString, "to:", caskPath.path)
        try await URLSession.shared.data(from: sourceURL).0.write(to: caskPath)

        // don't delete the local cask, since we want to re-use it for install
        // defer { try? FileManager.default.removeItem(at: caskPath) }

        var cmd = localBrewCommand.path
        cmd += " info --json=v2 --cask "
        cmd += caskPath.path
        let result = try await run(command: cmd, toolName: .init("info"), askPassAppInfo: cask)
        dbg("brew info result:", result)

        struct BrewInstallOutput : Decodable {
            // var formulae: [Formulae] // unused but seems to always be included
            var casks: [CaskItem]
        }

        let installInfo = try BrewInstallOutput(json: result.utf8Data)
        if let installCask = installInfo.casks.first,
           let caskURLString = installCask.url,
           let caskURL = URL(string: caskURLString) {
            if candidateURL != caskURL {
                // we parsed a different URL, which suggests that the system varies from the default catalog (usually arm vs. intel, but possibly also language)
                dbg("downloading:", caskURL.absoluteString, "(\(installCask.checksum ?? "no checksum"))", "instead of:", candidateURL, "(\(sha256 ?? "no checksum"))")
                candidateURL = caskURL
                sha256 = installCask.checksum
                caskArg = caskPath.path
            }
        }
    }


    func delete(cask: CaskItem, update: Bool = true, verbose: Bool = true) async throws {
        dbg(cask.token)
        var cmd = localBrewCommand.path
        let op = "remove"
        cmd += " " + op
        if self.forceInstallCasks { cmd += " --force" }
        if self.zapDeletedCasks { cmd += " --zap" }
        if verbose { cmd += " --verbose" }
        cmd += " --cask " + cask.token
        let result = try await run(command: cmd, toolName: .init("uninstaller"), askPassAppInfo: cask)
        dbg("result:", result)
    }

    @ViewBuilder func icon(for item: AppCatalogItem, useInstalledIcon: Bool = false) -> some View {
        if useInstalledIcon, let path = try? self.installPath(for: item) {
            // note: “The returned image has an initial size of 32 pixels by 32 pixels.”
            let icon = NSWorkspace.shared.icon(forFile: path.path)
            Image(uxImage: icon).resizable()
        } else if let _ = item.iconURL {
            item.iconImage() // use the icon URL if it has been set (e.g., using appcasks metadata)
        } else if let baseURL = item.developerName.flatMap(URL.init(string:)) {
            // otherwise fallback to using the favicon for the home page
            FaviconImage(baseURL: baseURL, fallback: {
                EmptyView()
            })
        } else {
            FairSymbol.questionmark_square_dashed
        }
    }

    func installPath(for item: AppCatalogItem) throws -> URL? {
        let token = item.bundleIdentifier.caskToken ?? ""
        let caskDir = URL(fileURLWithPath: token, relativeTo: self.localCaskroom)
        let versionDir = URL(fileURLWithPath: item.version ?? "", relativeTo: caskDir)
        if FileManager.default.isDirectory(url: versionDir) == true {
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
        }

        // fall back to scanning for the app artifact and looking in the /Applications folder
        if let cask = casks.first(where: { $0.token == token }) {
            for appList in (cask.artifacts ?? []).compactMap({ $0.infer() as [String]? }) {
                for appName in appList {
                    dbg("checking app:", appName)
                    if appName.hasSuffix(".app") {
                        let appURL = URL(fileURLWithPath: appName, relativeTo: FairAppInventory.applicationsFolderURL)
                        dbg("checking app path:", appURL.path)
                        if FileManager.default.isExecutableFile(atPath: appURL.path) {
                            return appURL
                        }
                    }
                }
            }
        }
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

    func launch(item: AppCatalogItem, gatekeeperCheck: Bool) async throws {
        let installPath = try self.installPath(for: item)
        dbg(item.id, installPath?.path)
        if let installPath = installPath, FileManager.default.isExecutableFile(atPath: installPath.path) {
            if gatekeeperCheck == true {
                do {
                    try Process.spctlAssess(appURL: installPath)
                } catch {
                    dbg("gatekeeper check failed:", error)
                }
            }
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

    /// Un-installs the local copy of Homebrew (by simply deleting the local install root)
    func uninstallHomebrew() async throws {
        try FileManager.default.trash(url: self.brewInstallRoot)
    }

    /// Downloads and installs Homebrew from the source zip
    /// - Returns: `true` if we installed Homebrew, `false` if it was already installed
    @discardableResult func installHomebrew(force: Bool = false, fromLocalOnly: Bool = false, retainCasks: Bool) async throws -> Bool {
        if force || (FileManager.default.isDirectory(url: Self.localBrewFolder) != true) {
            let cacheFolder = Self.localCacheFolder
            try FileManager.default.createDirectory(at: cacheFolder, withIntermediateDirectories: true, attributes: [:])
            try await installBrew(to: Self.localBrewFolder, fromLocalOnly: fromLocalOnly, retainCasks: retainCasks)
            return true
        } else {
            return false
        }
    }

    /// The docs recommend to use “the default prefix. Some things may not build when installed elsewhere” and “Pick another prefix at your peril!”, but downloading to a local cache URL seems to work fine.
    /// - Parameters:
    ///   - brewHome: the home into which to install brew
    ///   - fromLocalOnly: whether to only permit using the local cache of the brew archive zip
    ///   - retainCasks: whether to retain existing casks when updating to a new brew version
    private func installBrew(to brewHome: URL, fromLocalOnly: Bool, retainCasks: Bool) async throws {
        let fm = FileManager.default

        let fromURL, downloadedArtifact: URL
        let removeArtifact: Bool
        if let localURL = self.brewArchiveURLLocal, FileManager.default.fileExists(atPath: localURL.path) {
            fromURL = localURL
            downloadedArtifact = localURL
            removeArtifact = false
        } else if fromLocalOnly {
            throw AppError("Could not install from local artifact")
        } else {
            fromURL = self.brewArchiveURLRemote
            let (downloaded, response) = try await URLSession.shared.download(request: URLRequest(url: fromURL), memoryBufferSize: 1024 * 64, consumer: nil, parentProgress: nil)
            dbg("received download response:", response)
            downloadedArtifact = downloaded
            removeArtifact = true
        }

        dbg("unpacked brew package from:", fromURL.absoluteString, downloadedArtifact.fileSize()?.localizedByteCount()) // "response:", response)

        if retainCasks == false && FileManager.default.isDirectory(url: brewHome) == true {
            try fm.removeItem(at: brewHome) // clear any previous installation
        }

        try fm.unzipItem(at: downloadedArtifact, to: brewHome, trimBasePath: true, overwrite: retainCasks == true)
        dbg("extracted brew package to:", brewHome)

        if removeArtifact {
            try fm.removeItem(at: downloadedArtifact) // don't remove the local artifact, since we may need it later
        }

        // no re-start the FS watcher for the new folders
        // we do this mutliple times because the install process creates the folder eagerly before the install starts, and so it will be subject to the amount of time the install takes
        watchCaskroomFolder(delays: [0, 1, 2, 5, 10, 30])
    }

    /// Returns whether Homebrew is installed in the expected local path
    func isHomebrewInstalled() -> Bool {
        Self.homebrewCommandExists(at: self.brewInstallRoot)
    }

    /// Setup a watch for the cache folder
    private func watchCaskroomFolder(delays: [Int] = [0]) {
        if !self.isHomebrewInstalled() {
            return dbg("homebrew not installed")
        }

        let caskroomFolder = self.localCaskroom

        try? FileManager.default.createDirectory(at: caskroomFolder, withIntermediateDirectories: true, attributes: nil)

        // directory must exist or `DispatchSource.makeFileSystemObjectSource` will crash
        if FileManager.default.isDirectory(url: caskroomFolder) != true {
            return dbg("not a folder:", caskroomFolder.path)
        }

        dbg("checking brew observer in:", caskroomFolder.path)

        // set up a file-system observer for the install folder, which will refresh the installed apps whenever any changes are made; this allows external processes like homebrew to update the installed app
        self.fsobserver = FileSystemObserver(URL: caskroomFolder, queue: .main) {
            dbg("changes detected in cask folder:", caskroomFolder.path)
            // we need a small delay here because brew seems to create the directory eagerly before it unpacks and moves the app, which means there is often a signifcant delay between when the change occurs and the app version is available there
            for delay in delays {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay)) {
                    do {
                        self.installedCasks = try self.scanInstalledCasks()
                    } catch {
                        dbg("error scanning for installed casks:", error)
                    }
                }
            }
        }
    }
}

private extension AppCatalogItem {
    var abbreviatedToken: String {
        let token = self.id.rawValue
        if let lastSlash = token.lastIndex(of: "/") {
            return token[lastSlash...].description
        } else {
            return token
        }
    }
}

extension HomebrewInventory {
    /// Re-builds the AppInfo collection.
    private func updateAppInfo() {
        // an index of [token: extraInfo]
        let appcaskInfo: [String: [AppCatalogItem]] = (appcasks?.apps ?? [])
            .grouping(by: \.abbreviatedToken)

        // the position of the cask in the ranks, which is used to control the initial sort order
        let caskRanks: [String : Int] = (appcasks?.apps ?? [])
            .enumerated()
            .grouping(by: \.element.abbreviatedToken)
            .compactMapValues(\.first?.offset)

        // dbg("casks:", caskMap.keys.sorted())
        var infos: [AppInfo] = []

        //dbg("checking installed casks:", installedCasks.keys.sorted())
        //dbg("checking all casks:", casks.map(\.id).sorted())

        for cask in self.casks {
            // skips casks that don't have any download URL
            guard let downloadURL = cask.url.flatMap(URL.init(string:)) else {
                continue
            }

            // the short cask token (e.g. "firefox")
            let caskTokenShort = cask.token

            // the long cask token (e.g. "homebrew/cask/firefox")
            let caskTokenFull = cask.id
            let caskid = CaskIdentifier(caskTokenFull)

            let caskInfo = appcaskInfo[caskTokenShort]

            let downloads = caskInfo?.first?.downloadCount
            let readmeURL = caskInfo?.first?.readmeURL

            // TODO: extract installed Plist and check bundle identifier?
            let installed = installedCasks[caskTokenShort]?.first
            //dbg("installed info for:", caskTokenShort, installed)

            //dbg("download count for:", caskid, downloads)
            guard let caskHomepage = cask.homepage.flatMap(URL.init(string:)) else {
                dbg("skipping cask with no home page:", cask.homepage)
                continue
            }

            // TODO: we should de-proritize the privileged domains so the publisher fork will always take precedence
            let appcask = caskInfo?.first { item in
                item.homepage?.host == "appfair.app"
                || item.homepage?.host == "www.appfair.app"
                || item.homepage?.host == caskHomepage.host
            }

            //dbg("appcaskInfo for:", caskid, appcask)

            let name = cask.name.first ?? caskTokenShort

            let versionDate: Date? = nil // how to obtain this? we could look at the mod date on, e.g., /opt/homebrew/Library/Taps/homebrew/homebrew-cask/Casks/signal.rb, but they seem to only be synced with the last update

            let item = AppCatalogItem(name: name, bundleIdentifier: caskid, subtitle: cask.desc ?? "", developerName: caskHomepage.absoluteString, localizedDescription: cask.desc ?? "", size: 0, version: cask.version, versionDate: versionDate, downloadURL: downloadURL, iconURL: appcask?.iconURL, screenshotURLs: appcask?.screenshotURLs, versionDescription: appcask?.versionDescription, tintColor: appcask?.tintColor, beta: false, sourceIdentifier: appcask?.sourceIdentifier, categories: appcask?.categories, downloadCount: downloads, impressionCount: appcask?.impressionCount, viewCount: appcask?.viewCount, starCount: nil, watcherCount: nil, issueCount: nil, sourceSize: nil, coreSize: nil, sha256: cask.checksum, permissions: nil, metadataURL: self.caskMetadata(name: cask.token), readmeURL: readmeURL, homepage: caskHomepage)

            var plist: Plist? = nil
            if let installed = installed {
                plist = Plist(rawValue: [
                    InfoPlistKey.CFBundleIdentifier.rawValue: caskTokenFull, // not really a bundle ID!
                    InfoPlistKey.CFBundleShortVersionString.rawValue: installed,
                ])
            }
            let info = AppInfo(release: item, cask: cask, installedPlist: plist)
            infos.append(info)
        }

        var sortedInfos = infos

        //dbg("caskRanks", caskRanks)

        // when unsorted, use the position in the appcask ranking for presentation raking
        if self.sortOrder.isEmpty {
            sortedInfos = sortedInfos.reversed().sorted(by: { info1, info2 in
                guard let id1 = info1.cask?.token else { return false }
                guard let id2 = info2.cask?.token else { return true }

                let rank1 = caskRanks[id1]
                let rank2 = caskRanks[id2]

                guard let rank1 = rank1 else {
                    return rank2 == nil
                }
                guard let rank2 = rank2 else {
                    return true
                }

                return rank1 < rank2
            })
        } else {
            sortedInfos = sortedInfos.sorted(using: self.sortOrder)
        }

        dbg("sorted:", infos.count, "first:", sortedInfos.first?.id.rawValue, "last:", sortedInfos.last?.id.rawValue)

        // avoid triggering unnecessary changes
        if self.appInfos != sortedInfos {
             //withAnimation { // this animation seems to cancel loading of thumbnail images the first time the screen is displayed if the image takes a long time to load (e.g., for large thumbnails)
                self.appInfos = sortedInfos
             //}
        }
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
        // searching for a specific cask is an exact match
        if searchText.hasPrefix("homebrew/cask/") {
            return item.cask?.tapToken == searchText
        }

        let txt = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return txt.count < minimumSearchLength
        || item.cask?.tapToken.localizedCaseInsensitiveContains(searchText) == true
        || item.release.name.localizedCaseInsensitiveContains(txt) == true
        || item.release.developerName?.localizedCaseInsensitiveContains(txt) == true
        || item.cask?.homepage?.localizedCaseInsensitiveContains(txt) == true
        || item.release.subtitle?.localizedCaseInsensitiveContains(txt) == true
        || item.release.localizedDescription?.localizedCaseInsensitiveContains(txt) == true
    }

    func matchesSelection(item: AppInfo, sidebarSelection: SidebarSelection?) -> Bool {
        switch sidebarSelection?.item {
        case .installed:
            return installedCasks[item.release.id.rawValue] != nil
        case .updated:
            return appUpdated(item)
        default:
            return true
        }
    }

    func appUpdated(_ item: AppInfo) -> Bool {
        if let releaseVersion = item.release.version,
           let installedVersions = installedCasks[item.release.id.rawValue] {
            if self.ignoreAutoUpdatingAppUpdates == true && item.cask?.auto_updates == true {
                return false // show showing apps that mark themselves as auto-updating
            }
            // dbg(item.release.id, "releaseVersion:", releaseVersion, "installedCasks:", installedCasks)
            return installedVersions.contains(releaseVersion) == false
        } else {
            return false
        }
    }

    func versionNotInstalled(cask: CaskItem) -> Bool {
        if let installedCasks = installedCasks[cask.id] {
            return !installedCasks.contains(cask.version)
        } else {
            return false
        }
    }

    func updateCount() -> Int {
        return appInfos
            .filter({ info in
                if let cask = info.cask {
                    return self.versionNotInstalled(cask: cask)
                } else {
                    return false
                }
            })
            .filter({ info in
                appUpdated(info)
            })
            .count
    }

    func badgeCount(for item: FairAppInventory.SidebarItem) -> Text? {
        switch item {
        case .top:
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

extension ProcessInfo {
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

    /// The SHA-256 hash of the artifact.
    private let sha256: String

    /// Returns the checksum unless it is the "no_check" constant or does not otherwise appear to be a checksum
    var checksum: String? {
        //let validCharacters = CharacterSet(charactersIn: "")
        sha256 == "no_check" || sha256.count != 64 ? nil : sha256
    }

    /// E.g.: `app has been officially discontinued upstream`
    let caveats: String?

    let auto_updates: Bool?

    // "artifacts":[["Signal.app"],{"trash":["~/Library/Application Support/Signal","~/Library/Preferences/org.whispersystems.signal-desktop.helper.plist","~/Library/Preferences/org.whispersystems.signal-desktop.plist","~/Library/Saved Application State/org.whispersystems.signal-desktop.savedState"],"signal":{}}]
    typealias ArtifactItem = XOr<Array<String>>.Or<ArtifactObject>

    let artifacts: Array<ArtifactItem>?

    struct ArtifactObject : Equatable, Decodable {
        //let trash: Array<String>?
        //let quit: String?
        //let signal: Array<SignalItem>?
    }

    /// E.g., `{"macos":{">=":["10.12"]}}`
    // let depends_on": {},

    /// E.g.: `"conflicts_with":{"cask":["homebrew/cask-versions/1password-beta"]}`
    // let conflicts_with: null
    
    /// E.g.: `"container":"{:type=>:zip}"`
    // let container": null,

    /// Possible model for https://github.com/Homebrew/brew/issues/12786
//    private let files: [FileItem]?
//    private struct FileItem : Equatable, Decodable {
//        /// E.g., "arm64" or "x86"
//        let arch: String?
//        let url: String?
//        let sha256: String?
//    }
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

    /// The URL that points to the Hub's spec for the token.
    /// 
    /// e.g.: homebrew/cask/iterm2 or appfair/app/bon-mot
    var tapURL: URL? {
        let parts = tapToken.split(separator: "/")
        if parts.count == 3 {
            let base = parts[0]
            let cask = parts[1]
            let token = parts[2]
            return URL(string: "https://github.com/\(base)/\(base)-\(cask)/blob/HEAD/Casks/\(token).rb")
        } else {
            return nil
        }
    }
}

extension CaskItem {
    /// The basename of the local cache file for this item's download URL
    fileprivate func cacheBasePath(for url: URL) -> String {
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
