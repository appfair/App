import FairApp
import Dispatch

#if os(macOS)
let displayExtensions: Set<String>? = ["zip"]
let catalogURL: URL = URL(string: "https://www.appfair.net/fairapps.json")!
#endif

#if os(iOS)
let displayExtensions: Set<String>? = ["ipa"]
let catalogURL: URL = URL(string: "https://www.appfair.net/fairapps-iOS.json")!
#endif

/// The manager for the current app fair
@available(macOS 12.0, iOS 15.0, *)
@MainActor public final class AppManager: SceneManager {
    @AppStorage("themeStyle") var themeStyle = ThemeStyle.system

    /// The base domain of the provider for the hub
    @AppStorage("hubProvider") public var hubProvider = "github.com"
    /// The organization name of the hub
    @AppStorage("hubOrg") public var hubOrg = appfairName
    /// The name of the base repository for the provider
    @AppStorage("hubRepo") public var hubRepo = AppNameValidation.defaultAppName

    /// An optional authorization token for direct API usagefor the organization must
    ///
    @AppStorage("hubToken") public var hubToken = ""

    @AppStorage("showPreReleases") var showPreReleases = false

    @AppStorage("riskFilter") private var riskFilter = AppRisk.risky

    @Published public var errors: [AppError] = []

    /// The list of currently installed apps of the appID to the Info.plist (or error)
    @Published var installedApps: [URL : Result<Plist, Error>] = [:]

    /// Whether we are currently fetching apps
    @Published var fetching: Bool = false

    /// The current catalog of apps
    @Published var catalog: [AppCatalogItem] = []

    /// The fetched readmes for the apps
    @Published private var readmes: [URL: Result<AttributedString, Error>] = [:]

    static let `default`: AppManager = AppManager()

    private var fsobserver: FileSystemObserver!

    internal required init() {
        super.init()

        // set up a file-system observer for the install folder, which will refresh the installed apps whenever any changes are made; this allows external processes like homebrew to update the installed app
        self.fsobserver = FileSystemObserver(URL: Self.installFolderURL) {
            dbg("changes detected in app folder:", Self.installFolderURL.path)
            Task {
                await self.scanInstalledApps()
            }
        }

        /// The gloal quick actions for the App Fair
        self.quickActions = [
            QuickAction(id: "refresh-action", localizedTitle: loc("Refresh Catalog")) { completion in
                dbg("refresh-action")
                Task {
                    await self.fetchApps(cache: .reloadIgnoringLocalAndRemoteCacheData)
                    completion(true)
                }
            }
        ]
    }
}

@available(macOS 12.0, iOS 15.0, *)
extension AppManager {
    func fetchApps(cache: URLRequest.CachePolicy? = nil) async {
        do {
            self.fetching = true
            defer { self.fetching = false }
            let start = CFAbsoluteTimeGetCurrent()
            let catalog = try await FairHub.fetchCatalog(catalogURL: catalogURL, cache: cache)
            self.catalog = catalog.apps
            let end = CFAbsoluteTimeGetCurrent()
            dbg("fetched catalog:", catalog.apps.count, "in:", (end - start))
        } catch {
            Task { // otherwise warnings about accessing off of the main thread
                // errors here are not unexpected, since we can get a `cancelled` error if the view that initiated the `fetchApps` request
                dbg("received error:", error)
                // we tolerate a "cancelled" error because it can happen when a view that is causing a catalog load is changed and its request gets automaticallu cancelled
                if (error as NSError).domain == NSURLErrorDomain && (error as NSError).code == -999 {

                } else {
                    self.reportError(error)
                }
            }
        }
    }

    /// All the app-info items, sorted and filtered based on whether to include pre-releases.
    ///
    /// - Parameter includePrereleases: when `true`, versions marked `beta` will superceed any non-`beta` versions.
    /// - Returns: the list of apps, including all the installed apps, as well as matching pre-leases
    func appInfoItems(includePrereleases: Bool) -> [AppInfo] {
        let installedApps: [String?: [Plist]] = Dictionary(grouping: self.installedApps.values.compactMap(\.successValue), by: \.CFBundleIdentifier)

        // multiple instances of the same bundleID can exist for "beta" set to `false` and `true`;
        // the visibility of these will be controlled by whether we want to display pre-releases
        let bundleAppInfoMap: [String: [AppInfo]] = catalog
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
    func arrangedItems(category: SidebarItem?, sortOrder: [KeyPathComparator<AppInfo>], searchText: String) -> [AppInfo] {
        self
            .appInfoItems(includePrereleases: showPreReleases)
            .filter({ matchesFilterText(item: $0) })
            .filter({ category == .installed || category == .updated || matchesRiskFilter(item: $0) })
            .filter({ matchesSearch(item: $0, searchText: searchText) })
            .filter({ categoryFilter(category: category, item: $0) })
            .sorted(using: sortOrder + categorySortOrder(category: category))
    }

    func categorySortOrder(category: SidebarItem?) -> [KeyPathComparator<AppInfo>] {
        switch category {
        case .none:
            return []
        case .popular:
            return [KeyPathComparator(\AppInfo.release.starCount, order: .reverse), KeyPathComparator(\AppInfo.release.downloadCount, order: .reverse)]
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

    func categoryFilter(category: SidebarItem?, item: AppInfo) -> Bool {
        category?.matches(item: item) != false
    }

    func matchesFilterText(item: AppInfo) -> Bool {
        displayExtensions?.contains(item.release.downloadURL.pathExtension) != false
    }

    func matchesRiskFilter(item: AppInfo) -> Bool {
        item.release.riskLevel <= riskFilter
    }

    func matchesSearch(item: AppInfo, searchText: String) -> Bool {
        (searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || item.release.name.localizedCaseInsensitiveContains(searchText) == true
            || item.release.subtitle?.localizedCaseInsensitiveContains(searchText) == true
            || item.release.localizedDescription.localizedCaseInsensitiveContains(searchText) == true)
    }

    static var installFolderURL: URL {

        // we would like the install folder to be the same-named peer of the app's location, allowing it to run in `~/Downloads/` (which would place installed apps in `~/Downloads/App Fair`)
        // however, app translocation prevents it from knowing its location on first launch, and so we can't rely on being able to install as a peer without nagging the user to first move the app somewhere (thereby exhausting translocation)
        // Bundle.main.bundleURL.deletingPathExtension()
        URL(fileURLWithPath: Bundle.mainBundleName, relativeTo: (try? FileManager.default.url(for: .applicationDirectory, in: .localDomainMask, appropriateFor: nil, create: true)) ?? URL(fileURLWithPath: "/Applications"))
    }

    /// Register that an error occurred with the app manager
    func reportError(_ error: Error) {
        errors.append(AppError(error))
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

    func scanInstalledApps() async {
        dbg()
        do {
            let start = CFAbsoluteTimeGetCurrent()

            // always try to ensure the install folder is created (in case the user clobbers the app install folder while we are running)
            try? FileManager.default.createDirectory(at: Self.installFolderURL, withIntermediateDirectories: true, attributes: nil)

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

            // TODO: quit the app if it is running
            let trashedURL = try FileManager.default.trash(url: installPath)
            dbg("trashed:", item.name, "to:", trashedURL?.path)

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
            dbg("error performing trash for:", item.name, "error:", error)
            self.reportError(error)
        }
    }

    @discardableResult fileprivate func extractDownload(_ downloadedZip: URL, _ expandURL: URL, _ progress2: Progress) throws -> [ZipArchive.Entry] {
        try FileManager.default.extractContents(from: downloadedZip, to: expandURL, progress: progress2, handler: { url in
#if macOS
            // try to clear the quarantine flag
            var url = url
            var resourceValues = URLResourceValues()
            resourceValues.quarantineProperties = nil // this should clear the quarantine flag
            do {
                try url.setResourceValues(resourceValues) // note: “Attempts to set a read-only resource property or to set a resource property not supported by the resource are ignored and are not considered errors. This method is currently applicable only to URLs for file system resources.”
            } catch {
                dbg("unable to clear quarantine flag for:", url.path)
            }

            // check to ensure we have cleared the props
            let qtprops2 = try (url as NSURL).resourceValues(forKeys: [URLResourceKey.quarantinePropertiesKey])
            if !qtprops2.isEmpty {
                dbg("found quarantine xattr for:", url.path, "keys:", qtprops2)
                throw AppError("Quarantined App", failureReason: "The app was quarantined by the system and cannot be installed.")
            }
#endif
            return true
        })
    }

    static let progressUnitCount: Int64 = 4

    /// Install or update the given catalog item.
    func install(item: AppCatalogItem, progress parentProgress: Progress, update: Bool = true) async throws {
        if update == false, let installPath = Self.installedPath(for: item) {
            throw Errors.appAlreadyInstalled(installPath)
        }

        let t1 = CFAbsoluteTimeGetCurrent()
        let request = URLRequest(url: item.downloadURL) // , cachePolicy: T##URLRequest.CachePolicy, timeoutInterval: T##TimeInterval)

        parentProgress.kind = .file
        parentProgress.fileOperationKind = .downloading


        // we would just to use a download task to save directly to a file and have callbacks go through DownloadDelegate, but it is not working with async/await (see https://stackoverflow.com/questions/68276940/how-to-get-the-download-progress-with-the-new-try-await-urlsession-shared-downlo)
        // let delegate: URLSessionDownloadDelegate = DownloadDelegate(progress: parentProgress)
        // (downloadedZip, response) = try await URLSession.shared.download(for: request, delegate: delegate)

        
        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
        let length = response.expectedContentLength
        let progress1 = Progress(totalUnitCount: length)
        parentProgress.addChild(progress1, withPendingUnitCount: Self.progressUnitCount - 1)

        var data = Data()
        data.reserveCapacity(Int(length))

        var fastRunningProgress: Double = 0

        for try await byte in asyncBytes {
            if parentProgress.isCancelled {
                throw AppError("Cancelled", failureReason: "The download was cancelled.")
            }
            data.append(byte)
            let dataCount = Int64(data.count)
            let currentProgress = Double(data.count) / Double(length)
            // only update once per percent
            if Int(fastRunningProgress * 100) != Int(currentProgress * 100) {
                progress1.completedUnitCount = dataCount
                fastRunningProgress = currentProgress
            }
        }

        let t2 = CFAbsoluteTimeGetCurrent()
        dbg("downloaded:", length.localizedByteCount(), "response:", (response as? HTTPURLResponse)?.statusCode, "in:", t2 - t1)

        // grab the hash of the download to compare against the fairseal
        let actualSha256 = data.sha256().hex()
        dbg("comparing fairseal expected:", item.sha256, "with actual:", actualSha256)
        if item.sha256 != actualSha256 {
            throw AppError("Invalid fairseal", failureReason: "The app's fairseal was not valid.")
        }

        let installPath = Self.appInstallPath(for: item)

        // create a temporary zip file in the caches directory from which we will extract the data
        let downloadedZip = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: installPath, create: true)
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("zip")

        // make sure the file doesn't already exist
        try? FileManager.default.removeItem(at: downloadedZip)

        try data.write(to: downloadedZip, options: .atomic)

        let t3 = CFAbsoluteTimeGetCurrent()
        let expandURL = downloadedZip.appendingPathExtension("expanded")

        let progress2 = Progress(totalUnitCount: 1)
        parentProgress.addChild(progress2, withPendingUnitCount: 1)

//        try self.extractDownload(downloadedZip, expandURL, progress2)
//        let _: [ZipArchive.Entry] = try await Task(priority: .userInitiated) {
            try self.extractDownload(downloadedZip, expandURL, progress2)
//        }.value

        try FileManager.default.removeItem(at: downloadedZip)

        // try Process.removeQuarantine(appURL: expandURL) // xattr: [Errno 1] Operation not permitted: '/var/folders/app.App-Fair/CFNetworkDownload_XXX.tmp.expanded/Some App.app'

        let shallowFiles = try FileManager.default.contentsOfDirectory(at: expandURL, includingPropertiesForKeys: nil, options: [])
        dbg("unzipped:", downloadedZip.path, "to:", shallowFiles.map(\.lastPathComponent), "in:", t3 - t2)

        if shallowFiles.count != 1 {
            throw Errors.tooManyInstallFiles(item.downloadURL)
        }
        guard let expandedAppPath = shallowFiles.first(where: { $0.pathExtension == "app" }) else {
            throw Errors.noAppContents(item.downloadURL)
        }

        // perform as much validation before we perform the install
        try self.validate(appPath: expandedAppPath, forItem: item)

        let installFolder = installPath.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: installFolder, withIntermediateDirectories: true, attributes: nil)

        let destinationURL = installFolder.appendingPathComponent(expandedAppPath.lastPathComponent)

        // if we permit updates and it is already installed, trash the previous version
        if update && FileManager.default.isDirectory(url: destinationURL) == true {
            // TODO: first rename based on the old version number
            dbg("trashing:", destinationURL.path)
            try FileManager.default.trash(url: destinationURL)
        }

        dbg("installing:", expandedAppPath.path, "into:", destinationURL.path)
        try FileManager.default.moveItem(at: expandedAppPath, to: destinationURL)
        parentProgress.completedUnitCount = parentProgress.totalUnitCount - 1

        // if we are the catalog app ourselves, re-launch after updating
        if item.bundleIdentifier == Bundle.mainBundleID {
            dbg("re-launching catalog app")
#if os(macOS)
            //let proc = Process()
            //proc.executableURL = destinationURL
            //proc.launch()

            let task = Process()
            task.launchPath = "/usr/bin/open"
            task.arguments = [destinationURL.path]
            task.launch()

            DispatchQueue.main.async {
                NSApp.terminate(self)
            }
#endif // #if os(macOS)
        }

        // always re-scan after altering apps
        await scanInstalledApps()
        parentProgress.completedUnitCount = parentProgress.totalUnitCount
    }

    func validate(appPath: URL, forItem release: AppCatalogItem) throws {
        let appPathName = appPath.deletingPathExtension().lastPathComponent
        if appPathName != release.name {
            throw Errors.wrongAppName(appPathName, release.name)
        }
    }

    private static let readmeRegex = Result {
        try NSRegularExpression(pattern: #".*## Description\n(?<description>[^#]+)\n#.*"#, options: .dotMatchesLineSeparators)
    }

    func readme(for release: AppCatalogItem) -> AttributedString? {
        guard let readmeURL = release.readmeURL else {
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
                dbg("fetching README for:", release.id, readmeURL.absoluteString)
                let data = try await URLRequest(url: readmeURL)
                    .fetch(validateFragmentHash: true)
                var atx = String(data: data, encoding: .utf8) ?? ""
                // extract the portion of text between the "# Description" and following "#" sections
                if let match = try Self.readmeRegex.get().firstMatch(in: atx, options: [], range: atx.span)?.range(withName: "description") {
                    atx = (atx as NSString).substring(with: match)
                } else {
                    atx = ""
                }

                // the README.md relative location is 2 paths down from the repository base, so for relative links to Issues and Discussions to work the same as they do in the web version, we need to append the path that the README would be rendered in the browser
                let baseURL = release.baseURL.appendingPathComponent("blob/main/")
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

@available(macOS 12.0, iOS 15.0, *)
extension AppManager.SidebarItem {
    func matches(item: AppInfo) -> Bool {
        switch self {
        case .popular:
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

/// A watcher for changes to the install folder
private final class FileSystemObserver {
    private let fileDescriptor: CInt
    private let source: DispatchSourceProtocol

    init(URL: URL, block: @escaping () -> Void) {
        self.fileDescriptor = open(URL.path, O_EVTONLY)
        self.source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: self.fileDescriptor, eventMask: .all, queue: DispatchQueue.global())
        self.source.setEventHandler {
            block()
        }
        self.source.resume()
    }

    deinit {
        self.source.cancel()
        close(fileDescriptor)
    }
}

/// A DownloadDelegate that updates a progress.
/// Note: note currently working, perhaps due to un-implemented async/await support: https://stackoverflow.com/questions/68276940/how-to-get-the-download-progress-with-the-new-try-await-urlsession-shared-downlo
@objc private final class DownloadDelegate : NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
    let progress: Progress

    init(progress: Progress) {
        self.progress = progress
    }

    @objc func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
        // e.g.: https://github-releases.githubusercontent.com/420526657/7773060d-16b7-40b1-bdbe-03c0da4753f2?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20211201%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20211201T011008Z&X-Amz-Expires=300&X-Amz-Signature=5f1184f9fe71e5fb3724ea7bd96f2d8a3215056d4323afedf9fc56b4aa2a8114&X-Amz-SignedHeaders=host&actor_id=0&key_id=0&repo_id=420526657&response-content-disposition=attachment%3B%20filename%3DBon-Mot-macOS.zip&response-content-type=application%2Foctet-stream
        dbg("willPerformHTTPRedirection:", request.description)
        return request // allow all redirections
    }

    @objc func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        dbg("didWriteData:", bytesWritten, "total", totalBytesWritten, "/", totalBytesExpectedToWrite)
        progress.totalUnitCount = totalBytesExpectedToWrite
        progress.completedUnitCount = totalBytesWritten
        // TODO:
        // progress.estimatedTimeRemaining = …
        // progress.throughput = …
    }

    @objc func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // progress.completedUnitCount = progress.totalUnitCount
        progress.totalUnitCount = 0
        progress.completedUnitCount = 0
    }

    @objc func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        progress.totalUnitCount = 0
        progress.completedUnitCount = 0
    }

    @objc func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        dbg(metrics)
    }

    @objc func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
    }

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {

    }

    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {

    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {

    }
}
