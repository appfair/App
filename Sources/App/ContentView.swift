import FairApp
import JXSwiftUI
import JXKit
import JXPod

import AboutMe
import AnimalFarm
import PetStore

/// The main content view for the app. This is the starting point for customizing you app's behavior.
struct ContentView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        NavigationView {
            PlaygroundListView()
        }
    }
}

extension JXDynamicModule {
    @MainActor @ViewBuilder static func entryLink<V: View>(name: String, symbol: String, version: String?, branches: [String], view: @escaping () -> V) -> some View {
        if let source = try? hubSource {
            NavigationLink {
                ModuleVersionsListView(appName: name, branches: branches, versionManager: HubVersionManager(source: source, installedVersion: version.flatMap(SemVer.init(string:)))) {
                    view() // the root view that will be shown
                }
            } label: {
                HStack {
                    Label {
                        Text(name)
                    } icon: {
                        Image(systemName: symbol)
                            //.symbolVariant(.fill)
                            .symbolRenderingMode(.hierarchical)
                    }
                    Spacer()
                    Text(version ?? "")
                        .font(.caption.monospacedDigit())
                        .frame(alignment: .trailing)
                }
            }
        }
    }
}

extension Bundle {
    /// Returns the parsed Package.resolved embedded in the app.
    var packageResolved: ResolvedPackage {
        get throws {
            try ResolvedPackage(json: Bundle.module.loadResource(named: "Package.resolved"))
        }
    }

    func findVersion(repository: URL?, in packages: [(url: String, version: String?)]) -> String? {
        for (url, version) in packages {
            if url == repository?.absoluteString
                || url == repository?.deletingPathExtension().absoluteString {
                // the package matches, so return the version, which might be a
                dbg("package version found for", repository, version)
                return version
            }
        }

        dbg("no package version found for", repository)
        return nil
    }

    /// Returns the version of the package from the "Package.resolved" that is bundled with this app.
    func packageVersion(for repository: URL?) -> String? {
        dbg(repository)
        do {
            let resolved = try packageResolved
            switch resolved.rawValue {
                // handle both versions of the resolved package format
            case .p(let v1):
                return findVersion(repository: repository, in: v1.object.pins.map({ ($0.repositoryURL, $0.state.version) }))
            case .q(let v2):
                return findVersion(repository: repository, in: v2.pins.map({ ($0.location, $0.state.version) }))
            }
        } catch {
            dbg("error getting package version for", repository, error)
            return nil
        }

    }
}

// TODO: move JXDynamicModule down to JXBride and move implementation into PetStore and AnimalFarm themselves
extension PetStoreModule : JXDynamicModule {
    @MainActor @ViewBuilder static func entryLink(branches: [String]) -> some View {
        entryLink(name: "Pet Store", symbol: "hare", version: Bundle.module.packageVersion(for: Self.remoteURL?.baseURL), branches: branches) {
            PetStoreView()
        }
    }
}

extension AnimalFarmModule : JXDynamicModule {
    @MainActor @ViewBuilder static func entryLink(branches: [String]) -> some View {
        entryLink(name: "Animal Farm", symbol: "pawprint", version: Bundle.module.packageVersion(for: Self.remoteURL?.baseURL), branches: branches) {
            AnimalFarmView()
        }
    }
}

extension AboutMeModule : JXDynamicModule {
    @MainActor @ViewBuilder static func entryLink(branches: [String]) -> some View {
        entryLink(name: "About Me", symbol: "person", version: Bundle.module.packageVersion(for: Self.remoteURL?.baseURL), branches: branches) {
            AboutMeView()
        }
    }
}


@MainActor class HubVersionManager : ObservableObject {
    /// All the available refs and their dates for the pet store module
    @Published var refs: [HubModuleSource.RefInfo] = []

    /// The currently-active version of the local module
    let installedVersion: SemVer?

    let source: HubModuleSource

    init(source: HubModuleSource, installedVersion: SemVer?) {
        self.source = source
        self.installedVersion = installedVersion
    }

    func refreshModules() async {
        dbg("refreshing modules")
        do {
            self.refs = try await source.refs
            dbg("available refs:", refs.map(\.ref.name))
        } catch {
            dbg("error getting source:", error)
        }
    }
}

struct PlaygroundListView: View {
    @EnvironmentObject var store: Store

    /// Returns the branches to display in the versions list, which will be contingent on development mode being enabled.
    var branches: [String] {
        store.developmentMode == true ? ["main", "develop", "staging"] : []
    }

    var body: some View {
        List {
            Section("Applications") {
                PetStoreModule.entryLink(branches: branches)
                AnimalFarmModule.entryLink(branches: branches)
                AboutMeModule.entryLink(branches: branches)
                // add more applications here…
            }
        }
        .navigationTitle("Showcase")
    }
}


struct ModuleVersionsListView<V: View>: View {
    let appName: String
    /// The branches that should be shown
    let branches: [String]

    @StateObject var versionManager: HubVersionManager
    let viewBuilder: () -> V

    var body: some View {
        List {
            Section {
                ForEach(versionManager.refs, id: \.ref.name) { refDate in
                    moduleVersionLink(version: refDate.ref, date: refDate.date)
                }
            } header: {
                Text("Versions", bundle: .module, comment: "section header title for apps list view version section")
            }

            if !branches.isEmpty {
                Section {
                    ForEach(branches, id: \.self) { branch in
                        moduleVersionLink(version: .branch(branch), date: nil)
                    }
                } header: {
                    Text("Branches", bundle: .module, comment: "section header title for apps list view branches section")
                }
            }
        }
        .navigationTitle(appName)
        .refreshable {
            await versionManager.refreshModules()
        }
        .task {
            await versionManager.refreshModules()
        }
    }

    func moduleVersionLink(version: HubModuleSource.Ref, date: Date?) -> some View {
        let compatible = version.semver?.minorCompatible(with: versionManager.installedVersion ?? .min)

        return NavigationLink {
            ModuleRefView(ref: version) { viewBuilder() }
                .navigation(title: Text(appName), subtitle: Text(version.name))
                #if !os(macOS)
                .navigationBarTitleDisplayMode(.inline) // for some reason, this prevents the top-level button from being responsive
                #endif
        } label: {
            Label {
                VStack(alignment: .leading) {
                    Text(appName)
                    Group {
                        if let date = date {
                            Text("\(version.name) (\(date, format: .relative(presentation: .named, unitsStyle: .abbreviated)))", bundle: .module, comment: "list comment title describing the current version")
                        } else {
                            Text(version.name)
                        }
                    }
                    .font(.footnote.monospacedDigit())
                }
            } icon: {
                iconView()
            }
            //.labelStyle(CentreAlignedLabelStyle())
            .frame(alignment: .center)
        }
        .disabled(compatible == false)

        @ViewBuilder func iconView() -> some View {
            if version.name == versionManager.installedVersion?.versionString {
                Image(systemName: "checkmark.circle.fill")
                    .tint(.green)
            } else if compatible == false {
                Image(systemName: "xmark.circle")
                    .tint(.red)
            } else {
                Image(systemName: "circle")
                    .tint(.accentColor)
            }
        }
    }
}

struct ModuleRefView<Content: View> : View {
    let ref: HubModuleSource.Ref
    let content: () -> Content

    var body: some View {
        content()
    }
}

/// Doesn't work
struct CentreAlignedLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        Label {
            configuration.title
                .alignmentGuide(.firstTextBaseline) {
                    $0[VerticalAlignment.center]
                }
        } icon: {
            configuration.icon
                .alignmentGuide(.firstTextBaseline) {
                    $0[VerticalAlignment.center]
                }
        }
    }
}

extension SemVer {
    /// True when the major and minor versions are the same as the other version
    func minorCompatible(with version: SemVer) -> Bool {
        compatible(with: version, to: .minor)
    }

    func compatible(with version: SemVer, to component: Component) -> Bool {
        switch component {
        case .major:
            return self.major == version.major
        case .minor:
            return self.major == version.major && self.minor == version.minor
        case .patch:
            return self.major == version.major && self.minor == version.minor && self.patch == version.patch
        }
    }
}

// Prevent loading the JS from all playground destinations at once
private struct LazyView<V: View>: View {
    let view: () -> V

    var body: some View {
        view()
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Store())
    }
}
