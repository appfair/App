import FairApp

/// The manager for the current app fair
@available(macOS 12.0, iOS 15.0, *)
@MainActor public final class AppManager: SceneManager {
    /// The location where apps will be installed; the last component must match the catalog browser app itself, so a fair-ground named the "Games Arcade" would install into "/Applications/Games Arcade/" and the name of the catalog browser app itself would be "/Applications/Games Arcade.app"
    static let installPath = "/Applications/" + Bundle.mainBundleName + "/"

    /// The base domain of the provider for the hub
    @AppStorage("hubProvider") public var hubProvider = "github.com"
    /// The organization name of the hub
    @AppStorage("hubOrg") public var hubOrg = appfairName
    /// The name of the base repository for the provider
    @AppStorage("hubRepo") public var hubRepo = AppNameValidation.defaultAppName

    /// An optional authorization token for direct API usage
    @AppStorage("hubToken") public var hubToken = ""

    @AppStorage("catalogURL") public var catalogURL: URL = URL(string: "https://www.appfair.net/fairapps.json")!

    @AppStorage("displayMode") var displayMode: TriptychOrient = TriptychOrient.allCases.last!

    @Published public var errors: [AppError] = []

    /// The list of currently installed apps of the appID to the Info.plist (or error)
    @Published var installedApps: [URL : Result<Plist, Error>] = [:]

    /// The current catalog of apps
    @Published var catalog: [AppCatalogItem] = []

    static let `default`: AppManager = AppManager()

    internal required init() {

    }
}

@available(macOS 12.0, iOS 15.0, *)
extension AppManager {
    func fetchApps(cache: URLRequest.CachePolicy? = nil) async {
        do {
            let start = CFAbsoluteTimeGetCurrent()
            let catalog = try await self.hub().fetchCatalog(catalogURL: catalogURL, cache: cache)
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

    static var installFolderURL: URL {
        URL(fileURLWithPath: installPath)
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
            try FileManager.default.createDirectory(at: Self.installFolderURL, withIntermediateDirectories: true, attributes: nil)

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
                    let plist = try Plist(propertyListURL: infoPlist)
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

    func install(item: AppCatalogItem, progress: Progress, update: Bool = true) async throws {
        if update == false, let installPath = Self.installedPath(for: item) {
            throw Errors.appAlreadyInstalled(installPath)
        }

        let t1 = CFAbsoluteTimeGetCurrent()
        let request = URLRequest(url: item.downloadURL) // , cachePolicy: T##URLRequest.CachePolicy, timeoutInterval: T##TimeInterval)

        progress.kind = .file
        progress.fileOperationKind = .downloading

        final class Delegate : NSObject, URLSessionDownloadDelegate {
            let progress: Progress

            init(progress: Progress) {
                self.progress = progress
            }

            func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
                progress.totalUnitCount = totalBytesExpectedToWrite
                progress.completedUnitCount = totalBytesWritten
                // TODO:
                // progress.estimatedTimeRemaining = …
                // progress.throughput = …
            }

            func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
                // progress.completedUnitCount = progress.totalUnitCount
                progress.totalUnitCount = 0
                progress.completedUnitCount = 0
            }
        }

        let delegate: URLSessionDownloadDelegate = Delegate(progress: progress)
        let (downloadedZip, response) = try await URLSession.shared.download(for: request, delegate: delegate)
        let t2 = CFAbsoluteTimeGetCurrent()
        dbg("downloaded:", downloadedZip, try? downloadedZip.fileSize()?.localizedByteCount(), "response:", (response as? HTTPURLResponse)?.statusCode, "in:", t2 - t1)

        // grab the hash of the download to compare against the fairseal
        let actualSha256 = try Data(contentsOf: downloadedZip, options: .mappedIfSafe).sha256().hex()
        dbg("comparing fairseal expected:", item.sha256, "with actual:", actualSha256)
        if item.sha256 != actualSha256 {
            throw AppError("Invalid fairseal", failureReason: "The app's fairseal was not valid.")
        }

        let t3 = CFAbsoluteTimeGetCurrent()
        let expandURL = downloadedZip.appendingPathExtension("expanded")


        try FileManager.default.extractContents(from: downloadedZip, to: expandURL, progress: progress, handler: { url in
            #if macOS
            // attempt to clear quarantine flag so we can launch the app

            // https://eclecticlight.co/2020/10/29/quarantine-and-the-quarantine-flag/
            // let qtprops1 = try (url as NSURL).resourceValues(forKeys: [URLResourceKey.quarantinePropertiesKey])

            /*
             Default properties look like:
            /var/folders/f8/91ygcnx16fb5yldgcmns99q00000gn/T/app.App-Fair/CFNetworkDownload_o89pPj.tmp.expanded/Cloud Cuckoo.app/Contents/_CodeSignature/CodeResources flags: [__C.NSURLResourceKey(_rawValue: NSURLQuarantinePropertiesKey): {
                LSQuarantineAgentName = "AppFair App";
                LSQuarantineIsOwnedByCurrentUser = 1;
                LSQuarantineTimeStamp = "2021-10-14 17:57:12 +0000";
                LSQuarantineType = LSQuarantineTypeSandboxed;
            }]
             */

            // try to just clear the quarantine
            // let qprops: [String: Any] = [
            //   kLSQuarantineAgentNameKey as String: "App Fair",
            //   kLSQuarantineAgentBundleIdentifierKey as String: "app.App-Fair",
            //   kLSQuarantineTypeKey as String: kLSQuarantineTypeWebDownload,
            //   kLSQuarantineDataURLKey as String: downloadedZip,
            //   kLSQuarantineOriginURLKey as String: item.downloadURL
            //]

            //try (url as NSURL).setResourceValues([URLResourceKey.quarantinePropertiesKey: qprops])

            // try! (url as NSURL).setResourceValues([URLResourceKey.quarantinePropertiesKey: [] as NSArray])


            // try to clear the quarantine flag; this will fail if the app is sandboxed
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

        // try Process.removeQuarantine(appURL: expandURL) // xattr: [Errno 1] Operation not permitted: '/var/folders/f8/91ygcnx16fb5yldgcmns99q00000gn/T/app.App-Fair/CFNetworkDownload_ZGu16E.tmp.expanded/Some App.app'

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

        let installFolder = Self.appInstallPath(for: item).deletingLastPathComponent()
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
