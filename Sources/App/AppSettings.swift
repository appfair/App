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
    @EnvironmentObject var caskManager: CaskManager

    var body: some View {
        Form {
            Toggle(isOn: $caskManager.enableHomebrew) {
                Text(atx: "Homebrew Casks:")
            }
            .toggleStyle(.switch)
            .disabled(caskManager.enableHomebrew != true && CaskManager.isHomebrewInstalled == false)
                .help(Text("Adds homebrew Casks to the sources of available apps."))

            Toggle(isOn: $caskManager.quarantineCasks) {
                Text(atx: "Quarantine apps")
            }
                .help(Text("Marks apps installed with homebrew cask as being _quarantined_, which will cause a system gatekeeper check and user confirmation the first time they are run."))

            Toggle(isOn: $caskManager.forceInstallCasks) {
                Text(atx: "Install overwrites pre-existing Cask apps")
            }
                .help(Text("Whether to overwrite a prior installation of a given Cask. This could cause a newer version of an app to be overwritten by an earlier version."))


            Text("""
                Homebrew Cask is a repository of third-party applications and installers. These packages will be installed using the `brew` command. These packages are not subject to the same sandboxing and security requirements as App Fair fair-ground apps, and so should only be installed from trusted sources.

                Read more at [`https://brew.sh`](https://brew.sh/)
                """)
                .font(.body)
                .multilineTextAlignment(.leading)
                .frame(minHeight: 90, alignment: .top)
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct FairAppsSettingsView: View {
    @AppStorage("showPreReleases") private var showPreReleases = false
    @AppStorage("riskFilter") private var riskFilter = AppRisk.risky

    var body: some View {
        Form {
            HStack(alignment: .firstTextBaseline) {
                AppRiskPicker(risk: $riskFilter)
                riskFilter.riskSummaryText(bold: true)
                    .textSelection(.enabled)
                    .font(.body)
                    .frame(height: 150, alignment: .top)
            }

            Toggle(isOn: $showPreReleases) {
                Text("Show Pre-Releases")
            }
                .help(Text("Display releases that are not yet production-ready according to the developer's standards."))

            Text("Pre-releases are experimental versions of software that are less tested than stable versions. They are generally released to garner user feedback and assistance, and so should only be installed by those willing experiment.")
                .font(.body)
                .multilineTextAlignment(.leading)
                .frame(minHeight: 90, alignment: .top)

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

    var body: some View {
        Picker(selection: $risk) {
            ForEach(AppRisk.allCases) { appRisk in
                appRisk.riskLabel()
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
                HStack {
                    TextField("Hub", text: fairManager.$hubProvider)
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
                HStack {
                    SecureField("Token", text: fairManager.$hubToken)
                }

                Text(atx: "The token is optional, and is only needed for development or advanced usage. One can be created at your [GitHub Personal access token](https://github.com/settings/tokens) setting").multilineTextAlignment(.trailing)

                HelpButton(url: "https://github.com/settings/tokens")
            }
            .padding(20)
        }
    }
}

