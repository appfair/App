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
import Combine

/// A controller that handles multiple app inventory instances
protocol AppInventoryController {
    @MainActor var inventories: [(AppInventory, AnyCancellable)] { get }

    /// Finds the inventory for the given identifier in the managers list of sources
    @MainActor func inventory(from source: AppSource) -> AppInventory?
}


extension AppInventoryController {
    @MainActor var appInventories: [AppInventory] {
        inventories.map(\.0)
    }

    @MainActor var appSources: [AppSource] {
        appInventories.map(\.source)
    }

    @MainActor func inventory(from source: AppSource) -> AppInventory? {
        appInventories.first(where: { $0.source == source })
    }

    @MainActor func inventory(for item: AppInfo) -> AppInventory? {
        inventory(from: item.source)
        //item.isCask ? homeBrewInv : fairAppInv
    }

    /// Returns the metadata for the given catalog
    @MainActor func sourceInfo(for selection: SourceSelection) -> AppSourceInfo? {
        inventory(for: selection.source)?.sourceInfo(for: selection.section)
    }

    @MainActor func inventory(for source: AppSource) -> AppInventory? {
        inventory(from: source)
    }

    /// The caskManager, which should be extracted as a separate `EnvironmentObject`
    ///
    /// -TODO: @available(*, deprecated, renamed: "inventory(from:)")
    @MainActor var homeBrewInv: HomebrewInventory? {
        inventory(from: .homebrew) as? HomebrewInventory
    }

    /// Returns a list of all the inventories that extend from `AppSourceInventory`
    @MainActor var appSourceInventories: [AppSourceInventory] {
        appInventories.compactMap({ $0 as? AppSourceInventory })
    }
}

@available(macOS 12.0, iOS 15.0, *)
@MainActor public final class FairManager: SceneManager, AppInventoryController {
    @AppStorage("themeStyle") var themeStyle = ThemeStyle.system

    @AppStorage("enableInstallWarning") public var enableInstallWarning: Bool = true
    @AppStorage("enableDeleteWarning") public var enableDeleteWarning: Bool = true
    @AppStorage("enableSponsorship") public var enableSponsorship: Bool = true

    /// The base domain of the provider for the hub
    @AppStorage("hubProvider") public var hubProvider = "github.com"
    /// The organization name of the hub
    @AppStorage("hubOrg") public var hubOrg = "appfair"
    /// The name of the base repository for the provider
    @AppStorage("hubRepo") public var hubRepo = "App"

    /// An optional authorization token for direct API usagefor the organization
    @AppStorage("hubToken") public var hubToken = ""

    /// Whether to try blocking launch telemetry reporting
    @AppStorage("appLaunchPrivacy") public var appLaunchPrivacy: Bool = false

    /// The duration to continue blocking launch telemtry after an app has been launched (since the OS retries for a certain amount of time if the initial connection fails)
    @AppStorage("appLaunchPrivacyDuration") public var appLaunchPrivacyDuration: TimeInterval = 60.0

    /// Whether links clicked in the embedded browser should open in a new browser window
    @AppStorage("openLinksInNewBrowser") var openLinksInNewBrowser: Bool = true

    /// Whether the embedded browser should use private browsing mode for untrusted sites
    @AppStorage("usePrivateBrowsingMode") var usePrivateBrowsingMode: Bool = true

    /// Whether to enable user-specified sources
    @AppStorage("enableUserSources") var enableUserSources: Bool = false

    /// The list of source URL strings to load as sources
    @AppStorage("userSources") var userSources: AppStorageArray<String> = []

    /// The inventories of app sources that are currently available
    @Published var inventories: [(AppInventory, AnyCancellable)] = []

//    /// The appManager, which should be extracted as a separate `EnvironmentObject`
//    @Published var fairAppInv: AppSourceInventory
//    /// The caskManager, which should be extracted as a separate `EnvironmentObject`
//    @Published var homeBrewInv: HomebrewInventory

    /// The apps that have been installed or updated in this session
    @Published var sessionInstalls: Set<AppInfo.ID> = []

    /// The current app exit observer for app launch privacy; it will be cleared when the observer expires
    @Published private var appLaunchPrivacyDeactivator: NSObjectProtocol? = nil

    /// The current activities that are taking place for each bundle identifier
    @Published var operations: [BundleIdentifier: CatalogOperation] = [:]

    /// A cache for images that are loaded by this manager
    //let imageCache = Cache<URL, Image>()

    @Published public var errors: [AppError] = []

    //private var observers: [AnyCancellable] = []

    required internal init() {
        super.init()
        self.resetAppSources()

        /// The gloal quick actions for the App Fair
        self.quickActions = [
            QuickAction(id: "refresh-action", localizedTitle: NSLocalizedString("Refresh Catalog", bundle: .module, comment: "action button title for refreshing the catalog")) { completion in
                dbg("refresh-action")
                Task {
                    //await self.appManager.fetchApps(cache: .reloadIgnoringLocalAndRemoteCacheData)
                    completion(true)
                }
            }
        ]
    }

    /// Called when the user preference changes
    func updateUserSources(enable: Bool) {
        dbg(enable)
        resetAppSources(load: true)
    }

    /// Resets the in-memory list of app sources without touching the
    func resetAppSources(load: Bool = false) {
        self.inventories.removeAll()

        addInventory(HomebrewInventory(source: .homebrew, sourceURL: appfairCaskAppsURL))
        addAppSource(url: appfairCatalogURLMacOS, persist: false)

        if enableUserSources {
            for source in self.userSources.compactMap(URL.init(string:)) {
                dbg("adding user source:", source.absoluteString)
                addAppSource(url: source, load: load, persist: false)
            }
        }
    }

    /// Adds an app source to the list of inventories
    ///
    /// - Parameters:
    ///   - url: the url of the source
    ///   - load: whether to start a task to load the contents of the source
    ///   - persist: whether to save the URL in the persistent list of sources
    /// - Returns: whether the source was successfully added
    @discardableResult func addAppSource(url: URL, load: Bool = false, persist: Bool) -> AppSourceInventory? {
        let source = AppSource(rawValue: url.absoluteString)
        let inv = AppSourceInventory(source: source, sourceURL: url)
        let added = addInventory(inv)
        if added == false {
            return nil
        } else {
            if load {
                Task {
                    await self.refresh(inventory: inv, reloadFromSource: true)
                }
            }

            if persist { // save the source in the user defaults
                userSources.append(url.absoluteString)
            }
            return inv
        }
    }

    /// Removed the inventory for the given source, both from the current inventories
    /// as well as from the persistent list saved in ``AppStorage``.
    @discardableResult func removeInventory(for removeSource: AppSource, persist: Bool) -> Bool {
        var found = false
        for (index, (inv, _)) in self.inventories.enumerated().reversed() {
            if removeSource == inv.source {
                self.inventories.remove(at: index)
                if persist {
                    self.userSources.removeAll { $0 == removeSource.rawValue }
                }
                found = true
            }
        }
        return found
    }

    @discardableResult func addInventory(_ inventory: AppInventory) -> Bool {
        if let _ = self.inventories.first(where: { inv, _ in
            inv.source == inventory.source
        }) {
            // the source of the inventory is the unique identifier
            return false
        }

        // track any changes to the inventory and broadcast their changes
        let observer = inventory.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }
        self.inventories.append((inventory, observer))
        return true
    }

    func arrangedItems(source: AppSource, sourceSelection: SourceSelection?, sortOrder: [KeyPathComparator<AppInfo>], searchText: String) -> [AppInfo] {
        self.inventory(for: source)?.arrangedItems(sourceSelection: sourceSelection, sortOrder: sortOrder, searchText: searchText) ?? []
    }

    func badgeCount(for item: SourceSelection) -> Text? {
        inventory(for: item.source)?.badgeCount(for: item.section)
    }

    /// Returns true is there are any refreshes in progress
    var refreshing: Bool {
        self.appInventories.contains { $0.updateInProgress > 0 }
    }

    func refresh(inventory: AppInventory, reloadFromSource: Bool) async {
        do {
            try await inventory.refreshAll(reloadFromSource: reloadFromSource)
        } catch {
            self.reportError(AppError(String(format: NSLocalizedString("Error Loading Catalog", bundle: .module, comment: "error wrapper string when a catalog URL fails to load")), failureReason: String(format: NSLocalizedString("The catalog failed to load from the URL: %@", bundle: .module, comment: "error wrapper string when a catalog URL fails to load"), inventory.sourceURL.absoluteString), underlyingError: error))
        }
    }

    func refresh(reloadFromSource: Bool) async {
        await withTaskGroup(of: Void.self, returning: Void.self) { group in
            for inv in self.appInventories.shuffled() {
                let _ = group.addTaskUnlessCancelled {
                    await self.refresh(inventory: inv, reloadFromSource: reloadFromSource)
                }
            }
        }
    }

    func reportError(_ error: Error) {
        errors.append(error as? AppError ?? AppError(error))
    }
    
    func inactivate() {
        dbg("inactivating and clearing caches")
        clearCaches()
    }

    func clearCaches() {
        //imageCache.clear()
        //fairAppInv.imageCache.clear()
        //homeBrewInv.imageCache.clear()
        //URLSession.shared.invalidateAndCancel()
        URLSession.shared.configuration.urlCache?.removeAllCachedResponses()
        URLCache.shared.removeAllCachedResponses()
    }

    /// Attempts to perform the given action and adds any errors to the error list if they fail.
    func trying(block: () async throws -> ()) async {
        do {
            try await block()
        } catch {
            reportError(error)
        }
    }

    func updateCount() -> Int {
        appInventories.map({ $0.updateCount() }).reduce(0, { $0 + $1 })
    }

    /// The view that will summarize the app source in the detail panel when no app is selected.
    func sourceOverviewView(selection: SourceSelection, showText: Bool, showFooter: Bool) -> some View {
        let inv: AppInventory? = inventory(for: selection.source)
        let info = inv?.sourceInfo(for: selection.section)
        let label = info?.label
        let color = label?.tint ?? .accentColor

        return VStack(spacing: 0) {
            Group {
                Divider()
                    .background(color)
                    .padding(.top, 1)

                label
                    .foregroundColor(Color.primary)
                    //.font(.largeTitle)
                    .symbolVariant(.fill)
                    .font(Font.largeTitle)
                    //.font(self.sourceFont(sized: 40))
                    .frame(height: 60)

                Divider()
                    .background(color)
            }

            Spacer()
            
            ScrollView {
                Group {
                    if showText, let info = info, let overview = info.overviewText {
                        overview.joined(separator: Text(verbatim: "\n\n"))
                                .font(Font.title2)
                    }
                    if let description = (inv as? AppSourceInventory)?.catalog?.localizedDescription {
                        Text(atx: description)
                    }
                }
                .padding()
            }
            .textSelection(.enabled) // bug: sometimes selecting will unwraps and converts to a single line

            Spacer()
            if showFooter, let info = info {
                ForEach(enumerated: info.footerText) { _, footerText in
                    footerText
                        .textSelection(.enabled)
                }
                    .font(.footnote)
            }
        }
    }


    /// The icon for the given item
    /// - Parameters:
    ///   - info: the info to check
    ///   - transition: whether to use a fancy transition
    /// - Returns: the icon
    @ViewBuilder func iconView(for item: AppInfo, transition: Bool = false) -> some View {
        Group {
            inventory(for: item.source)?.icon(for: item)
        }
        //.transition(AnyTransition.scale(scale: 0.50).combined(with: .opacity)) // bounce & fade in the icon
        .transition(transition == false ? AnyTransition.opacity : AnyTransition.asymmetric(insertion: AnyTransition.opacity, removal: AnyTransition.scale(scale: 0.75).combined(with: AnyTransition.opacity))) // skrink and fade out the placeholder while fading in the actual icon

    }

    func launch(_ item: AppInfo) async {
        await self.trying {
            if self.appLaunchPrivacy {
                try await self.enableAppLaunchPrivacy()
            }
            try await inventory(for: item)?.launch(item)
        }
    }

    func install(_ item: AppInfo, source: AppSource, progress parentProgress: Progress?, manageDownloads: Bool? = nil, update: Bool = true, verbose: Bool = true) async {
        await self.trying {
            try await inventory(for: item)?.install(item, progress: parentProgress, update: update, verbose: verbose)
            sessionInstalls.insert(item.id)
        }
    }

    func reveal(_ item: AppInfo) async {
        await self.trying {
            try await inventory(for: item)?.reveal(item)
        }
    }

    func delete(_ item: AppInfo) async throws {
        try await inventory(for: item)?.delete(item, verbose: true)
    }

    func installedVersion(_ item: AppInfo) -> String? {
        inventory(for: item)?.appInstalled(item)
    }

    func appUpdated(_ item: AppInfo) -> Bool {
        inventory(for: item)?.appUpdated(item) == true
    }
}

extension SourceSelection {

//    var sourceInfo: AppSourceInfo? {
//        switch self.source {
//        case .appSourceFairgroundMacOS, .appSourceFairgroundiOS:
//            switch self.item {
//            case .top:
//                return AppSourceInventory.SourceInfo.TopAppInfo()
//            case .recent:
//                return AppSourceInventory.SourceInfo.RecentAppInfo()
//            case .installed:
//                return AppSourceInventory.SourceInfo.InstalledAppInfo()
//            case .sponsorable:
//                return AppSourceInventory.SourceInfo.SponsorableAppInfo()
//            case .updated:
//                return AppSourceInventory.SourceInfo.UpdatedAppInfo()
//            case .category(let category):
//                return CategoryAppInfo(category: category)
//            }
//        case .homebrew:
//            switch self.item {
//            case .top:
//                return HomebrewInventory.SourceInfo.TopAppInfo()
//            case .recent:
//                return HomebrewInventory.SourceInfo.RecentAppInfo()
//            case .sponsorable:
//                return HomebrewInventory.SourceInfo.SponsorableAppInfo()
//            case .installed:
//                return HomebrewInventory.SourceInfo.InstalledAppInfo()
//            case .updated:
//                return HomebrewInventory.SourceInfo.UpdatedAppInfo()
//            case .category(let category):
//                return CategoryAppInfo(category: category)
//            }
//        default:
//            return nil
//        }
//    }

    struct CategoryAppInfo : AppSourceInfo {
        let category: AppCategory

        func tintedLabel(monochrome: Bool) -> TintedLabel {
            category.tintedLabel(monochrome: monochrome)
        }

        /// Subtitle text for this source
        var fullTitle: Text {
            Text("Category: \(category.text)", bundle: .module, comment: "app category info: title pattern")
        }

        /// A textual description of this source
        var overviewText: [Text] {
            []
            // Text(wip("XXX"), bundle: .module, comment: "app category info: overview text")
        }

        var footerText: [Text] {
            []
            // Text(wip("XXX"), bundle: .module, comment: "homebrew recent apps info: overview text")
        }

        /// A list of the features of this source, which will be displayed as a bulleted list
        var featureInfo: [(FairSymbol, Text)] {
            []
        }
    }
}

// MARK: App Launch Privacy support

extension FairManager {
    static let appLaunchPrivacyToolName = "applaunchprivacy"

    /// The script that we will store in the Applications Script folder to block app launch snooping
    static let appLaunchPrivacyToolSource = Result {
        try Bundle.module.loadBundleResource(named: appLaunchPrivacyToolName + "/main.swift")
    }

    /// The executable that we will store in the Applications Script folder to block app launch snooping
    static let appLaunchPrivacyToolBinary = Result {
        try Bundle.module.loadBundleResource(named: appLaunchPrivacyToolName + ".b64")
    }

    /// The script that we will store in the Applications Script folder to block app launch snooping
    static let appLaunchPrivacyTool = Result {
        URL(string: appLaunchPrivacyToolName, relativeTo: try FileManager.default.url(for: .applicationScriptsDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
    }

    private func clearAppLaunchPrivacyObserver() {
        if let observer = self.appLaunchPrivacyDeactivator {
            // cancel the app exit observer
            NotificationCenter.default.removeObserver(observer)
            self.appLaunchPrivacyDeactivator = nil
        }
    }

    /// Disables App Launch Privacy mode
    func disableAppLaunchPrivacy() throws {
        if let appLaunchPrivacyTool = try Self.appLaunchPrivacyTool.get() {
            dbg("disabling app launch privacy")
            let unblock = try Process.exec(cmd: appLaunchPrivacyTool.path, "disable")
            dbg(unblock.exitCode == 0 ? "successfully" : "unsuccessfully", "disabled app launch privacy:", unblock.stdout, unblock.stderr)
            if unblock.exitCode == 0 {
                clearAppLaunchPrivacyObserver()
            }
        }
    }

    /// Invokes the block launch telemetry script if it is installed and enabled
    func enableAppLaunchPrivacy(duration timeInterval: TimeInterval? = nil) async throws {
        let duration = timeInterval ?? self.appLaunchPrivacyDuration

        guard let appLaunchPrivacyTool = try Self.appLaunchPrivacyTool.get() else {
            throw AppError(String(format: NSLocalizedString("Could not find %@", bundle: .module, comment: "error message when failed to find app launch privacy tool"), Self.appLaunchPrivacyToolName))
        }

        /// If we have launch telemetry blocking enabled, this will invoke the telemetry block script before executing the operation, and then disable it after the given time interval
        if FileManager.default.fileExists(atPath: appLaunchPrivacyTool.path) {
            dbg("invoking telemetry launch block script:", appLaunchPrivacyTool.path)
            let privacyEnabled = try Process.exec(cmd: appLaunchPrivacyTool.path, "enable")
            if privacyEnabled.exitCode != 0 {
                throw AppError(NSLocalizedString("Failed to block launch telemetry", bundle: .module, comment: "error message"), failureReason: (privacyEnabled.stdout + privacyEnabled.stderr).joined(separator: "\n"))
            }

            // clear any previous observer
            clearAppLaunchPrivacyObserver()

            let observer = NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { note in
                dbg("application exiting; disabling app launch privacy mode")
                try? self.disableAppLaunchPrivacy()
            }

            self.appLaunchPrivacyDeactivator = observer

            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                do {
                    if observer.isEqual(self.appLaunchPrivacyDeactivator) {
                        dbg("disabling app launch privacy")
                        try self.disableAppLaunchPrivacy()
                    } else {
                        dbg("app launch privacy timer marker became invalid; skipping disable")
                    }
                } catch {
                    dbg("error unblocking launch telemetry:", error)
                }
            }
        }
    }

    /// Saves the telemetry script to the user's application folder
    func saveAppLaunchPrivacyTool(source: Bool) throws -> URL {
        dbg("installing script")

        guard let scriptFile = try FairManager.appLaunchPrivacyTool.get() else {
            throw CocoaError(.fileNoSuchFile)
        }

        // clear any previous script if it exists
        try? FileManager.default.removeItem(at: scriptFile)

        if source {
            let swiftFile = scriptFile.appendingPathExtension("swift")
            dbg("writing source to file:", swiftFile.path)
            try Self.appLaunchPrivacyToolSource.get().write(to: swiftFile)
            return swiftFile
        } else {
            let executableFile = scriptFile
            dbg("writing binary to file:", executableFile.path)
            let encodedTool = try Self.appLaunchPrivacyToolBinary.get()
            guard let decodedTool = Data(base64Encoded: encodedTool, options: [.ignoreUnknownCharacters]) else {
                throw AppError(String(format: NSLocalizedString("Unable to decode %@", bundle: .module, comment: "error message"), Self.appLaunchPrivacyToolName))
            }
            try decodedTool.write(to: executableFile)
            return executableFile
        }
    }

    /// Installs a swift utility that will block telemetry. This needs to be a compiled program rather than a shell script, because we want to set the setuid bit on it to be able to invoke it without asking for the admin password every time.
    /// - Parameter compiler: the compiler to use to build the script (e.g., `"/usr/bin/swiftc"`), or `nil` to install the bundled binary directly
    func installAppLaunchPrivacyTool(compiler: String? = nil) async throws {
        let swiftFile = try saveAppLaunchPrivacyTool(source: true)
        let compiledOutput: URL

        if let compiler = compiler {
            compiledOutput = swiftFile.deletingPathExtension()

            let swiftCompilerInstalled = FileManager.default.isExecutableFile(atPath: compiler)

            if swiftCompilerInstalled {
                throw AppError(NSLocalizedString("Developer tools not found", bundle: .module, comment: "error message"), failureReason: NSLocalizedString("This operation requires that the swift compiler be installed on the host machine in order to build the necessary tools. Please install Xcode in order to enable telemetry blocking.", bundle: .module, comment: "error failure reason message"))
            }

            dbg("compiling script:", swiftFile.path, "to:", compiledOutput)

            let result = try Process.exec(cmd: "/usr/bin/swiftc", "-o", compiledOutput.path, target: swiftFile)
            if result.exitCode != 0 {
                throw AppError(String(format: NSLocalizedString("Error compiling %@", bundle: .module, comment: "error message"), Self.appLaunchPrivacyToolName), failureReason: (result.stdout + result.stderr).joined(separator: "\n"))
            }
        } else {
            compiledOutput = try saveAppLaunchPrivacyTool(source: false)
        }

        // set the root uid bit on the script so we can execute it without asking for the password each time
        let setuid = "/usr/sbin/chown root '\(compiledOutput.path)' && /bin/chmod 4750 '\(compiledOutput.path)'"
        let _ = try await NSUserScriptTask.fork(command: setuid, admin: true)
    }

    /// Invoked when the `appLaunchPrivacy` setting changes
    func handleChangeAppLaunchPrivacy(enabled: Bool) {
        Task {
            await self.trying {
                do {
                    if enabled == true {
                        try await self.installAppLaunchPrivacyTool()
                    } else {
                        if let script = try? Self.appLaunchPrivacyTool.get() {
                            if FileManager.default.fileExists(atPath: script.path) {
                                dbg("removing script at:", script.path)
                                try FileManager.default.removeItem(at: script)
                            }
                            if FileManager.default.fileExists(atPath: script.appendingPathExtension("swift").path) {
                                dbg("removing script at:", script.path)
                                try FileManager.default.removeItem(at: script.appendingPathExtension("swift"))
                            }
                        }
                    }
                } catch {
                    // any failure to install should disable the toggle
                    self.appLaunchPrivacy = false
                    throw error
                }
            }
        }
    }


    @ViewBuilder func launchPrivacyButton() -> some View {
        if self.appLaunchPrivacy == false {
        } else if self.appLaunchPrivacyDeactivator == nil {
            Text("Ready", bundle: .module, comment: "launch privacy activate toolbar button title when in the inactive state")
                .label(image: FairSymbol.shield_slash_fill.symbolRenderingMode(.hierarchical).foregroundStyle(Color.brown, Color.gray))
                .button {
                    await self.trying {
                        try await self.enableAppLaunchPrivacy()
                    }
                }
                .help(Text("App launch telemetry blocking is enabled but not currently active. It will automatically activate upon launching an app from the App Fair, or clicking this button will manually activate it and then deactivate in \(Text(duration: self.appLaunchPrivacyDuration))", bundle: .module, comment: "launch privacy activate toolbar button tooltip when in the inactive state"))
        } else {
            Text("Active", bundle: .module, comment: "launch privacy button toolbar button title when in the activate state")
                .label(image: FairSymbol.shield_fill.symbolRenderingMode(.hierarchical).foregroundStyle(Color.orange, Color.blue))
                .button {
                    await self.trying {
                        try self.disableAppLaunchPrivacy()
                    }
                }
                .help(Text("App Launch Privacy is currently active for \(Text(duration: self.appLaunchPrivacyDuration)). Click this button to deactivate privacy mode.", bundle: .module, comment: "launch privacy button toolbar button title when in the inactivate state"))
        }
    }
}


extension Error {
    /// Returns true if this error indicates that the user cancelled an operaiton
    var isURLCancelledError: Bool {
        (self as NSError).domain == NSURLErrorDomain && (self as NSError).code == -999
    }
}
