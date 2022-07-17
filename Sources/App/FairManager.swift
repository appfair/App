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
import FairExpo
import Combine

protocol FairManagerType {
}

@available(macOS 12.0, iOS 15.0, *)
@MainActor public final class FairManager: SceneManager, FairManagerType {
    @AppStorage("themeStyle") var themeStyle = ThemeStyle.system

    @AppStorage("firstLaunchV1") public var firstLaunchV1 = true

    @AppStorage("enableInstallWarning") public var enableInstallWarning = true
    @AppStorage("enableDeleteWarning") public var enableDeleteWarning = true
    @AppStorage("enableSponsorship") public var enableSponsorship = true

    /// The base domain of the provider for the hub
    @AppStorage("hubProvider") public var hubProvider = "github.com"
    /// The organization name of the hub
    @AppStorage("hubOrg") public var hubOrg = "appfair"
    /// The name of the base repository for the provider
    @AppStorage("hubRepo") public var hubRepo = "App"

    /// An optional authorization token for direct API usagefor the organization
    @AppStorage("hubToken") public var hubToken = ""

    /// Whether to try blocking launch telemetry reporting
    @AppStorage("appLaunchPrivacy") public var appLaunchPrivacy = false

    /// The duration to continue blocking launch telemtry after an app has been launched (since the OS retries for a certain amount of time if the initial connection fails)
    @AppStorage("appLaunchPrivacyDuration") public var appLaunchPrivacyDuration: TimeInterval = 60.0

    /// Whether links clicked in the embedded browser should open in a new browser window
    @AppStorage("openLinksInNewBrowser") var openLinksInNewBrowser = true

    /// Whether the embedded browser should use private browsing mode for untrusted sites
    @AppStorage("usePrivateBrowsingMode") var usePrivateBrowsingMode = true

    /// The inventories that are currently available
    @Published var inventories: [AppSource: AppInventory] = [:]

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

    private var observers: [AnyCancellable] = []

    required internal init() {
        super.init()

        for source in self.appSources {
            switch source {
            case .homebrew:
                self.addInventory(source: source, HomebrewInventory.default)
            case .appSourceFairgroundMacOS:
                self.addInventory(source: source, AppSourceInventory.macOSInventory)
            case .appSourceFairgroundiOS:
                self.addInventory(source: source, AppSourceInventory.iOSInventory)
            default:
                continue
            }
        }

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

    func addInventory(source: AppSource, _ inventory: AppInventory) {
        self.inventories[source] = inventory
        // track any changes to the inventory and broadcast their changes
        self.observers.append(inventory.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        })
    }

    /// The list of sources as presented in the user interface
    ///
    /// - TODO: @available(*, deprecated, message: "use persistent list")
    var appSources: [AppSource] {
        // return inventories.keys.array() // randomly ordered

        return [
            .homebrew,
            .appSourceFairgroundMacOS,
            //wip(.appSourceFairgroundiOS),
        ]
    }

    /// The appManager, which should be extracted as a separate `EnvironmentObject`
    /// - TODO: @available(*, deprecated, message: "use inventories[.fairapps]")
    var fairAppInv: AppSourceInventory? {
        inventories[.appSourceFairgroundMacOS] as? AppSourceInventory
    }

    /// The appManager, which should be extracted as a separate `EnvironmentObject`
    /// - TODO: @available(*, deprecated, message: "use inventories[.fairapps]")
    var fairAppiOSInv: AppSourceInventory? {
        inventories[.appSourceFairgroundiOS] as? AppSourceInventory
    }

    /// The caskManager, which should be extracted as a separate `EnvironmentObject`
    /// - TODO: @available(*, deprecated, message: "use inventories[.homebrew]")
    var homeBrewInv: HomebrewInventory? {
        inventories[.homebrew] as? HomebrewInventory
    }

    func inventory(for source: AppSource) -> AppInventory? {
        switch source {
        case .homebrew: return homeBrewInv
        case .appSourceFairgroundMacOS: return fairAppInv
        case .appSourceFairgroundiOS: return fairAppiOSInv
        default: return nil
        }
    }

    func arrangedItems(source: AppSource, sidebarSelection: SidebarSelection?, sortOrder: [KeyPathComparator<AppInfo>], searchText: String) -> [AppInfo] {
        self.inventory(for: source)?.arrangedItems(sidebarSelection: sidebarSelection, sortOrder: sortOrder, searchText: searchText) ?? []
    }

    func badgeCount(for item: SidebarSelection) -> Text? {
        inventory(for: item.source)?.badgeCount(for: item.item)
    }

    /// Returns true is there are any refreshes in progress
    var refreshing: Bool {
        self.inventories.values.contains { $0.updateInProgress > 0 }
    }

    func refresh(clearCatalog: Bool) async throws {
        for catalog in self.inventories.values {
            try await catalog.refreshAll(clearCatalog: clearCatalog)
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
        inventories.values.map({ $0.updateCount() }).reduce(0, { $0 + $1 })
    }

    /// The view that will summarize the app source in the detail panel when no app is selected.
    func sourceOverviewView(selection: SidebarSelection, showText: Bool, showFooter: Bool) -> some View {
        let info = sourceInfo(for: selection)
        let label = info?.label
        let color = label?.tint ?? .accentColor

        return VStack(spacing: 0) {
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

            if showText, let info = info, let overview = info.overviewText {
                ScrollView {
                    overview.joined(separator: Text(verbatim: "\n\n"))
                            .font(Font.title2)
                            .padding()
                            .padding()
                }
                     .textSelection(.enabled) // bug: sometimes selecting will unwraps and converts to a single line
            }

            if showFooter, let info = info {
                Spacer()
                ForEach(enumerated: info.footerText) { _, footerText in
                    footerText
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
    @ViewBuilder func iconView(for info: AppInfo, source: AppSource, transition: Bool = false) -> some View {
        Group {
            //inventory(for: source)?.iconImage(item: info)
            if info.isCask == true {
                homeBrewInv?.icon(for: info, useInstalledIcon: false)
            } else {
                fairAppInv?.iconImage(item: info)
            }
        }
        //.transition(AnyTransition.scale(scale: 0.50).combined(with: .opacity)) // bounce & fade in the icon
        .transition(transition == false ? AnyTransition.opacity : AnyTransition.asymmetric(insertion: AnyTransition.opacity, removal: AnyTransition.scale(scale: 0.75).combined(with: AnyTransition.opacity))) // skrink and fade out the placeholder while fading in the actual icon

    }

    func launch(_ info: AppInfo) async {
        await self.trying {
            if self.appLaunchPrivacy {
                try await self.enableAppLaunchPrivacy()
            }

            if info.isCask == true {
                try await homeBrewInv?.launch(item: info)
            } else {
                try await fairAppInv?.launch(item: info)
            }
        }
    }

    func install(_ info: AppInfo, source: AppSource, progress parentProgress: Progress?, manageDownloads: Bool? = nil, update: Bool = true, verbose: Bool = true) async {
        await self.trying {
            if info.isCask {
                try await homeBrewInv?.install(item: info, progress: parentProgress, update: update, verbose: verbose)
            } else {
                try await fairAppInv?.install(item: info, progress: parentProgress, update: update, verbose: verbose)
            }
            sessionInstalls.insert(info.id)
        }
    }

    func reveal(_ item: AppInfo) async {
        await self.trying {
            if item.isCask {
                try await homeBrewInv?.reveal(item: item)
            } else {
                try await fairAppInv?.reveal(item: item)
            }
        }
    }

    func installedVersion(for item: AppInfo) -> String? {
        if item.isCask {
            return homeBrewInv?.appInstalled(item: item)
        } else {
            return fairAppInv?.appInstalled(item: item)
        }
    }

    func appUpdated(for item: AppInfo) -> Bool {
        if item.isCask {
            return homeBrewInv?.appUpdated(item: item) == true
        } else {
            return fairAppInv?.appUpdated(item: item) == true
        }
    }
}

extension FairManagerType {
    func sourceInfo(for selection: SidebarSelection) -> AppSourceInfo? {
        switch selection.source {
        case .appSourceFairgroundMacOS:
            switch selection.item {
            case .top:
                return AppSourceInventory.SourceInfo.TopAppInfo()
            case .recent:
                return AppSourceInventory.SourceInfo.RecentAppInfo()
            case .installed:
                return AppSourceInventory.SourceInfo.InstalledAppInfo()
            case .sponsorable:
                return AppSourceInventory.SourceInfo.SponsorableAppInfo()
            case .updated:
                return AppSourceInventory.SourceInfo.UpdatedAppInfo()
            case .category(let category):
                return CategoryAppInfo(category: category)
            }
        case .homebrew:
            switch selection.item {
            case .top:
                return HomebrewInventory.SourceInfo.TopAppInfo()
            case .recent:
                return HomebrewInventory.SourceInfo.RecentAppInfo()
            case .sponsorable:
                return HomebrewInventory.SourceInfo.SponsorableAppInfo()
            case .installed:
                return HomebrewInventory.SourceInfo.InstalledAppInfo()
            case .updated:
                return HomebrewInventory.SourceInfo.UpdatedAppInfo()
            case .category(let category):
                return CategoryAppInfo(category: category)
            }
        default:
            return nil
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
            throw AppError("Could not find \(Self.appLaunchPrivacyToolName)")
        }

        /// If we have launch telemetry blocking enabled, this will invoke the telemetry block script before executing the operation, and then disable it after the given time interval
        if FileManager.default.fileExists(atPath: appLaunchPrivacyTool.path) {
            dbg("invoking telemetry launch block script:", appLaunchPrivacyTool.path)
            let privacyEnabled = try Process.exec(cmd: appLaunchPrivacyTool.path, "enable")
            if privacyEnabled.exitCode != 0 {
                throw AppError("Failed to block launch telemetry", failureReason: (privacyEnabled.stdout + privacyEnabled.stderr).joined(separator: "\n"))
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
                throw AppError("Unable to decode \(Self.appLaunchPrivacyToolName)")
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
                throw AppError("Developer tools not found", failureReason: "This operation requires that the swift compiler be installed on the host machine in order to build the necessary tools. Please install Xcode in order to enable telemetry blocking.")
            }

            dbg("compiling script:", swiftFile.path, "to:", compiledOutput)

            let result = try Process.exec(cmd: "/usr/bin/swiftc", "-o", compiledOutput.path, target: swiftFile)
            if result.exitCode != 0 {
                throw AppError("Error compiling \(Self.appLaunchPrivacyToolName)", failureReason: (result.stdout + result.stderr).joined(separator: "\n"))
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
