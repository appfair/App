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
    @MainActor @ViewBuilder static func entryLink<V: View>(name: String, symbol: String, version: String?, branches: [String], view: @escaping (JXContext) -> V) -> some View {
        if let source = try? Self.hubSource {
            NavigationLink {
                ModuleVersionsListView(appName: name, branches: branches) { ctx in
                    view(ctx) // the root view that will be shown
                }
                .environmentObject(HubVersionManager(source: source, relativePath: dump(Self.remoteURL?.relativePath), installedVersion: version.flatMap(SemVer.init(string:))))
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

// TODO: move JXDynamicModule down to JXBridge and move implementation into PetStore and AnimalFarm themselves

extension PetStoreModule : JXDynamicModule {
    @MainActor @ViewBuilder static func entryLink(branches: [String]) -> some View {
        entryLink(name: "Pet Store", symbol: "hare", version: Bundle.module.packageVersion(for: Self.remoteURL?.baseURL), branches: branches) { ctx in
            PetStoreView(context: ctx)
        }
    }
}

extension AnimalFarmModule : JXDynamicModule {
    @MainActor @ViewBuilder static func entryLink(branches: [String]) -> some View {
        entryLink(name: "Animal Farm", symbol: "pawprint", version: Bundle.module.packageVersion(for: Self.remoteURL?.baseURL), branches: branches) { ctx in
            AnimalFarmView(context: ctx)
        }
    }
}

extension AboutMeModule : JXDynamicModule {
    @MainActor @ViewBuilder static func entryLink(branches: [String]) -> some View {
        entryLink(name: "About Me", symbol: "person", version: Bundle.module.packageVersion(for: Self.remoteURL?.baseURL), branches: branches) { ctx in
            AboutMeView() // (context: ctx)
        }
    }
}


@MainActor class HubVersionManager : ObservableObject {
    /// All the available refs and their dates for the pet store module
    @Published var refs: [HubModuleSource.RefInfo] = []

    /// All the local version folders
    @Published var localVersions: [HubModuleSource.Ref: URL] = [:]

    /// The currently-active version of the local module
    let installedVersion: SemVer?

    /// The relative path to the remove module for resolving references
    let relativePath: String?

    let source: HubModuleSource

    init(source: HubModuleSource, relativePath: String?, installedVersion: SemVer?) {
        self.source = source
        self.installedVersion = installedVersion
        self.relativePath = relativePath
    }

    /// Returns the most recent available version that is compatible with this version
    var latestCompatableVersion: HubModuleSource.RefInfo? {
        self.refs
            .filter { refInfo in
                refInfo.ref.semver?.minorCompatible(with: self.installedVersion ?? .max) == true
            }
            .sorting(by: \.ref.semver)
            .last
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

    var baseLocalPath: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base
            .appendingPathComponent("jxmodules", isDirectory: true)
            .appendingPathComponent(source.repository.host ?? "host", isDirectory: true)
            .appendingPathComponent(source.repository.path, isDirectory: true)
    }

    /// The local extraction path for the given ref.
    ///
    /// This will be something like: `~/Library/Developer/CoreSimulator/Devices/*/data/Containers/Data/Application/*/Library/Application%20Support/github.com/Magic-Loupe/PetStore.git/`
    func localRootPath(for ref: HubModuleSource.Ref) -> URL {
        baseLocalPath
            .appendingPathComponent(ref.type, isDirectory: true)
            .appendingPathComponent(ref.name, isDirectory: true)
    }

    /// Remove the local cached folder for the given ref.
    @discardableResult func removeLocalFolder(for ref: HubModuleSource.Ref) -> Bool {
        defer { scanFolder() } // re-scan after removing any items
        let path = localRootPath(for: ref)

        do {
            dbg("removing folder:", path.path)
            try FileManager.default.removeItem(at: path)
            return true
        } catch {
            dbg("error removing folder at:", path, error)
            return false
        }
    }

    func localRootPathExists(for ref: HubModuleSource.Ref) -> Bool {
        localVersions[ref] != nil
    }

    func localDynamicPath(for ref: HubModuleSource.Ref) -> URL? {
        URL(string: self.relativePath ?? "", relativeTo: localRootPath(for: ref))
    }

    func scanFolder() {
        // remove existing cached folders
        var versions: [HubModuleSource.Ref: URL] = [:]
        defer {
            if versions != self.localVersions {
                // update the versions if anything has changed
                self.localVersions = versions
            }
        }

        dbg(baseLocalPath)
        do {
            let dir = { try FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: [.isDirectoryKey], options: [.producesRelativePathURLs, .skipsHiddenFiles]) }

            let contents = try dir(baseLocalPath)
            for base in contents {
                dbg(base) // "branch" or "tag"
                guard let kind = HubModuleSource.Ref.Kind(rawValue: base.lastPathComponent) else {
                    dbg("skipping unrecognized folder kind:", base.path)
                    continue
                }
                let subcontents = try dir(base)
                for sub in subcontents {
                    let ref = HubModuleSource.Ref(kind: kind, name: sub.lastPathComponent)
                    dbg("creating ref:", ref, "to:", sub)
                    versions[ref] = sub
                }
            }
        } catch {
            dbg("error:", error)
        }
    }
}

struct PlaygroundListView: View {
    @EnvironmentObject var store: Store

    /// Returns the branches to display in the versions list, which will be contingent on development mode being enabled.
    var branches: [String] {
        store.developmentMode == true ? ["main"] : []
    }

    var body: some View {
        List {
            Section("Sample Apps") {
                PetStoreModule.entryLink(branches: branches)
                AnimalFarmModule.entryLink(branches: branches)
                AboutMeModule.entryLink(branches: branches)
                // add more applications here…
            }
            .symbolVariant(.fill)
        }
        .navigationTitle("Showcase")
    }
}


struct ModuleVersionsListView<V: View>: View {
    @EnvironmentObject var store: Store
    @State var allVersionsExpanded = false
    let appName: String
    /// The branches that should be shown
    let branches: [String]

    @EnvironmentObject var versionManager: HubVersionManager
    let viewBuilder: (JXContext) -> V

    var body: some View {
        List {
#if DEBUG
            if store.developmentMode == true {
                Section {
                    moduleVersionLink(ref: nil, date: nil)
                } header: {
                    Text("Live", bundle: .module, comment: "section header title for apps list view live edit section")
                }
            }
#endif

            Section {
                if let latestRef = versionManager.latestCompatableVersion {
                    moduleVersionLink(ref: .tag(latestRef.ref.name), date: latestRef.date, latest: true)
                }

                if store.developmentMode == true {
                    DisclosureGroup(isExpanded: $allVersionsExpanded) {
                        ForEach(versionManager.refs, id: \.ref.name) { refDate in
                            moduleVersionLink(ref: refDate.ref, date: refDate.date)
                        }
                    } label: {
                        Text("All Versions (\(versionManager.refs.count, format: .number))", bundle: .module, comment: "header title for disclosure group listing versions")
                    }
                }

            } header: {
                Text("Versions", bundle: .module, comment: "section header title for apps list view live edit section")
            }

            if store.developmentMode == true, branches.isEmpty == false {
                Section {
                    ForEach(branches, id: \.self) { branch in
                        moduleVersionLink(ref: .branch(branch), date: nil)
                    }
                } header: {
                    Text("Branches", bundle: .module, comment: "section header title for apps list view branches section")
                }
            }
        }
        .navigationTitle(appName)
        .refreshable {
            versionManager.scanFolder()
            await versionManager.refreshModules()
        }
        .task {
            versionManager.scanFolder()
            await versionManager.refreshModules()
        }
    }

    func log(_ value: String) {
        dbg(value)
    }

    struct LocalScriptLoader : JXScriptLoader {
        let baseURL: URL

        func scriptURL(resource: String, relativeTo: URL?, root: URL) throws -> URL {
            dbg(resource, "relativeTo:", relativeTo?.absoluteString, "root", root.absoluteString, "baseURL", baseURL.absoluteString)
            // we ignore the passed-in root and instead use our own base URL
            // let url = URL(fileURLWithPath: resource, relativeTo: self.baseURL) // relative doesn't seem to work
            let url = baseURL.appendingPathComponent(resource)
            dbg(url.absoluteString)
            return url
        }

        func loadScript(from url: URL) throws -> String? {
            dbg(url.absoluteString)
            dbg("LOAD FROM:", baseURL)
            return try String(contentsOf: url)
        }
    }

    func createContext(for ref: HubModuleSource.Ref?) -> JXContext {
        let loader: JXScriptLoader
        if let ref = ref, let baseURL = versionManager.localDynamicPath(for: ref) {
            loader = LocalScriptLoader(baseURL: baseURL)
        } else {
            loader = MonitoringScriptLoader(log: self.log)
        }
        let context = JXContext(configuration: .init(strict: store.strictMode, scriptLoader: loader, log: self.log))
        return context
    }

    func moduleVersionLink(ref: HubModuleSource.Ref?, date: Date?, latest: Bool = false) -> some View {
        let compatible = ref?.semver?.minorCompatible(with: versionManager.installedVersion ?? .max)

        return NavigationLink {
            ModuleRefView(ref: ref) { viewBuilder(createContext(for: ref)) }
                .environmentObject(versionManager)
                .navigation(title: Text(appName), subtitle: (ref?.name).flatMap(Text.init))
#if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
        } label: {
            Label {
                VStack(alignment: .leading) {
                    Text(appName)
                    HStack {
                        // if latest == true {
                        //     Text("Latest", bundle: .module, comment: "prefix for string that is the most recent string")
                        // }
                        if let ref = ref {
                            Text(ref.name)
                        }
                        if let date = date {
                            Text("(\(date, format: .relative(presentation: .named, unitsStyle: .abbreviated)))", bundle: .module, comment: "list comment title describing the current version")
                        } else {
                            (ref?.name).flatMap(Text.init)
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
        .swipeActions(content: {
            if let ref = ref, versionManager.localRootPathExists(for: ref) {
                Button(role: .destructive) {
                    versionManager.removeLocalFolder(for: ref)
                } label: {
                    Label("Remove", systemImage: "trash")
                }
            }
        })
        .disabled(compatible == false)

        func iconView() -> Image {
            if let version = ref {
                if version.name == versionManager.installedVersion?.versionString {
                    return Image(systemName: "circle.inset.filled")
                } else if compatible == false {
                    return Image(systemName: "xmark.circle") // unavailable
                } else if versionManager.localRootPathExists(for: version) {
                    return Image(systemName: "circle.dashed.inset.filled")
                } else {
                    return Image(systemName: "circle.dashed")
                }
            } else {
                // no version: using local file system
                return Image(systemName: "arrow.clockwise.circle.fill")
            }
        }
    }
}

struct ModuleRefView<Content: View> : View {
    let ref: HubModuleSource.Ref?
    let content: () -> Content
    @EnvironmentObject var versionManager: HubVersionManager
    @State var loading: Bool = true
    @EnvironmentObject var store: Store

    /// The local expansion path for the ref
    var localPath: URL? {
        if let ref = ref {
            return versionManager.localRootPath(for: ref)
        } else {
            return nil // TODO: return the local path when there is no ref?
        }
    }

    var body: some View {
        if loading == true {
            ProgressView()
                .task(id: ref, { await loadRef(overwrite: true) })
        } else {
            content()
        }
    }

    @discardableResult func loadRef(overwrite: Bool) async -> URL? {
        defer {
            loading = false
        }

        guard let ref = ref else {
            dbg("no ref to load")
            return nil
        }

        defer {
            versionManager.scanFolder()
        }

        return await store.trying {
            guard let localExpandURL = localPath else {
                throw AppError("Unable to find local path for ref archive")
            }
            if FileManager.default.fileExists(atPath: localExpandURL.path) == true {
                if overwrite {
                    dbg("removing:", localExpandURL.path)
                    try FileManager.default.removeItem(at: localExpandURL)
                } else {
                    dbg("returning existing folder:", localExpandURL.path)
                    return localExpandURL
                }
            }
            let url = versionManager.source.archiveURL(for: ref)
            dbg("loading ref:", ref, url)
            let (localURL, response) = try await URLSession.shared.downloadFile(for: URLRequest(url: url))
            dbg("downloaded:", localURL, response.expectedContentLength)
            let progress: Progress? = nil // TODO
            try FileManager.default.unzipItem(at: localURL, to: localExpandURL, progress: progress, trimBasePath: true, overwrite: true)
            dbg("extracted to:", localExpandURL)
            return localExpandURL
        }
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Store())
    }
}
