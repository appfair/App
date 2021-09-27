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
import SwiftUI

@available(macOS 12.0, iOS 15.0, *)
struct CatalogItemView: View {
    let info: AppInfo
    @EnvironmentObject var appManager: AppManager
    @Environment(\.openURL) var openURLAction

    @State var currentActivity: Activity? = nil
    @State var progress = Progress(totalUnitCount: 1)
    @State var readme: AttributedString? = nil
    @State var confirmations: [Activity: Bool] = [:]

    var body: some View {
        VStack {
            catalogBody
        }
        .task {
            await fetchREADME()
        }
    }

    private var catalogBody: some View {
        HStack(alignment: .top) {
            iconView()

            VStack(alignment: .leading, spacing: 10) {
                Text(item.name)
                    .font(Font.system(size: 20, weight: .bold, design: .default))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                Text(item.subtitle ?? item.localizedDescription)
                    .font(Font.system(size: 15, weight: .regular, design: .default))
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)

                actionButtonStack

                Spacer()
            }
        }
        .padding()
    }

    private var installButton: some View {
        button(activity: .install, role: nil, needsConfirm: true)
            .disabled(appInstalled)
            .confirmationDialog(Text("Install \(info.release.name)", bundle: .module), isPresented: confirmationBinding(.install), titleVisibility: .visible, actions: {
                Bundle.module.button("Download & Install \(info.release.name)") {
                    runTask(activity: .install, confirm: true)
                }
                Bundle.module.button("Visit Community Forum") {
                    openURLAction(info.release.discussionsURL)
                }
                // TODO: only show if there are any open issues
                // Bundle.module.button("Visit App Issues Page") {
                //    openURLAction(info.release.issuesURL)
                // }
                .help(Text("Opens your web browsers and visits the developer site at \(info.release.baseURL.absoluteString)", bundle: .module)) // sadly, tooltips on confirmationDialog buttons don't seem to work
            }, message: deleteMessage)
            .tint(.green)
    }

    var updateButton: some View {
        button(activity: .update)
            .disabled(!appInstalled || appUpdated)
            .accentColor(.orange)
    }

    var launchButton: some View {
        button(activity: .launch)
            .disabled(!appInstalled)
            .accentColor(.green)
    }

    var revealButton: some View {
        button(activity: .reveal)
            .disabled(!appInstalled)
            .accentColor(.teal)
    }

    var trashButton: some View {
        button(activity: .trash, role: ButtonRole.destructive, needsConfirm: true)
        //.keyboardShortcut(.delete)
            .disabled(!appInstalled)
            .accentColor(.red)
            .confirmationDialog(Text("Really delete this app?", bundle: .module), isPresented: confirmationBinding(.trash), titleVisibility: .visible, actions: {
                Bundle.module.button("Delete") {
                    runTask(activity: .trash, confirm: true)
                }
            }, message: {
                Text("This will remove the application “\(info.release.name)” from your applications folder and place it in the Trash.")
            })
    }

    private var actionButtonStack: some View {
        let isCatalogApp = info.release.bundleIdentifier == "app.App-Fair"

        return HStack {
            installButton.disabled(isCatalogApp)
            updateButton
            Spacer()
            launchButton.disabled(isCatalogApp)
            Spacer()
            revealButton
            trashButton.disabled(isCatalogApp)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle)
        .controlSize(.large)
    }

    func deleteMessage() -> some View {
        Text(atx: """
            This will download and install the application “\(info.release.name)” from the developer “\(info.release.developerName)” at:

            \(info.release.sourceURL.absoluteString)

            This app has not undergone any formal review, so you will be installing and running it at your own risk.

            Before installing, you should first review the Discussions, Issues, and Documentation pages to learn more about the app.
            """)
    }

    var item: FairAppCatalog.AppRelease {
        info.release
    }

    var doingStuff: Bool {
        currentActivity != nil
    }

    enum Activity : CaseIterable, Equatable {
        case install
        case update
        case trash
        case reveal
        case launch

        var info: (title: LocalizedStringKey, systemSymbol: String, tintColor: Color?, toolTip: LocalizedStringKey) {
            switch self {
            case .install:
                return ("Install", "square.and.arrow.down.fill", Color.blue, "Download and install the app.")
            case .update:
                return ("Update", "square.and.arrow.down.on.square.fill", Color.orange, "Update to the latest version of the app.")
            case .trash:
                return ("Delete", "trash", Color.red, "Delete the app from your computer.")
            case .reveal:
                return ("Reveal", "doc.text.fill.viewfinder", Color.indigo, "Displays the app install location in the Finder.")
            case .launch:
                return ("Launch", "checkmark.seal.fill", Color.green, "Launches the app.")
            }
        }
    }

    /// The plist for the given installed app
    var appPropertyList: Result<Plist, Error>? {
        let installPath = AppManager.appInstallPath(for: item)
        let result = appManager.installedApps[installPath]
        dbg("install for item:", item, "install path:", AppManager.appInstallPath(for: item).path, "plist:", result != nil, "installedApps:", appManager.installedApps.keys.map(\.path))

        if result == nil {
            dbg("install path not found:", installPath, "in keys:", appManager.installedApps.keys)
        }
        return result
    }

    /// Returns the URLs that are registered with the system `NSWorkspace` for handling the app's bundle
    var appInstallURLs: [URL] {
        guard let plist = appPropertyList?.successValue else {
            return []
        }
        guard let bundleID = plist.bundleID else {
            return []
        }

#if os(macOS)
        let apps = NSWorkspace.shared.urlsForApplications(withBundleIdentifier: bundleID)
        return apps
#else
        return [] // TODO: iOS install check
#endif
    }

    /// Whether the app is successfully installed
    var appInstalled: Bool {
        return !appInstallURLs.isEmpty
    }

    /// The app is updated if its version is
    var appUpdated: Bool {
        (info.installedVersion ?? .min) >= (info.releasedVersion ?? .min)
    }

    func confirmationBinding(_ activity: Activity) -> Binding<Bool> {
        Binding {
            confirmations[activity] ?? false
        } set: { newValue in
            confirmations[activity] = newValue
        }
    }

    func runTask(activity: Activity, confirm confirmed: Bool) {
        if !confirmed {
            confirmations[activity] = true
        } else {
            confirmations[activity] = false // we have confirmed
            currentActivity = activity
            Task {
                await performAction(activity: activity)
                currentActivity = nil
            }
        }
    }

    func button(activity: Activity, role: ButtonRole? = .none, needsConfirm: Bool = false) -> some View {
        Button(role: role, action: {
            runTask(activity: activity, confirm: !needsConfirm)
        }, label: {
            Label(title: {
                HStack(spacing: 5) {
                    Text(activity.info.title, bundle: .module)
                        .truncationMode(.middle)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                    Group {
                        if currentActivity == activity {
                            ProgressView()
                                .progressViewStyle(.circular) // spinner
                                .controlSize(.small) // needs to be small to fit in the button
                                .opacity(currentActivity == activity ? 1 : 0)
                        } else {
                            Image(systemName: "circle")
                        }
                    }
                    .frame(width: 20, height: 15)
                }
            }, icon: {
                Image(systemName: activity.info.systemSymbol)
            })
        })
            .buttonStyle(ActionButtonStyle(primary: true, highlighted: false))
            .accentColor(activity.info.tintColor)
            .disabled(doingStuff)
            .help(activity.info.toolTip)
    }

    func performAction(activity: Activity) async {
        switch activity {
        case .install: await installButtonTapped()
        case .update: await updateButtonTapped()
        case .trash: await deleteButtonTapped()
        case .reveal: await revealButtonTapped()
        case .launch: await launchButtonTapped()
        }
    }

    func fetchREADME() async {
        dbg("fetching")
//        do {
//            // let await
//            let contents = ""
//            // self.readme = try contents.atx()
//            self.readme = wip(nil) // FIXME: no point in rendering markdown until headers and other formatting are supported
//        } catch {
//            self.readme = AttributedString("Error fetching README.md")
//            appManager.reportError(error)
//        }
    }

    func iconView() -> some View {
        FairIconView(item.name)
            .frame(width: 100, height: 100)
        //AppIconView(iconName: item.name, baseColor: .yellow)
    }

    func iconView2() -> some View {
        let baseColor = Color.randomIconColor()
        return ZStack {
            RoundedRectangle(cornerRadius: 15)
                .foregroundStyle(
                    .linearGradient(colors: [Color.gray, .white], startPoint: .bottomLeading, endPoint: .topTrailing))
            RoundedRectangle(cornerRadius: 15)
                .foregroundStyle(
                    .linearGradient(colors: [Color.gray, .white], startPoint: .topTrailing, endPoint: .bottomLeading))
                .padding(4)
            Image(systemName: "trash")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .symbolVariant(.fill)
                .symbolVariant(.square)
                .foregroundStyle(.linearGradient(colors: [baseColor, baseColor.opacity(0.9)], startPoint: .topTrailing, endPoint: .bottomLeading))
                .padding(20)
        }
        .frame(width: 100, height: 100)
    }

    func card(_ s1: LocalizedStringKey, _ s2: LocalizedStringKey, _ s3: LocalizedStringKey) -> some View {
        VStack {
            Text(s1, bundle: .module)
                .textCase(.uppercase)
                .font(.system(size: 10, weight: .bold, design: .default))
                .foregroundColor(.secondary)
            Text(s2, bundle: .module)
                .font(.system(size: 20, weight: .black, design: .rounded))
            Text(s3, bundle: .module)
        }
    }

    func installButtonTapped() async {
        dbg("installButtonTapped")
        do {
            try await appManager.install(item: item, progress: progress, update: false)
        } catch {
            appManager.reportError(error)
        }
    }

    func launchButtonTapped() async {
        dbg("launchButtonTapped")
        await appManager.launch(item: item)
    }

    func updateButtonTapped() async {
        dbg("updateButtonTapped")
        do {
            try await appManager.install(item: item, progress: progress, update: true)
        } catch {
            appManager.reportError(error)
        }
    }

    func revealButtonTapped() async {
        dbg("revealButtonTapped")
        await appManager.reveal(item: item)
    }

    func deleteButtonTapped() async {
        dbg("deleteButtonTapped")
        await appManager.trash(item: item)
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct CatalogItemView_Previews: PreviewProvider {
    static var previews: some View {
        CatalogItemView(info: AppInfo(release: catalog))
            .frame(width: 700)
            .environmentObject(AppManager())
        //.environment(\.locale, Locale(identifier: "fr"))
    }
}


private let catalog = FairAppCatalog.AppRelease(name: "App Fair", bundleIdentifier: "app.App-Fair", subtitle: "The App Fair catalog browser app", developerName: "appfair@appfair.net", localizedDescription: "This app allows you to browse, download, and install apps from the App Fair", size: 1_234_567, version: "1.2.3", versionDate: Date(timeIntervalSinceReferenceDate: 0), downloadURL: URL(string: "https://github.com/appfair/App/releases/download/App-Fair/App-Fair-macOS.zip")!, iconURL: URL(string: "https://github.com/appfair/App/releases/download/App-Fair/App-Fair.png")!, screenshotURLs: nil, versionDescription: nil, tintColor: "#AABBCC", beta: false, sourceIdentifier: nil, categories: [""], downloadCount: 123_456, starCount: 123, watcherCount: nil, issueCount: 12, sourceSize: 2_210_000, coreSize: nil, sha256: nil, permissions: nil)
