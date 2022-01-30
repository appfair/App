import FairApp
import SwiftUI

@available(macOS 12.0, iOS 15.0, *)
public struct AppSettingsView: View {
    public enum Tabs: Hashable {
        case general
        case fairapps
        case homebrew
        case advanced
    }

    public var body: some View {
        TabView {
            GeneralSettingsView()
                .padding(20)
                .tabItem {
                    Text("General")
                        .label(image: FairSymbol.switch_2)
                        .symbolVariant(.fill)
                }
                .tag(Tabs.general)
            FairAppsSettingsView()
                .padding(20)
                .tabItem {
                    Text("Fairapps")
                        .label(image: AppSource.fairapps.symbol)
                        .symbolVariant(.fill)
                }
                .tag(Tabs.general)
            HomebrewSettingsView()
                .padding(20)
                .tabItem {
                    Text("Homebrew")
                        .label(image: AppSource.homebrew.symbol)
                        .symbolVariant(.fill)
                }
                .tag(Tabs.general)
            AdvancedSettingsView()
                .padding(20)
                .tabItem {
                    Text("Advanced")
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
    @EnvironmentObject var caskManager: CaskManager

    @State private var homebrewOperationInProgress = false
    @State private var homebrewInstalled: Bool? = nil

    var body: some View {
        settingsForm
            .task {
                self.homebrewInstalled = caskManager.isHomebrewInstalled()
            }
    }

    var settingsForm: some View {
        Form {
            HStack {
                Toggle(isOn: $caskManager.enableHomebrew) {
                    Text(atx: "Homebrew Casks")
                }

//                let installedVersion = try? caskManager.installedBrewVersion()
//                if let installedVersion = installedVersion {
//                    (Text("Installed version: \(installedVersion.version)")
//                     + Text(" (") + Text(installedVersion.updated, format: .relative(presentation: .numeric, unitsStyle: .wide)) + Text(")"))
//                        .foregroundColor(.secondary)
//                        .textSelection(.enabled)
//                } else {
//                    Text("Not Installed")
//                }
            }
            .toggleStyle(.switch)
            .help(Text("Adds homebrew Casks to the sources of available apps."))

            Group {
                Toggle(isOn: $caskManager.manageCaskDownloads) {
                    Text(atx: "Use integrated download manager")
                }
                    .help(Text("Whether to use the built-in download manager to handle downloading and previewing Cask artifacts. This will permit Cask installation to be monitored and cancelled from within the app. Disabling this preference will cause brew to use curl for downloading, which will not report progress in the user-interface."))

                Toggle(isOn: $caskManager.quarantineCasks) {
                    Text(atx: "Quarantine installed apps")
                }
                    .help(Text("Marks apps installed with homebrew cask as being quarantined, which will cause a system gatekeeper check and user confirmation the first time they are run."))

                Toggle(isOn: $caskManager.forceInstallCasks) {
                    Text(atx: "Install overwrites previous app installation")
                }
                    .help(Text("Whether to overwrite a prior installation of a given Cask. This could cause a newer version of an app to be overwritten by an earlier version."))

                Toggle(isOn: $caskManager.enableBrewSelfUpdate) {
                    Text(atx: "Enable Homebrew self-update")
                }
                    .help(Text("Allow Homebrew to update itself while installing other packages."))

                Toggle(isOn: $caskManager.requireCaskChecksum) {
                    Text(atx: "Require cask checksum")
                }
                    .help(Text("Requires that downloaded artifacts have an associated SHA-256 cryptographic checksum to verify that they match the version that was added to the catalog."))

                Toggle(isOn: $caskManager.enableBrewAnalytics) {
                    Text(atx: "Enable installation telemetry")
                }
                    .help(Text("Permit Homebrew to send telemetry to Google about the packages you install and update. See https://docs.brew.sh/Analytics"))
            }
            .disabled(caskManager.enableHomebrew == false)


            Divider().padding()

            Section {
                GroupBox {
                    VStack {
                        Text("""
                            Homebrew is a repository of third-party applications and installers called “Casks”. These packages are installed and managed using the `brew` command and are typically placed in the `/Applications/` folder.

                            Homebrew Casks are not subject to the same sandboxing, entitlement disclosure, and source transparency requirements as App Fair fair-ground apps, and so should only be installed from trusted sources.

                            Read more at: [https://brew.sh](https://brew.sh)
                            Browse all Casks: [https://formulae.brew.sh/cask/](https://formulae.brew.sh/cask/)
                            Location: \((caskManager.brewInstallRoot.path as NSString).abbreviatingWithTildeInPath)
                            Installed: \(isBrewInstalled ? "yes" : "no")
                            """)
                            .textSelection(.enabled)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .controlSize(.small)
                                .frame(height: 12)
                                .opacity(homebrewOperationInProgress ? 1.0 : 0.0)

                            Text(isBrewInstalled ? "Reset Homebrew" : "Setup Homebrew")
                                .button {
                                    homebrewOperationInProgress = true
                                    do {
                                        if isBrewInstalled {
                                            try await caskManager.uninstallHomebrew()
                                            dbg("caskManager.uninstallHomebrew success")
                                        } else {
                                            try await caskManager.installHomebrew()
                                            dbg("caskManager.installHomebrew success")
                                        }
                                        self.homebrewInstalled = caskManager.isHomebrewInstalled()
                                    } catch {
                                        self.fairManager.appManager.reportError(error)
                                    }
                                    self.homebrewOperationInProgress = false
                                }
                                .disabled(self.homebrewOperationInProgress)
                                .help(isBrewInstalled ? "This will remove the version of Homebrew that is used locally by the App Fair. It will not affect any system-level Homebrew installation that may be present elsewhere. Homebrew can be re-installed again afterwards." : "Download homebrew and set it up for use by the App Fair. It will be installed locally to the App Fair and will not affect any other version that may be installed on the system. This operation will be performed automatically if any cask is installed and there is no local version of Homebrew found on the system.")
                                .padding()
                        }
                    }
                    .frame(maxWidth: .infinity)

                }
            }
        }
    }

    var isBrewInstalled: Bool {
        // override locally so we can control state
        if let homebrewInstalled = homebrewInstalled {
            return homebrewInstalled
        }
        return caskManager.isHomebrewInstalled()
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct FairAppsSettingsView: View {
    @EnvironmentObject var fairManager: FairManager
    @EnvironmentObject var appManager: AppManager

    @State var hoverRisk: AppRisk? = nil

    var body: some View {
        Form {
            HStack(alignment: .top) {
                AppRiskPicker(risk: $appManager.riskFilter, hoverRisk: $hoverRisk)
                (hoverRisk ?? appManager.riskFilter).riskSummaryText(bold: true)
                    .textSelection(.enabled)
                    .font(.body)
                    .frame(height: 150, alignment: .top)
                    .frame(maxWidth: .infinity)
            }

            Toggle(isOn: $appManager.showPreReleases) {
                Text("Show Pre-Releases")
            }
                .help(Text("Display releases that are not yet production-ready according to the developer's standards."))

            Text("Pre-releases are experimental versions of software that are less tested than stable versions. They are generally released to garner user feedback and assistance, and so should only be installed by those willing experiment.")
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
                Text("Badge App Icon with update count")
            }
                .help(Text("Show the number of updates that are available to install."))
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
        case .system: return Text("System")
        case .light: return Text("Light")
        case .dark: return Text("Dark")
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
            Text("Theme:")
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
            Text("Risk Exposure:")
        }
        .radioPickerStyle()
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct AdvancedSettingsView: View {
    @EnvironmentObject var fairManager: FairManager
    @EnvironmentObject var appManager: AppManager

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
                Toggle(isOn: $appManager.relaunchUpdatedApps) {
                    Text("Re-launch updated apps")
                }
                    .help(Text("Automatically re-launch an app when it has bee updated. Otherwise, the updated version will be used after quitting and re-starting the app."))

                Toggle(isOn: $appManager.autoUpdateCatalogApp) {
                    Text(atx: "Keep catalog app up to date")
                }
                .help(Text("Automatically download and apply updates to the App Fair catalog browser app."))
                .toggleStyle(.checkbox)

                Toggle(isOn: $fairManager.enableInstallWarning) {
                    Text(atx: "Require app install confirmation")
                }
                .help(Text("Installing an app will present a confirmation alert to the user. If disabled, apps will be installed and updated without confirmation."))
                .toggleStyle(.checkbox)

                Toggle(isOn: $fairManager.enableDeleteWarning) {
                    Text(atx: "Require app delete confirmation")
                }
                .help(Text("Deleting an app will present a confirmation alert to the user. If disabled, apps will be deleted without confirmation."))
                .toggleStyle(.checkbox)

                Divider()


                Divider().padding()

                HStack {
                    TextField("Hub Host", text: fairManager.$hubProvider)
                    checkButton(fairManager.hubProvider)
                }
                HStack {
                    TextField("Organization", text: fairManager.$hubOrg)
                    checkButton(fairManager.hubProvider, fairManager.hubOrg)
                }
                HStack {
                    TextField("Repository", text: fairManager.$hubRepo)
                    checkButton(fairManager.hubProvider, fairManager.hubOrg, fairManager.hubRepo)
                }
//                HStack {
//                    SecureField("Token", text: fairManager.$hubToken)
//                }
//
//                Text(atx: "The token is optional, and is only needed for development or advanced usage. One can be created at your [GitHub Personal access token](https://github.com/settings/tokens) setting").multilineTextAlignment(.trailing)

                HelpButton(url: "https://github.com/settings/tokens")
            }
            .padding(20)
        }
    }
}

