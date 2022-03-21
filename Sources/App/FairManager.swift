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
                homeBrewInv.icon(for: info.release, useInstalledIcon: false)
            } else {
                info.release.iconImage()
            }
        }
        //.transition(AnyTransition.scale(scale: 0.50).combined(with: .opacity)) // bounce & fade in the icon
        .transition(transition == false ? AnyTransition.opacity : AnyTransition.asymmetric(insertion: AnyTransition.opacity, removal: AnyTransition.scale(scale: 0.75).combined(with: AnyTransition.opacity))) // skrink and fade out the placeholder while fading in the actual icon

    }
}

extension Error {
    /// Returns true if this error indicates that the user cancelled an operaiton
    var isURLCancelledError: Bool {
        (self as NSError).domain == NSURLErrorDomain && (self as NSError).code == -999
    }
}
