import FairApp
import Dispatch
import Security
import Foundation

#if os(macOS)
let displayExtensions: Set<String>? = ["zip"]
let catalogURL: URL = appfairCatalogURLMacOS
#endif

#if os(iOS)
let displayExtensions: Set<String>? = ["ipa"]
let catalogURL: URL = appfairCatalogURLIOS
#endif

/// Whether to remember the response to a prompt or not;
enum PromptSuppression : Int, CaseIterable {
    /// The user has not specified whether to remember the response
    case unset
    /// The user specified that the the response should always the confirmation response
    case confirmation
    /// The user specified that the the response should always be the destructive response
    case destructive
}

extension ObservableObject {
    /// Issues a prompt with the given parameters, returning whether the user selected OK or Cancel
    @MainActor func prompt(_ style: NSAlert.Style = .informational, window sheetWindow: NSWindow? = nil, messageText: String, informativeText: String? = nil, accept: String = loc("OK"), refuse: String = loc("Cancel"), suppressionTitle: String? = nil, suppressionKey: Binding<PromptSuppression>? = nil) async -> Bool {

        let window = sheetWindow ?? NSApp.currentEvent?.window

        if let suppressionKey = suppressionKey {
            switch suppressionKey.wrappedValue {
            case .confirmation: return true
            case .destructive: return false
            case .unset: break // show prompt
            }
        }

        let alert = NSAlert()
        alert.alertStyle = style
        alert.messageText = messageText
        if let informativeText = informativeText {
            alert.informativeText = informativeText
        }
        alert.addButton(withTitle: accept)
        alert.addButton(withTitle: refuse)

        if let suppressionTitle = suppressionTitle {
            alert.suppressionButton?.title = suppressionTitle
        }
        alert.showsSuppressionButton = suppressionKey != nil

        let response: NSApplication.ModalResponse
        if let window = window {
            response = await alert.beginSheetModal(for: window)
        } else {
            response = alert.runModal()
        }

        // remember the response if we have prompted to do so
        if let suppressionKey = suppressionKey, alert.suppressionButton?.state == .on {
            switch response {
            case .alertFirstButtonReturn: suppressionKey.wrappedValue = .confirmation
            case .alertSecondButtonReturn: suppressionKey.wrappedValue = .destructive
            default: break
            }
        }

        return response == .alertFirstButtonReturn
    }
}

/// The manager for installing App Fair apps
@available(macOS 12.0, iOS 15.0, *)
@MainActor public final class FairAppInventory: ObservableObject, AppInventory {
    /// The list of currently installed apps of the appID to the Info.plist (or error)
    @Published var installedApps: [URL : Result<Plist, Error>] = [:]

    /// The current activities that are taking place
    @Published var operations: [BundleIdentifier: CatalogOperation] = [:]

    /// The current catalog of apps
    @Published var catalog: [AppCatalogItem] = []

    /// Whether the app is currently performing an update
    @Published var updateInProgress = 0

    @AppStorage("showPreReleases") var showPreReleases = showPreReleasesDefault
    static let showPreReleasesDefault = false

    @AppStorage("relaunchUpdatedApps") var relaunchUpdatedApps = relaunchUpdatedAppsDefault
    static let relaunchUpdatedAppsDefault = true

    @AppStorage("riskFilter") var riskFilter = riskFilterDefault
    static let riskFilterDefault = AppRisk.risky

    @AppStorage("autoUpdateCatalogApp") public var autoUpdateCatalogApp = autoUpdateCatalogAppDefault
    static let autoUpdateCatalogAppDefault = true

    /// Whether to automatically re-launch the catalog app when it has updated itself
    @AppStorage("relaunchUpdatedCatalogApp") var relaunchUpdatedCatalogApp = relaunchUpdatedCatalogAppDefault
    static let relaunchUpdatedCatalogAppDefault = PromptSuppression.unset

    @Published public var errors: [AppError] = []

    /// Resets all of the `@AppStorage` properties to their default values
    func resetAppStorage() {
        self.showPreReleases = Self.showPreReleasesDefault
        self.relaunchUpdatedApps = Self.relaunchUpdatedAppsDefault
        self.riskFilter = Self.riskFilterDefault
        self.autoUpdateCatalogApp = Self.autoUpdateCatalogAppDefault
        self.relaunchUpdatedCatalogApp = Self.relaunchUpdatedCatalogAppDefault
    }

    /// Register that an error occurred with the app manager
    func reportError(_ error: Error) {
        errors.append(error as? AppError ?? AppError(error))
    }

    static let `default`: FairAppInventory = FairAppInventory()

    private var fsobserver: FileSystemObserver? = nil

    internal init() {
        if FileManager.default.isDirectory(url: Self.installFolderURL) == false {
            Task {
                try? await Self.createInstallFolder()
            }
        }

        // set up a file-system observer for the install folder, which will refresh the installed apps whenever any changes are made; this allows external processes like homebrew to update the installed app
        if FileManager.default.isDirectory(url: Self.installFolderURL) == true {
            self.fsobserver = FileSystemObserver(URL: Self.installFolderURL, queue: .main) {
                dbg("changes detected in app folder:", Self.installFolderURL.path)
                Task {
                    await self.scanInstalledApps()
                }
            }
        }
    }

    func refreshAll() async throws {
        self.updateInProgress += 1
        defer { self.updateInProgress -= 1 }

        async let v0: () = scanInstalledApps()
        async let v1: () = fetchApps(cache: .reloadIgnoringLocalAndRemoteCacheData)
        let _ = await (v0, v1)
    }
}

/// An activity and progress
class CatalogOperation {
    let activity: CatalogActivity
    var progress: Progress

    init(activity: CatalogActivity, progress: Progress = Progress()) {
        self.activity = activity
        self.progress = progress
    }
}

enum CatalogActivity : CaseIterable, Equatable {
    case install
    case update
    case trash
    case reveal
    case launch
}


@available(macOS 12.0, iOS 15.0, *)
extension FairAppInventory {
    func fetchApps(cache: URLRequest.CachePolicy? = nil) async {
        do {
            dbg("loading catalog")
            let start = CFAbsoluteTimeGetCurrent()
            let catalog = try await FairHub.fetchCatalog(catalogURL: catalogURL, cache: cache)
            self.catalog = catalog.apps
            let end = CFAbsoluteTimeGetCurrent()
            dbg("fetched catalog:", catalog.apps.count, "in:", (end - start))
            if autoUpdateCatalogApp == true {
                try await updateCatalogApp()
            }
        } catch {
            Task { // otherwise warnings about accessing off of the main thread
                // errors here are not unexpected, since we can get a `cancelled` error if the view that initiated the `fetchApps` request
                dbg("received error:", error)
                // we tolerate a "cancelled" error because it can happen when a view that is causing a catalog load is changed and its request gets automaticallu cancelled
                if error.isURLCancelledError {
                } else {
                    self.reportError(error)
                }
            }
        }
    }

    /// The app info for the current app (which is the catalog browser app)
    var catalogAppInfo: AppInfo? {
        appInfoItems(includePrereleases: false).first(where: { info in
            info.release.bundleIdentifier.rawValue == Bundle.main.bundleIdentifier
        })
    }

    /// If the catalog app is updated,
    private func updateCatalogApp() async throws {
        // auto-update the App Fair app itself to the latest non-pre-release version
        guard let catalogApp = catalogAppInfo else {
            return dbg("could not locate current app in app list")
        }

        // only update the App Fair catalog manager app when it has been placed in the /Applications/ folder. This avoids issues around app translocation 
        if Bundle.main.executablePath?.hasPrefix(Self.applicationsFolderURL.path) != true {
            return dbg("skipping update to catalog app:", Bundle.main.executablePath, "since it is not installed in the applications folder:", Self.applicationsFolderURL.path)
        }

        dbg("updating:", Bundle.main.bundleURL.path, "from installed:", catalogApp.installedVersionString, "to:", catalogApp.releasedVersion?.versionString)

        // if the release version is greater than the installed version, download and install it automatically
        if (catalogApp.releasedVersion ?? .min) > (catalogApp.installedVersion ?? .max) {
            try await install(item: catalogApp.release, progress: nil, update: true)
        }
    }

    /// All the app-info items, sorted and filtered based on whether to include pre-releases.
    ///
    /// - Parameter includePrereleases: when `true`, versions marked `beta` will superceed any non-`beta` versions.
    /// - Returns: the list of apps, including all the installed apps, as well as matching pre-leases
    func appInfoItems(includePrereleases: Bool) -> [AppInfo] {
        let installedApps: [BundleIdentifier?: [Plist]] = Dictionary(grouping: self.installedApps.values.compactMap(\.successValue), by: { $0.CFBundleIdentifier.flatMap(BundleIdentifier.init(rawValue:)) })

        // multiple instances of the same bundleID can exist for "beta" set to `false` and `true`;
        // the visibility of these will be controlled by whether we want to display pre-releases
        let bundleAppInfoMap: [BundleIdentifier: [AppInfo]] = catalog
            .map { item in
                AppInfo(release: item, installedPlist: installedApps[item.bundleIdentifier]?.first)
            }
            .grouping(by: \.release.bundleIdentifier)

        // need to cull duplicates based on the `beta` flag so we only have a single item with the same CFBundleID
        let infos = bundleAppInfoMap.values.compactMap({ appInfos in
            appInfos
                .filter { item in
                    // "beta" apps are are included when the pre-release flag is set
                    includePrereleases == true || item.release.beta == false // || item.installedPlist != nil
                }
                .sorting(by: \.releasedVersion, ascending: false, noneFirst: true) // the latest release comes first
                .first // there can be only a single bundle identifier in the list for Identifiable
        })

        return infos.sorting(by: \.release.bundleIdentifier) // needs to return in constant order
    }

    /// The items arranged for the given category with the specifed sort order and search text
    func arrangedItems(sidebarSelection: SidebarSelection?, sortOrder: [KeyPathComparator<AppInfo>], searchText: String) -> [AppInfo] {
        self
            .appInfoItems(includePrereleases: showPreReleases || sidebarSelection?.item == .installed)
            .filter({ matchesExtension(item: $0) })
            .filter({ sidebarSelection?.item.isLocalFilter == true || matchesRiskFilter(item: $0) })
            .filter({ matchesSearch(item: $0, searchText: searchText) })
            .filter({ categoryFilter(sidebarSelection: sidebarSelection, item: $0) })
            .sorted(using: sortOrder + categorySortOrder(category: sidebarSelection?.item))
    }

    func categorySortOrder(category: SidebarItem?) -> [KeyPathComparator<AppInfo>] {
        switch category {
        case .none:
            return []
        case .top:
            return [KeyPathComparator(\AppInfo.release.downloadCount, order: .reverse)]
        case .recent:
            return [KeyPathComparator(\AppInfo.release.versionDate, order: .reverse)]
        case .updated:
            return [KeyPathComparator(\AppInfo.release.versionDate, order: .reverse)]
        case .installed:
            return [KeyPathComparator(\AppInfo.release.name, order: .forward)]
        case .category:
            return [KeyPathComparator(\AppInfo.release.starCount, order: .reverse), KeyPathComparator(\AppInfo.release.downloadCount, order: .reverse)]
        }
    }

    func categoryFilter(sidebarSelection: SidebarSelection?, item: AppInfo) -> Bool {
        sidebarSelection?.item.matches(item: item) != false
    }

    func matchesExtension(item: AppInfo) -> Bool {
        displayExtensions?.contains(item.release.downloadURL.pathExtension) != false
    }

    func matchesRiskFilter(item: AppInfo) -> Bool {
        item.release.riskLevel <= riskFilter
    }

    func matchesSearch(item: AppInfo, searchText: String) -> Bool {
        let txt = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return (txt.count < minimumSearchLength
                || item.release.bundleIdentifier.rawValue.localizedCaseInsensitiveContains(searchText) == true
                || item.release.name.localizedCaseInsensitiveContains(searchText) == true
                || item.release.subtitle?.localizedCaseInsensitiveContains(searchText) == true
                || item.release.localizedDescription?.localizedCaseInsensitiveContains(searchText) == true)
    }

    /// The main folder for apps
    static var applicationsFolderURL: URL {
        (try? FileManager.default.url(for: .applicationDirectory, in: .localDomainMask, appropriateFor: nil, create: true)) ?? URL(fileURLWithPath: "/Applications")
    }

    /// The folder where App Fair apps will be installed
    static var installFolderURL: URL {
        // we would like the install folder to be the same-named peer of the app's location, allowing it to run in `~/Downloads/` (which would place installed apps in `~/Downloads/App Fair`)
        // however, app translocation prevents it from knowing its location on first launch, and so we can't rely on being able to install as a peer without nagging the user to first move the app somewhere (thereby exhausting translocation)
        // Bundle.main.bundleURL.deletingPathExtension()
        URL(fileURLWithPath: Bundle.mainBundleName, relativeTo: applicationsFolderURL)
    }

    /// Launch the local installed copy of this app
    func launch(item: AppCatalogItem) async {
        do {
            dbg("launching:", item.name)
            guard let installPath = Self.installedPath(for: item) else {
                throw Errors.appNotInstalled(item)
            }

            dbg("launching:", installPath)

#if os(macOS)
            let cfg = NSWorkspace.OpenConfiguration()
            cfg.activates = true

            try await NSWorkspace.shared.openApplication(at: installPath, configuration: cfg)
#else
            throw Errors.launchAppNotSupported
#endif
        } catch {
            dbg("error performing launch for:", item, "error:", error)
            self.reportError(error)
        }
    }

    /// Returns the installed path for this app; this will always be
    /// `/Applications/Fair Ground/App Name.app`, except for the
    /// `Fair Ground.app` catalog app itself, which will be at:
    /// `/Applications/Fair Ground.app`.scanInstalledApps
    static func appInstallPath(for item: AppCatalogItem) -> URL {
        // e.g., "App Fair.app" matches "/Applications/App Fair"
        URL(fileURLWithPath: item.name + FairCLI.appSuffix, isDirectory: true, relativeTo: installFolderURL.lastPathComponent == item.name ? installFolderURL.deletingLastPathComponent() : installFolderURL)
    }

    /// The catalog app itself is the same as the name of the install path with the ".app" suffix
    static var catalogAppURL: URL {
        URL(fileURLWithPath: installFolderURL.lastPathComponent + FairCLI.appSuffix, relativeTo: installFolderURL.deletingLastPathComponent())
    }

    /// The bundle IDs for all the installed apps
    var installedBundleIDs: Set<String> {
        Set(installedApps.values.compactMap(\.successValue).compactMap(\.CFBundleIdentifier))
    }

    static func createInstallFolder() async throws {
        // always try to ensure the install folder is created (in case the user clobbers the app install folder while we are running)
        // FIXME: this will always fail, since the ownership & permissions of /Applications/ cannot be changed
        try await withPermission(installFolderURL.deletingLastPathComponent()) { _ in
            try FileManager.default.createDirectory(at: installFolderURL, withIntermediateDirectories: true, attributes: nil)
        }
    }

    /// Attempts to perform the given action and adds any errors to the error list if they fail.
    func trying(block: () async throws -> ()) async {
        do {
            try await block()
        } catch {
            reportError(error)
            //errors.append(error as? AppError ?? AppError(error))
        }
    }

    func scanInstalledApps() async {
        dbg()
        do {
            let start = CFAbsoluteTimeGetCurrent()
            try? await Self.createInstallFolder()
            var installPathContents = try FileManager.default.contentsOfDirectory(at: Self.installFolderURL, includingPropertiesForKeys: [], options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles, .producesRelativePathURLs]) // producesRelativePathURLs are critical so these will match the url returned from appInstallPath
            installPathContents.append(Self.catalogAppURL)

            var installedApps = self.installedApps
            installedApps.removeAll() // clear the list
            for installPath in installPathContents {
                if installPath.pathExtension != "app" {
                    continue
                }
                if FileManager.default.isDirectory(url: installPath) != true {
                    continue
                }
                let infoPlist = installPath.appendingPathComponent("Contents/Info.plist")
                do {
                    let plist = try Plist(data: Data(contentsOf: infoPlist))
                    // here was can validate some of the app's metadata, version number, etc
                    installedApps[installPath] = .success(plist)
                } catch {
                    dbg("error parsing Info.plist for:", installPath.path, error)
                    installedApps[installPath] = .failure(error)
                }
            }

            self.installedApps = installedApps
            let end = CFAbsoluteTimeGetCurrent()
            dbg("scanned", installedApps.count, "apps in:", end - start, installedBundleIDs)
        } catch {
            dbg("error performing re-scan:", error)
            self.reportError(error)
        }
    }

    /// The `appInstallPath`, or nil if it does not exist
    static func installedPath(for item: AppCatalogItem) -> URL? {
        appInstallPath(for: item).asDirectory
    }

    /// Trashes the local installed copy of this app
    func trash(item: AppCatalogItem) async {
        do {
            dbg("trashing:", item.name)
            guard let installPath = Self.installedPath(for: item) else {
                throw Errors.appNotInstalled(item)
            }

            try await trash(installPath)
        } catch {
            dbg("error performing trash for:", item.name, "error:", error)
            self.reportError(error)
        }

        // always re-scan after altering apps
        await scanInstalledApps()
    }

    /// Reveals the local installed copy of this app using the finder
    func reveal(item: AppCatalogItem) async {
        do {
            dbg("revealing:", item.name)
            guard let installPath = Self.installedPath(for: item) else {
                throw Errors.appNotInstalled(item)
            }
            dbg("revealing:", installPath.path)

#if os(macOS)
            // NSWorkspace.shared.activateFileViewerSelecting([installPath]) // unreliable
            NSWorkspace.shared.selectFile(installPath.path, inFileViewerRootedAtPath: Self.installFolderURL.path)
#endif

        } catch {
            dbg("error performing reveal for:", item.name, "error:", error)
            self.reportError(error)
        }
    }

    /// Install or update the given catalog item.
    func install(item: AppCatalogItem, progress parentProgress: Progress?, update: Bool = true) async throws {
        let window = NSApp.currentEvent?.window

        if update == false, let installPath = Self.installedPath(for: item) {
            throw Errors.appAlreadyInstalled(installPath)
        }

        try Task.checkCancellation()
        let (downloadedArtifact, downloadSha256) = try await downloadArtifact(url: item.downloadURL, progress: parentProgress)
        try Task.checkCancellation()

        // grab the hash of the download to compare against the fairseal
        dbg("comparing fairseal expected:", item.sha256, "with actual:", downloadSha256)
        if item.sha256 != downloadSha256.hex() {
            throw AppError("Invalid fairseal", failureReason: "The app's fairseal was not valid.")
        }

        try Task.checkCancellation()

        let t1 = CFAbsoluteTimeGetCurrent()
        let expandURL = downloadedArtifact.appendingPathExtension("expanded")

        let progress2 = Progress(totalUnitCount: 1)
        parentProgress?.addChild(progress2, withPendingUnitCount: 0)

        try FileManager.default.unzipItem(at: downloadedArtifact, to: expandURL, skipCRC32: false, progress: progress2, preferredEncoding: .utf8)
        try FileManager.default.removeItem(at: downloadedArtifact)
        try FileManager.default.clearQuarantine(at: expandURL)

        try Task.checkCancellation()

        let t2 = CFAbsoluteTimeGetCurrent()

        // try Process.removeQuarantine(appURL: expandURL) // xattr: [Errno 1] Operation not permitted: '/var/folders/app.App-Fair/CFNetworkDownload_XXX.tmp.expanded/Some App.app'

        let shallowFiles = try FileManager.default.contentsOfDirectory(at: expandURL, includingPropertiesForKeys: nil, options: [])
        dbg("unzipped:", downloadedArtifact.path, "to:", shallowFiles.map(\.lastPathComponent), "in:", t2 - t1)

        if shallowFiles.count != 1 {
            throw Errors.tooManyInstallFiles(item.downloadURL)
        }
        guard let expandedAppPath = shallowFiles.first(where: { $0.pathExtension == "app" }) else {
            throw Errors.noAppContents(item.downloadURL)
        }

        try Task.checkCancellation()

        // perform as much validation as possible before we attempt the install
        try self.validate(appPath: expandedAppPath, forItem: item)

        let installPath = Self.appInstallPath(for: item)
        let installFolderURL = installPath.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: installFolderURL, withIntermediateDirectories: true, attributes: nil)

        let destinationURL = installFolderURL.appendingPathComponent(expandedAppPath.lastPathComponent)

        // if we permit updates and it is already installed, trash the previous version
        if update && FileManager.default.isDirectory(url: destinationURL) == true {
            // TODO: first rename based on the old version number
            dbg("trashing:", destinationURL.path)
            try await trash(destinationURL)
        }

        try Task.checkCancellation()

        dbg("installing:", expandedAppPath.path, "into:", destinationURL.path)
        try await Self.withPermission(installFolderURL) { installFolderURL in
            try FileManager.default.moveItem(at: expandedAppPath, to: destinationURL)
        }
        if let parentProgress = parentProgress {
            parentProgress.completedUnitCount = parentProgress.totalUnitCount - 1
        }

        // always re-scan after altering apps
        await scanInstalledApps()

        if let parentProgress = parentProgress {
            parentProgress.completedUnitCount = parentProgress.totalUnitCount
        }

        if self.relaunchUpdatedApps == true {
            @MainActor func relaunch() {
                dbg("re-launching app:", item.bundleIdentifier)
                terminateAndRelaunch(bundleID: item.bundleIdentifier, force: false)
            }

            // the catalog app is special, since re-launching requires quitting the current app
            let isCatalogApp = item.bundleIdentifier.rawValue == Bundle.main.bundleID
            if !isCatalogApp {
                // automatically re-launch any app that isn't a catalog app
                relaunch()
            } else {
                // if this is the catalog app, prompt the user to re-launch
                let response = await prompt(window: window, messageText: loc("App Fair has been updated"), informativeText: loc("This app has been updated from \(Bundle.main.bundleVersionString ?? "?") to the latest version \(item.version ?? "?"). Would you like to re-launch it?"), accept: loc("Re-launch"), refuse: loc("Later"), suppressionKey: $relaunchUpdatedCatalogApp)
                dbg("prompt response:", response)
                if response == true {
                    relaunch()
                }
            }
        }
    }

    private func trash(_ fileURL: URL) async throws {
        // perform privilege escalation if needed
        let trashedURL = try await Self.withPermission(fileURL) { fileURL in
            try FileManager.default.trash(url: fileURL)
        }
        dbg("trashed:", fileURL.path, "to:", trashedURL?.path)
    }

    /// Kills the process with the given `bundleID` and re-launches it.
    private func terminateAndRelaunch(bundleID: BundleIdentifier, force: Bool) {
#if os(macOS)
        // re-launch the current app once it has been killed
        // note that NSRunningApplication cannot be used from a sandboxed app
        if let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID.rawValue).first, let path = runningApp.bundleURL {
            dbg("runningApp:", runningApp)
            // when the app is this process (i.e., the catalog browser), we need to re-start using a spawned shell script
            let pid = runningApp.processIdentifier

            // spawn a script that waits for the pid to die and then re-launches it
            // we need to do this prior to attempting termination, since we may be terminating ourself
            let relaunch = "(while /bin/kill -0 \(pid) >&/dev/null; do /bin/sleep 0.1; done; /usr/bin/open \"\(path)\") &"
            Process.launchedProcess(launchPath: "/bin/sh", arguments: ["-c", relaunch])

            // Note: “Sandboxed applications can’t use this method to terminate other applciations [sic]. This method returns false when called from a sandboxed application.”
            let terminated = force ? runningApp.forceTerminate() : runningApp.terminate()
            dbg(terminated ? "successful" : "unsuccessful", "termination")
        } else {
            dbg("no process identifier for:", bundleID)
        }
#endif // #if os(macOS)
    }

    /// Performs the given operation, and if it fails, try again after attempting a privileged operation to change the owner of the file to the current user.
    private static func withPermission<T>(_ fileURL: URL, recursive: Bool = false, block: (URL) throws -> T) async throws -> T {
        do {
            // attempt the operation without any privilege escalation first
            return try block(fileURL)
        } catch {
            #if os(macOS)
            func reauthorize(_ error: Error) async throws -> T {
                // we have a few options here:
                // 1. [SMJobBless](https://developer.apple.com/documentation/servicemanagement/1431078-smjobbless) and an XPC helper; cumbersome, and has inherent security flaws as discussed at: [](https://blog.obdev.at/what-we-have-learned-from-a-vulnerability/)
                // 2. [AuthorizationExecuteWithPrivileges](https://developer.apple.com/documentation/security/1540038-authorizationexecutewithprivileg) deprecated and un-available in swift (although the symbol can be manually coerced)
                // 3. NSAppleScript using "with administrator privileges"

                let output = try await NSUserScriptTask.fork(command: "/usr/sbin/chown \(recursive ? "-R" : "") $USER '\(fileURL.path)'", admin: true)
                dbg("successfully executed script:", output)
                // now try-try the operation with the file's permissions corrected
                return try block(fileURL)
            }

            if let error = error as? CocoaError {
                if error.code == .fileReadNoPermission
                    || error.code == .fileWriteNoPermission {
                    // e.g.: withPermission: file permission error: CocoaError(_nsError: Error Domain=NSCocoaErrorDomain Code=513 "“Pan Opticon.app” couldn’t be moved to the trash because you don’t have permission to access it." UserInfo={NSURL=./Pan%20Opticon.app/ -- file:///Applications/App%20Fair/, NSUserStringVariant=(Trash), NSUnderlyingError=0x600001535680 {Error Domain=NSOSStatusErrorDomain Code=-5000 "afpAccessDenied: Insufficient access privileges for operation "}})
                    dbg("file permission error: \(error)")
                    return try await reauthorize(error)
                } else {
                    dbg("non-file permission error: \(error)")
                    // should we reauth for any error? E.g., `.fileWriteFileExists`? For now, be conservative and only attempt to change the permissions when we are sure the failure was due to a system file read/write error
                    // return try reauthorize(error)
                    throw error
                }
            }
            #endif
            throw error
        }
    }

    func validate(appPath: URL, forItem release: AppCatalogItem) throws {
        let appPathName = appPath.deletingPathExtension().lastPathComponent
        if appPathName != release.name {
            throw Errors.wrongAppName(appPathName, release.name)
        }
    }

    enum Errors : Error {
        /// Launching apps is not supported on this platform
        case launchAppNotSupported
        /// An operation assumed the app was not installed, but it was
        case appAlreadyInstalled(URL)
        /// The expected install path was not the name of the app to be installed
        case wrongAppName(String, String)
        /// An operation assumed the app was installed, but it wasn't
        case appNotInstalled(AppCatalogItem)
        /// A problem occurred with unzipping the file
        case unableToLoadZip(URL)
        /// When there are more install files than expected
        case tooManyInstallFiles(URL)
        /// When the zip archive is empty
        case noAppContents(URL)
    }
}

extension AppInventory {

    /// Downloads the artifact for the given catalog item.
    func downloadArtifact(url: URL, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, timeoutInterval: TimeInterval = 60.0, headers: [String: String] = [:], progress parentProgress: Progress?) async throws -> (downloadedArtifact: URL, sha256: Data) {
        let t1 = CFAbsoluteTimeGetCurrent()
        var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)

        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }

        parentProgress?.kind = .file
        parentProgress?.fileOperationKind = .downloading

        let hasher = SHA256Hasher()
        let (downloadedArtifact, response) = try await URLSession.shared.download(request: request, memoryBufferSize: 1024 * 64, consumer: hasher, parentProgress: parentProgress)
        let downloadSha256 = await hasher.final()

        let t2 = CFAbsoluteTimeGetCurrent()

        dbg("downloaded:", downloadedArtifact.fileSize()?.localizedByteCount(), t2 - t1, (response as? HTTPURLResponse)?.statusCode)
        return (downloadedArtifact, downloadSha256)
    }
}

@available(macOS 12.0, iOS 15.0, *)
extension FairAppInventory {
    typealias Item = URL

    func activateFind() {
        dbg("### ", #function) // TODO: is there a way to focus the search field in the toolbar?
    }

    func updateCount() -> Int {
        appInfoItems(includePrereleases: showPreReleases).filter { item in
            item.appUpdated
        }
        .count
    }

    func badgeCount(for item: SidebarItem) -> Text? {
        switch item {
        case .top:
            return nil // Text(123.localizedNumber(style: .decimal))
        case .recent:
            return nil // Text(11.localizedNumber(style: .decimal))
        case .updated:
            return Text(updateCount(), format: .number)
        case .installed:
            return Text(installedBundleIDs.count, format: .number)
        case .category:
            if pretendMode {
                let pretendCount = item.id.utf8Data.sha256().first ?? 0 // 0-256
                return Text(pretendCount.localizedNumber(style: .decimal))
            } else {
                return nil
            }
        }
    }

    enum SidebarItem : Hashable {
        case top
        case updated
        case installed
        case recent
        case category(_ group: AppCategory.Grouping)

        /// The persistent identifier for this grouping
        var id: String {
            switch self {
            case .top:
                return "top"
            case .updated:
                return "updated"
            case .installed:
                return "installed"
            case .recent:
                return "recent"
            case .category(let grouping):
                return "category:" + grouping.rawValue
            }
        }

        func label(for source: AppSource) -> TintedLabel {
            switch source {
            case .fairapps:
                switch self {
                case .top:
                    return TintedLabel(title: Text("Apps"), systemName: AppSource.fairapps.symbol.symbolName, tint: Color.accentColor, mode: .multicolor)
                case .recent:
                    return TintedLabel(title: Text("Recent"), systemName: FairSymbol.clock_fill.symbolName, tint: Color.yellow, mode: .multicolor)
                case .installed:
                    return TintedLabel(title: Text("Installed"), systemName: FairSymbol.externaldrive_fill.symbolName, tint: Color.orange, mode: .multicolor)
                case .updated:
                    return TintedLabel(title: Text("Updated"), systemName: FairSymbol.arrow_down_app_fill.symbolName, tint: Color.green, mode: .multicolor)
                case .category(let grouping):
                    return grouping.tintedLabel
                }
            case .homebrew:
                switch self {
                case .top:
                    return TintedLabel(title: Text("Casks"), systemName: AppSource.homebrew.symbol.symbolName, tint: Color.yellow, mode: .hierarchical)
                case .installed:
                    return TintedLabel(title: Text("Installed"), systemName: FairSymbol.internaldrive.symbolName, tint: Color.orange, mode: .hierarchical)
                case .recent: // not supported with casks
                    return TintedLabel(title: Text("Recent"), systemName: FairSymbol.clock.symbolName, tint: Color.green, mode: .hierarchical)
                case .category(let grouping):
                    return grouping.tintedLabel
                case .updated:
                    return TintedLabel(title: Text("Updated"), systemName: FairSymbol.arrow_down_app.symbolName, tint: Color.green, mode: .hierarchical)
                }
            }

        }

        /// True indicates that this sidebar specifies to filter for locally-installed packages
        var isLocalFilter: Bool {
            switch self {
            case .updated:
                return true
            case .installed:
                return true
            case .top:
                return false
            case .recent:
                return false
            case .category:
                return false
            }
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
extension FairAppInventory.SidebarItem {
    func matches(item: AppInfo) -> Bool {
        switch self {
        case .top:
            return true
        case .updated:
            return item.appUpdated
        case .installed:
            return item.installedVersion != nil
        case .recent:
            return true
        case .category(let category):
            return Set(category.categories).intersection(item.release.appCategories).isEmpty == false
        }
    }
}
