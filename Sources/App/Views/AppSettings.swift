import FairKit

@available(macOS 12.0, iOS 15.0, *)
public struct AppSettingsView: View {
    public enum Tabs: Hashable {
        case general
        case fairapps
        case homebrew
        case privacy
        case advanced
    }

    public var body: some View {
        TabView {
            GeneralSettingsView()
                .padding(20)
                .tabItem {
                    Text("General", bundle: .module, comment: "general preferences tab title")
                        .label(image: FairSymbol.switch_2)
                        .symbolVariant(.fill)
                }
                .tag(Tabs.general)
            FairAppsSettingsView()
                .padding(20)
                .tabItem {
                    Text("Fairapps", bundle: .module, comment: "fairapps preferences tab title")
                        .label(image: AppSource.fairapps.symbol)
                        .symbolVariant(.fill)
                }
                .tag(Tabs.general)
            HomebrewSettingsView()
                .padding(20)
                .tabItem {
                    Text("Homebrew", bundle: .module, comment: "homebrew preferences tab title")
                        .label(image: AppSource.homebrew.symbol)
                        .symbolVariant(.fill)
                }
                .tag(Tabs.general)
            PrivacySettingsView()
                .padding(20)
                .tabItem {
                    Text("Privacy", bundle: .module, comment: "privacy preferences tab title")
                        .label(image: FairSymbol.hand_raised)
                        .symbolVariant(.fill)
                }
                .tag(Tabs.privacy)
            AdvancedSettingsView()
                .padding(20)
                .tabItem {
                    Text("Advanced", bundle: .module, comment: "advanced preferences tab title")
                        .label(image: FairSymbol.gearshape)
                        .symbolVariant(.fill)
                }
                .tag(Tabs.advanced)
        }
        .padding(20)
        .frame(width: 600)
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct HomebrewSettingsView: View {
    @EnvironmentObject var fairManager: FairManager

    @State private var homebrewOperationInProgress = false
    @State private var homebrewInstalled: Bool? = nil

    var body: some View {
        settingsForm
            .task {
                self.homebrewInstalled = fairManager.homeBrewInv.isHomebrewInstalled()
            }
    }

    var settingsForm: some View {
        VStack {
            Form {
                HStack {
                    Toggle(isOn: $fairManager.homeBrewInv.enableHomebrew) {
                        Text("Homebrew Casks", bundle: .module, comment: "settings switch title for enabling homebrew cask support")
                    }
                    .onChange(of: fairManager.homeBrewInv.enableHomebrew) { enabled in
                        if wip(false) && (enabled == false) { // un-installing also removes all the casks, and so re-installation won't know about existing apps; disable this behavior until we can find a different location for the Caskroom (and support migration from older clients)
                            // un-install the local homebrew cache if we ever disable it; this makes it so we don't need a local cache location
                            Task {
                                try await fairManager.homeBrewInv.uninstallHomebrew()
                                self.homebrewInstalled = fairManager.homeBrewInv.isHomebrewInstalled()
                            }
                        }
                    }
                }
                .toggleStyle(.switch)
                .help(Text("Adds homebrew Casks to the sources of available apps.", bundle: .module, comment: "tooltip text for switch to enable homebrew support"))

                Group {
                    Group {
                        Toggle(isOn: $fairManager.homeBrewInv.manageCaskDownloads) {
                            Text("Use integrated download manager", bundle: .module, comment: "homebrew preference checkbox for enabling the integrated download manager")
                        }
                            .help(Text("Whether to use the built-in download manager to handle downloading and previewing Cask artifacts. This will permit Cask installation to be monitored and cancelled from within the app. Disabling this preference will cause brew to use curl for downloading, which will not report progress in the user-interface.", bundle: .module, comment: "tooltip help text for preference to enable integrated download homebrew download manager"))

                        Toggle(isOn: $fairManager.homeBrewInv.forceInstallCasks) {
                            Text("Install overwrites previous app installation", bundle: .module, comment: "homebrew preference checkbox")
                        }
                            .help(Text("Whether to overwrite a prior installation of a given Cask. This could cause a newer version of an app to be overwritten by an earlier version.", bundle: .module, comment: "tooltip help text for preference"))

                        Toggle(isOn: $fairManager.homeBrewInv.quarantineCasks) {
                            Text("Quarantine installed apps", bundle: .module, comment: "homebrew preference checkbox")
                        }
                            .help(Text("Marks apps installed with homebrew cask as being quarantined, which will cause a system gatekeeper check and user confirmation the first time they are run.", bundle: .module, comment: "tooltip help text for homebrew preference checkbox"))

                        Toggle(isOn: $fairManager.homeBrewInv.permitGatekeeperBypass) {
                            Text("Permit gatekeeper bypass", bundle: .module, comment: "tooltip help text for homebrew preference")
                        }
                            .help(Text("Allows the launching of quarantined apps that are not signed and notarized. This will prompt the user for confirmation each time an app identified as not being signed before it will be launched.", bundle: .module, comment: "tooltip help text for homebrew preference"))

                        Toggle(isOn: $fairManager.homeBrewInv.installDependencies) {
                            Text("Automatically install dependencies", bundle: .module, comment: "homebrew preference checkbox")
                        }
                            .help(Text("Automatically attempt to install any required dependencies for a cask.", bundle: .module, comment: "homebrew preference checkbox tooltip"))

                        Toggle(isOn: $fairManager.homeBrewInv.ignoreAutoUpdatingAppUpdates) {
                            Text("Exclude auto-updating apps from updates list", bundle: .module, comment: "homebrew preference checkbox")
                        }
                            .help(Text("If a cask marks itself as handling its own software updates internally, exclude the cask from showing up in the “Updated” section. This can help avoid showing redundant updates for apps that expect to be able to update themselves, but can also lead to these apps being stale when they are next launched.", bundle: .module, comment: "homebrew preference checkbox tooltip"))

                        Toggle(isOn: $fairManager.homeBrewInv.zapDeletedCasks) {
                            Text("Clear all app info on delete", bundle: .module, comment: "homebrew preference checkbox")
                        }
                            .help(Text("When deleting apps, also try to delete all the info stored by the app, including preferences, user data, and other info. This operation is known as “zapping” the app, and it will attempt to purge all traces of the app from your system, with the possible side-effect of also removing infomation that could be useful if you were to ever re-install the app.", bundle: .module, comment: "homebrew preference checkbox tooltip"))
                    }

                    Group {

                        Toggle(isOn: $fairManager.homeBrewInv.allowCasksWithoutApp) {
                            Text("Show casks without app artifacts", bundle: .module, comment: "homebrew preference checkbox")
                                //.label(.bolt)
                        }
                            .help(Text("This permits the installation of apps that don't list any launchable artifacts with an .app extension. Such apps will not be able to be launched directly from the App Fair app, but they may exist as system extensions or launch services.", bundle: .module, comment: "homebrew preference checkbox tooltip"))

                        Toggle(isOn: $fairManager.homeBrewInv.requireCaskChecksum) {
                            Text("Require cask checksum", bundle: .module, comment: "homebrew preference checkbox")
                        }
                            .help(Text("Requires that downloaded artifacts have an associated SHA-256 cryptographic checksum to verify that they match the version that was added to the catalog. This help ensure the integrity of the download, but may exclude some casks that do not publish their checksums, and so is disabled by default.", bundle: .module, comment: "homebrew preference checkbox tooltip"))

                        Toggle(isOn: $fairManager.homeBrewInv.enableBrewSelfUpdate) {
                            Text("Enable Homebrew self-update", bundle: .module, comment: "homebrew preference checkbox")
                        }
                            .help(Text("Allow Homebrew to update itself while installing other packages.", bundle: .module, comment: "homebrew preference checkbox tooltip"))

                        // switching between the system-installed brew and locally cached brew doesn't yet work
                        #if DEBUG
                        #if false
                        Toggle(isOn: $fairManager.homeBrewInv.useSystemHomebrew) {
                            Text("Use system Homebrew installation", bundle: .module, comment: "homebrew preference checkbox")
                        }
                            .help(Text("Use the system-installed Homebrew installation", bundle: .module, comment: "homebrew preference checkbox tooltip"))
                            .disabled(!HomebrewInventory.globalBrewInstalled)
                        #endif
                        Toggle(isOn: $fairManager.homeBrewInv.enableBrewAnalytics) {
                            Text("Enable installation telemetry", bundle: .module, comment: "homebrew preference checkbox")
                        }
                            .help(Text("Permit Homebrew to send telemetry to Google about the packages you install and update. See https://docs.brew.sh/Analytics", bundle: .module, comment: "homebrew preference checkbox tooltip"))
                        #endif
                    }
                    .disabled(fairManager.homeBrewInv.enableHomebrew == false)
                }
            }

            Divider()

            Section {
                GroupBox {
                    VStack {
                        Text("""
                            Homebrew is a repository of third-party applications and installers called “Casks”. These packages are installed and managed using the `brew` command and are typically placed in the `/Applications/` folder.

                            Homebrew Casks are not subject to the same sandboxing, entitlement disclosure, and source transparency requirements as App Fair fair-ground apps, and so should only be installed from trusted sources.

                            Read more at: [https://brew.sh](https://brew.sh)
                            Browse all Casks: [https://formulae.brew.sh/cask/](https://formulae.brew.sh/cask/)
                            Location: \((fairManager.homeBrewInv.brewInstallRoot.path as NSString).abbreviatingWithTildeInPath)
                            Installed: \(isBrewInstalled ? "yes" : "no")
                            """, bundle: .module, comment: "homebrew preference description")
                            // .textSelection(.enabled) // bug that causes lines to stop wrapping when text is selected
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .controlSize(.small)
                                .frame(height: 12)
                                .opacity(homebrewOperationInProgress ? 1.0 : 0.0)
                            Text("Reveal", bundle: .module, comment: "homebrew preference button for showing locating of homebrew installation")
                                .button {
                                    NSWorkspace.shared.activateFileViewerSelecting([fairManager.homeBrewInv.brewInstallRoot.absoluteURL]) // else: “NSURLs written to the pasteboard via NSPasteboardWriting must be absolute URLs.  NSURL 'Homebrew/ -- file:///Users/home/Library/Application Support/app.App-Fair/appfair-homebrew/' is not an absolute URL”
                                }
                                .disabled(isBrewInstalled == false)
                                .help(Text("Browse the Homebrew installation folder using the Finder", bundle: .module, comment: "homebrew preference button tooltip"))

                            #if DEBUG

                            if isBrewInstalled {
                                Text("Reset Homebrew", bundle: .module, comment: "button text on Homebrew preferences for resetting the Homebrew installation")
                                    .button {
                                        homebrewOperationInProgress = true
                                        do {
                                            try await fairManager.homeBrewInv.uninstallHomebrew()
                                            dbg("caskManager.uninstallHomebrew success")
                                            self.homebrewInstalled = fairManager.homeBrewInv.isHomebrewInstalled()
                                        } catch {
                                            self.fairManager.fairAppInv.reportError(error)
                                        }
                                        self.homebrewOperationInProgress = false
                                    }
                                    .disabled(self.homebrewOperationInProgress)
                                    .help(Text("This will remove the version of Homebrew that is used locally by the App Fair. It will not affect any system-level Homebrew installation that may be present elsewhere. Homebrew can be re-installed again afterwards.", bundle: .module, comment: "tooltip text for button to uninstall homebrew on brew preferences panel"))
                                    .padding()
                            } else {
                                Text("Setup Homebrew", bundle: .module, comment: "button text on Homebrew preferences for installing Homebrew")
                                    .button {
                                        homebrewOperationInProgress = true
                                        do {
                                            try await fairManager.homeBrewInv.installHomebrew(retainCasks: false)
                                            dbg("caskManager.installHomebrew success")
                                            self.homebrewInstalled = fairManager.homeBrewInv.isHomebrewInstalled()
                                        } catch {
                                            self.fairManager.fairAppInv.reportError(error)
                                        }
                                        self.homebrewOperationInProgress = false
                                    }
                                    .disabled(self.homebrewOperationInProgress)
                                    .help(Text("Download homebrew and set it up for use by the App Fair. It will be installed locally to the App Fair and will not affect any other version that may be installed on the system. This operation will be performed automatically if any cask is installed and there is no local version of Homebrew found on the system.", bundle: .module, comment: "tooltip text for button to install homebrew on brew preferences panel"))
                                    .padding()

                            }
                            #endif
                        }
                    }
                    .frame(maxWidth: .infinity)
                } label: {
                    Text("About Homebrew Casks", bundle: .module, comment: "homebrew preference group box title")
                        .font(.headline)
                }
            }
        }
    }

    var isBrewInstalled: Bool {
        // override locally so we can control state
        if let homebrewInstalled = homebrewInstalled {
            return homebrewInstalled
        }
        return fairManager.homeBrewInv.isHomebrewInstalled()
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct FairAppsSettingsView: View {
    @EnvironmentObject var fairManager: FairManager

    @State var hoverRisk: AppRisk? = nil

    var body: some View {
        Form {
            HStack(alignment: .top) {
                AppRiskPicker(risk: $fairManager.fairAppInv.riskFilter, hoverRisk: $hoverRisk)
                (hoverRisk ?? fairManager.fairAppInv.riskFilter).riskSummaryText(bold: true)
                    .textSelection(.enabled)
                    .font(.body)
                    .frame(height: 150, alignment: .top)
                    .frame(maxWidth: .infinity)
            }

            Toggle(isOn: $fairManager.fairAppInv.showPreReleases) {
                Text("Show Pre-Releases", bundle: .module, comment: "fairapps preference checkbox")
            }
                .help(Text("Display releases that are not yet production-ready according to the developer's standards.", bundle: .module, comment: "fairapps preference checkbox tooltip"))

            Text("Pre-releases are experimental versions of software that are less tested than stable versions. They are generally released to garner user feedback and assistance, and so should only be installed by those willing experiment.", bundle: .module, comment: "fairapps preference description")
                .font(.body)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

        }
    }
}



@available(macOS 12.0, iOS 15.0, *)
struct GeneralSettingsView: View {
    @AppStorage("themeStyle") private var themeStyle = ThemeStyle.system
    @AppStorage("iconBadge") private var iconBadge = true

    var body: some View {
        Form {
            ThemeStylePicker(style: $themeStyle)

            Divider()

            Toggle(isOn: $iconBadge) {
                Text("Badge App Icon with update count", bundle: .module, comment: "fairapps preference checkbox")
            }
                .help(Text("Show the number of updates that are available to install.", bundle: .module, comment: "fairapps preference checkbox tooltip"))
        }
    }
}


/// The preferred theme style for the app
public enum ThemeStyle: String, CaseIterable {
    case system
    case light
    case dark
}

extension ThemeStyle : Identifiable {
    public var id: Self { self }

    public var label: Text {
        switch self {
        case .system: return Text("System", bundle: .module, comment: "general preference for theme style in popup menu")
        case .light: return Text("Light", bundle: .module, comment: "general preference for theme style in popup menu")
        case .dark: return Text("Dark", bundle: .module, comment: "general preference for theme style in popup menu")
        }
    }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}


@available(macOS 12.0, iOS 15.0, *)
struct ThemeStylePicker: View {
    @Binding var style: ThemeStyle

    var body: some View {
        Picker(selection: $style) {
            ForEach(ThemeStyle.allCases) { themeStyle in
                themeStyle.label
            }
        } label: {
            Text("Theme:", bundle: .module, comment: "picker title for general preference for theme style")
        }
        .radioPickerStyle()
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct AppRiskPicker: View {
    @Binding var risk: AppRisk
    @Binding var hoverRisk: AppRisk?

    var body: some View {
        Picker(selection: $risk) {
            ForEach(AppRisk.allCases) { appRisk in
                appRisk.riskLabel()
                    .brightness(hoverRisk == appRisk ? 0.2 : 0.0)
                    .onHover {
                        self.hoverRisk = $0 ? appRisk : nil
                    }
            }
        } label: {
            Text("Risk Exposure:", bundle: .module, comment: "fairapps preference title for risk management")
        }
        .radioPickerStyle()
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct AdvancedSettingsView: View {
    @EnvironmentObject var fairManager: FairManager

    func checkButton(_ parts: String...) -> some View {
        EmptyView()
//        Group {
//            Image(systemName: "checkmark.square.fill").aspectRatio(contentMode: .fit).foregroundColor(.green)
//            Image(systemName: "xmark.square.fill").aspectRatio(contentMode: .fit).foregroundColor(.red)
//        }
    }

    var body: some View {
        VStack {
            Form {
                Group {
                    Toggle(isOn: $fairManager.fairAppInv.relaunchUpdatedApps) {
                        Text("Re-launch updated apps", bundle: .module, comment: "preference checkbox")
                    }
                        .help(Text("Automatically re-launch an app when it has been updated. Otherwise, the updated version will be used after quitting and re-starting the app.", bundle: .module, comment: "preference checkbox tooltip"))

                    Toggle(isOn: $fairManager.fairAppInv.autoUpdateCatalogApp) {
                        Text("Keep catalog app up to date", bundle: .module, comment: "preference checkbox")
                    }
                    .help(Text("Automatically download and apply updates to the App Fair catalog browser app.", bundle: .module, comment: "preference checkbox tooltip"))
                    .toggleStyle(.checkbox)

                    Toggle(isOn: $fairManager.enableInstallWarning) {
                        Text("Require app install confirmation", bundle: .module, comment: "preference checkbox")
                    }
                    .help(Text("Installing an app will present a confirmation alert to the user. If disabled, apps will be installed and updated without confirmation.", bundle: .module, comment: "preference checkbox tooltip"))
                    .toggleStyle(.checkbox)

                    Toggle(isOn: $fairManager.enableDeleteWarning) {
                        Text("Require app delete confirmation", bundle: .module, comment: "preference checkbox")
                    }
                    .help(Text("Deleting an app will present a confirmation alert to the user. If disabled, apps will be deleted without confirmation.", bundle: .module, comment: "preference checkbox tooltip"))
                    .toggleStyle(.checkbox)
                }

                Divider()

                Text("Clear caches", bundle: .module, comment: "button label for option to clear local cache data in the app settings")
                    .button {
                        URLCache.shared.removeAllCachedResponses()
                    }
                    .help(Text("Purges the local cache of icons and app descriptions", bundle: .module, comment: "button help text for option to clear local cache data in the app settings"))

                Group {
                    HStack {
                        TextField(text: fairManager.$hubProvider) {
                            Text("Hub Host", bundle: .module, comment: "advanced preference text field label for the GitHub host")
                        }
                        checkButton(fairManager.hubProvider)
                    }
                    HStack {
                        TextField(text: fairManager.$hubOrg) {
                            Text("Organization", bundle: .module, comment: "advanced preference text field label for the GitHub organization")
                        }
                        checkButton(fairManager.hubProvider, fairManager.hubOrg)
                    }
                    HStack {
                        TextField(text: fairManager.$hubRepo) {
                            Text("Repository", bundle: .module, comment: "advanced preference text field label for the GitHub repository")
                        }
                        checkButton(fairManager.hubProvider, fairManager.hubOrg, fairManager.hubRepo)
                    }
    //                HStack {
    //                    SecureField("Token", text: fairManager.$hubToken)
    //                }
    //
    //                Text(atx: "The token is optional, and is only needed for development or advanced usage. One can be created at your [GitHub Personal access token](https://github.com/settings/tokens) setting").multilineTextAlignment(.trailing)

                    HelpButton(url: "https://github.com/settings/tokens")
                }
            }
            .padding(20)
        }
    }
}

extension Text {
    /// Creates a Text like "10 seconds", "2 hours"
    init(duration: TimeInterval, style: Date.ComponentsFormatStyle.Style = .wide) {
        self.init(Date(timeIntervalSinceReferenceDate: 0)..<Date(timeIntervalSinceReferenceDate: duration), format: .components(style: style))
    }
}

struct PrivacySettingsView : View {
    @EnvironmentObject var fairManager: FairManager

    @Namespace var namespace

    var body: some View {
        VStack {
            Form {
                HStack {
                    Toggle(isOn: $fairManager.appLaunchPrivacy) {
                        Text("App Launch Privacy:", bundle: .module, comment: "app privacy preference enable switch")
                    }
                    .toggleStyle(.switch)
                    .help(Text("By default, macOS reports every app launch event to a remote server, which could expose your activities to third parties. Enabling this setting will block this telemetry.", bundle: .module, comment: "app privacy preference enable switch tooltip"))
                    .onChange(of: fairManager.appLaunchPrivacy) { enabled in
                        self.fairManager.handleChangeAppLaunchPrivacy(enabled: enabled)
                    }

                    Spacer()
                    fairManager.launchPrivacyButton()
                        .buttonStyle(.bordered)
                        .focusable(true)
                        .prefersDefaultFocus(in: namespace)
                }

                Picker(selection: $fairManager.appLaunchPrivacyDuration) {
                    Text(duration: 10.0).tag(10.0) // 10 seconds
                    Text(duration: 60.0).tag(60.0) // 60 seconds
                    Text(duration: 60.0 * 30).tag(60.0 * 30) // 1/2 hour
                    Text(duration: 60.0 * 60.0 * 1.0).tag(60.0 * 60.0 * 1.0) // 1 hour
                    Text(duration: 60.0 * 60.0 * 2.0).tag(60.0 * 60.0 * 2.0) // 2 hours
                    Text(duration: 60.0 * 60.0 * 12.0).tag(60.0 * 60.0 * 12.0) // 12 hours
                    Text(duration: 60.0 * 60.0 * 24.0).tag(60.0 * 60.0 * 24.0) // 24 hours

                    Text("Until App Fair Exit", bundle: .module, comment: "app launch privacy preference menu label").tag(TimeInterval(60.0 * 60.0 * 24.0 * 365.0 * 100.0)) // 100 years is close enough to forever
                } label: {
                    Text("Duration:", bundle: .module, comment: "app launch privacy activation duration menu title")
                }
                .help(Text("The amount of time that App Launch Privacy will remain enabled before it is automatically disabled. Exiting the App Fair app will always disable App Launch privacy mode.", bundle: .module, comment: "app launch privacy duration menu tooltip"))
                .pickerStyle(.menu)
                .disabled(fairManager.appLaunchPrivacy == false)
                .fixedSize() // otherwise the picker expands greedily

                scriptPreviewRow()
            }
            .padding()


            Divider()

            GroupBox {
                Text("""
                    The macOS operating system reports all application launches to third-party servers. Preventing this tracking is accomplished by temporarily blocking network traffic to these servers during the launch of an application. Enabling this feature will require authenticating as an administrator.

                    App Launch Privacy will block telemetry from being sent when an app is opened using the App Fair's “Launch” button, or when it is manually enabled using the shield button.

                    Privacy mode will be automatically de-activated after the specified duration, as well as when quitting App Fair.app. Privacy mode should not be left permanently disabled, because it may prevent certificate revocation checks from taking place.
                    """, bundle: .module, comment: "app launch privacy description text")
                .font(.body)
                // .textSelection(.enabled) // bug that causes lines to stop wrapping when text is selected
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
            } label: {
                Text("About App Launch Privacy", bundle: .module, comment: "app launch privacy description group box title")
                    .font(.headline)
            }
        }
    }

    func scriptPreviewRow() -> some View {
        Group {
            if let scriptURL = try? FairManager.appLaunchPrivacyTool.get() {
                let scriptFolder = (scriptURL.deletingLastPathComponent().path as NSString).abbreviatingWithTildeInPath

                if fairManager.appLaunchPrivacy == true {
                    HStack {
                        TextField(text: .constant(scriptFolder)) {
                            Text("Installed at:", bundle: .module, comment: "app launch privacy text field label for installation location")
                        }
                        .textFieldStyle(.plain)
                        .textSelection(.disabled)
                        .focusable(false)

                        Text("Show", bundle: .module, comment: "app launch privacy button title for displaying location of installed script")
                            .button {
                                NSWorkspace.shared.selectFile(scriptURL.appendingPathExtension("swift").path, inFileViewerRootedAtPath: scriptFolder)
                            }
                    }
                } else {
                    HStack {
                        TextField(text: .constant(scriptFolder)) {
                            Text("Install location:", bundle: .module, comment: "app launch privacy text field title for script installation location")
                        }
                        .textFieldStyle(.plain)
                        .textSelection(.disabled)
                        .focusable(false)

                        Text("Preview", bundle: .module, comment: "app launch privacy button title for previewing location where script will be installed")
                            .button {
                                if !FileManager.default.isReadableFile(atPath: scriptURL.path) {
                                    // save the script so we can preview it
                                    if let swiftFile = try? self.fairManager.saveAppLaunchPrivacyTool(source: true) {
                                        NSWorkspace.shared.selectFile(swiftFile.path, inFileViewerRootedAtPath: scriptFolder)
                                    }
                                }
                            }
                    }
                }
            }
        }
    }

}

