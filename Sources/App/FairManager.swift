import FairApp

@available(macOS 12.0, iOS 15.0, *)
@MainActor public final class FairManager: SceneManager {
    /// The appManager, which should be extracted as a separate `EnvironmentObject`
    let appManager = AppManager()
    /// The caskManager, which should be extracted as a separate `EnvironmentObject`
    let caskManager = CaskManager()

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
        async let v0: () = appManager.scanInstalledApps()
        async let v1: () = appManager.fetchApps(cache: .reloadIgnoringLocalAndRemoteCacheData)
        async let v2: () = caskManager.refreshAll()
        let _ = try await (v0, v1, v2) // perform the two refreshes in tandem
    }

    /// Attempts to perform the given action and adds any errors to the error list if they fail.
    func trying(block: () async throws -> ()) async {
        do {
            try await block()
        } catch {
            appManager.errors.append(error as? AppError ?? AppError(error))
        }
    }

    func updateCount() -> Int {
        return appManager.updateCount()
            + (caskManager.enableHomebrew ? caskManager.updateCount() : 0)
    }
}

