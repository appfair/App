import FairApp

@available(macOS 12.0, iOS 15.0, *)
@MainActor public final class FairManager: SceneManager {
    /// The appManager, which should be extracted as a separate `EnvironmentObject`
    let fairAppInv: FairAppInventory
    /// The caskManager, which should be extracted as a separate `EnvironmentObject`
    let homeBrewInv: HomebrewInventory

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

    /// Whether to try blocking launch telemetry reporting
    @AppStorage("blockLaunchTelemetry") public var blockLaunchTelemetry = false

    /// The apps that have been installed or updated in this session
    @Published var sessionInstalls: Set<AppInfo.ID> = []


    required internal init() {
        self.fairAppInv = FairAppInventory()
        self.homeBrewInv = HomebrewInventory()
        
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

    /// The icon for the given item
    /// - Parameters:
    ///   - info: the info to check
    ///   - transition: whether to use a fancy transition
    /// - Returns: the icon
    @ViewBuilder func iconView(for info: AppInfo, transition: Bool = false) -> some View {
        Group {
            if info.isCask == true {
                homeBrewInv.icon(for: info, useInstalledIcon: false)
            } else {
                info.catalogMetadata.iconImage()
            }
        }
        //.transition(AnyTransition.scale(scale: 0.50).combined(with: .opacity)) // bounce & fade in the icon
        .transition(transition == false ? AnyTransition.opacity : AnyTransition.asymmetric(insertion: AnyTransition.opacity, removal: AnyTransition.scale(scale: 0.75).combined(with: AnyTransition.opacity))) // skrink and fade out the placeholder while fading in the actual icon

    }

    /// The number of times we have blocked launch telemetry
    private var launchTelemetryBlockCount = 0

    func launch(_ info: AppInfo) async {
        await self.trying {
            try await blockLaunchTelemetry(duration: 30.0)

            if info.isCask == true {
                try await homeBrewInv.launch(item: info)
            } else {
                await fairAppInv.launch(item: info.catalogMetadata)
            }
        }
    }

    func install(_ info: AppInfo, progress parentProgress: Progress?, manageDownloads: Bool? = nil, update: Bool = true, verbose: Bool = true) async {
        await self.trying {
            if info.isCask {
                try await homeBrewInv.install(item: info, progress: parentProgress, update: update)
            } else {
                try await fairAppInv.install(item: info.catalogMetadata, progress: parentProgress, update: update)
            }
            sessionInstalls.insert(info.id)
        }
    }

}

// MARK: telemetry blocking

extension FairManager {

    /// The script that we will store in the Applications Script folder to block app launch snooping
    static let blockLaunchTelemetryScript = Result {
        URL(string: "snoopblock", relativeTo: try FileManager.default.url(for: .applicationScriptsDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
    }

    /// Invokes the block launch telemetry script if it is installed and enabled
    private func blockLaunchTelemetry(duration: TimeInterval) async throws {
        /// If we have launch telemetry blocking enabled, this will invoke the telemetry block script before executing the operation, and then disable it after the given time interval
        if blockLaunchTelemetry,
            let blockScript = try? Self.blockLaunchTelemetryScript.get(),
            FileManager.default.fileExists(atPath: blockScript.path) {
            dbg("invoking telemetry launch block script:", blockScript.path)
            let blocked = try Process.exec(cmd: blockScript.path, "block")
            if blocked.exitCode != 0 {
                throw AppError("Failed to block launch telemetry", failureReason: (blocked.stdout + blocked.stderr).joined(separator: "\n"))
            }

            launchTelemetryBlockCount += 1

            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                do {
                    // handle the case where multiple apps have been launched within the given window
                    self.launchTelemetryBlockCount -= 1
                    if self.launchTelemetryBlockCount <= 0 {
                        dbg("unblocking launch telemetry")
                        let unblock = try Process.exec(cmd: blockScript.path, "unblock")
                        dbg(unblock.exitCode == 0 ? "successfully" : "unsuccessfully", "unblocked launch telemetry:", unblock.stdout, unblock.stderr)
                    }
                } catch {
                    dbg("error unblocking launch telemetry:", error)
                }
            }

            // also flush the DNS cache to ensure that the OCSP address is not cached
            let _ = try Process.exec(cmd: "/usr/bin/dscacheutil", "-flushcache")
        }
    }


    /// Compiles a swift utility that will block telemetry. This needs to be a compiled program rather than a shell script, because we want to set the setuid bit on it to be able to invoke it without asking for the admin password every time.
    func installTelemetryBlocker() async throws {
        dbg("installing script")

        guard let scriptFile = try FairManager.blockLaunchTelemetryScript.get() else {
            throw CocoaError(.fileNoSuchFile)
        }

        if !FileManager.default.isExecutableFile(atPath: "/usr/bin/swiftc") {
            throw AppError("Developer tools not found", failureReason: "This operation requires that the swift compiler be installed on the host machine in order to build the necessary tools. Please install Xcode in order to enable telemetry blocking.")
        }


        // clear any previous script if it exists
        try? FileManager.default.removeItem(at: scriptFile)

        let swiftFile = scriptFile.appendingPathExtension("swift")

        dbg("writing to file:", swiftFile.path)
        try Self.telemetryBlockScript.write(to: swiftFile, atomically: true, encoding: .utf8)
        dbg("compiling script:", swiftFile.path)
        let result = try Process.exec(cmd: "/usr/bin/swiftc", "-o", scriptFile.path, target: swiftFile)
        if result.exitCode != 0 {
            throw AppError("Error compiling snoopblock.swift", failureReason: (result.stdout + result.stderr).joined(separator: "\n"))
        }

        // set the root uid bit on the script so we can execute it without asking for the password each time
        let setuid = "chown root '\(scriptFile.path)' && chmod 4755 '\(scriptFile.path)'"
        let _ = try await NSUserScriptTask.fork(command: setuid, admin: true)


    }

    /// The script that we compile to a helper utility in order to run to block app telemetry reporting when launching apps
    private static let telemetryBlockScript = #"""
import Foundation

let flag = CommandLine.arguments.dropFirst().first

let blockString = """

# begin launch telemetry blocking
127.0.0.1 ocsp.apple.com
127.0.0.1 ocsp2.apple.com
# end launch telemetry blocking

"""

var hostsContent = try String(contentsOfFile: "/etc/hosts", encoding: .utf8)
if flag == "block" {
    hostsContent.append(contentsOf: blockString)
} else if flag == "unblock" {
    hostsContent = hostsContent.replacingOccurrences(of: blockString, with: "")
} else {
    struct BadArgument : LocalizedError {
        let failureReason: String? = "argument must be block or unblock"
    }
    throw BadArgument()
}

try hostsContent.write(toFile: "/etc/hosts", atomically: true, encoding: .utf8)

"""#

}


extension Error {
    /// Returns true if this error indicates that the user cancelled an operaiton
    var isURLCancelledError: Bool {
        (self as NSError).domain == NSURLErrorDomain && (self as NSError).code == -999
    }
}
