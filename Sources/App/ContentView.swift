import FairApp
import JXHost

import AboutMe
import AnimalFarm
import DatePlanner
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
    @MainActor @ViewBuilder static func entryLink<V: View>(host: Bundle?, name: String, symbol: String, branches: [String], view: @escaping (JXContext) -> V) -> some View {
        let version = host?.packageVersion(for: Self.remoteURL.baseURL)
        let source = Self.hubSource
        NavigationLink {
            ModuleVersionsListView(appName: name, branches: branches) { ctx in
                view(ctx) // the root view that will be shown
            }
            .environmentObject(source.versionManager(for: self, refName: version))
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

extension Bundle {
    /// Returns the parsed `Package.resolved` embedded in this bundle.
    ///
    /// The file is the output of `swift package resolve`, and will contain information about the individual versions of the dependencies of the app.
    ///
    /// - Note: The `Package.resolved` must be manually included in the bundle's `Resources/` through a build rule.
    static let packageResolved = {
        Result {
            try ResolvedPackage(json: Bundle.module.loadResource(named: "Package.resolved"))
        }
    }()

    func findVersion(repository: URL?, in packages: [(url: String, version: String?)]) -> String? {
        for (url, version) in packages {
            // note that some repositories have the ".git" extension and some do not; compare them by trimming the extension
            if url == repository?.absoluteString
                || url == repository?.deletingPathExtension().absoluteString {
                // the package matches, so return the version, which might be a
                //dbg("package version found for", repository, version)
                return version
            }
        }

        //dbg("no package version found for", repository)
        return nil
    }

    /// Returns the version of the package from the "Package.resolved" that is bundled with this app.
    func packageVersion(for repository: URL?) -> String? {
        dbg(repository)
        do {
            let resolved = try Self.packageResolved.get()
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

struct PlaygroundListView: View {
    @EnvironmentObject var store: Store

    /// Returns the branches to display in the versions list, which will be contingent on development mode being enabled.
    var branches: [String] {
        store.developmentMode == true ? ["main"] : []
    }

    var body: some View {
        List {
            Section("Sample Apps") {
                PetStoreModule.entryLink(host: .module, name: "Pet Store", symbol: "hare", branches: branches) { ctx in
                    PetStoreView(context: ctx)
                }
                AnimalFarmModule.entryLink(host: .module, name: "Animal Farm", symbol: "pawprint", branches: branches) { ctx in
                    AnimalFarmView(context: ctx)
                }
                AboutMeModule.entryLink(host: .module, name: "About Me", symbol: "person", branches: branches) { ctx in
                    AboutMeView(context: ctx)
                }
                DatePlannerModule.entryLink(host: .module, name: "Date Planner", symbol: "calendar", branches: branches) { ctx in
                    DatePlannerView(context: ctx)
                }
                // add more applications here…
            }
            .symbolVariant(.fill)
        }
        .navigationTitle("Showcase")
    }
}


/// A view that displays a sectioned list of navigation links to individual versions of a module.
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
            versionManager.scanModuleFolder()
            await versionManager.refreshModules()
        }
        .task {
            versionManager.scanModuleFolder()
            await versionManager.refreshModules()
        }
    }

    func log(_ value: String) {
        dbg(value)
    }

    struct LocalScriptLoader : JXScriptLoader {
        let baseURL: URL

        func scriptURL(resource: String, relativeTo: URL?, root: URL) throws -> URL {
            // we ignore the passed-in root and instead use our own base URL
            // let url = URL(fileURLWithPath: resource, relativeTo: self.baseURL) // relative doesn't seem to work
            let url = baseURL.appendingPathComponent(resource)
            dbg("resolved:", resource, "as:", url.path)
            return url
        }

        func loadScript(from url: URL) throws -> String? {
            //dbg(url.absoluteString)
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
        return ModuleRefPresenterView(appName: appName, ref: ref, date: date, versionManager: versionManager, compatible: compatible) {
            viewBuilder(createContext(for: ref))
        }
        .swipeActions(edge: .leading, content: {
            // show either a remove or download button, depending on whether the ref is currently downloaded
            if let ref = ref {
                if versionManager.localRootPathExists(for: ref) {
                    Button() {
                        versionManager.removeLocalFolder(for: ref)
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                    .tint(.red)
                } else {
                    Button() {
                        Task {
                            await store.trying {
                                try await versionManager.downloadArchive(for: ref, overwrite: true)
                            }
                        }
                    } label: {
                        Label("Download", systemImage: "square.and.arrow.down.fill")
                    }
                    .tint(.yellow)
                }
            }
        })
        .disabled(compatible == false)
    }
}

struct ModuleRefPresenterView<V: View>: View {
    let appName: String
    let ref: HubModuleSource.Ref?
    let date: Date?
    let versionManager: HubVersionManager
    let compatible: Bool?
    let viewBuilder: () -> V
    
    @State var isPresented = false

    var body: some View {
        Button(action: { isPresented = true }) {
            Label {
                VStack(alignment: .leading) {
                    //Text(appName)
                    HStack {
                        // if latest == true {
                        //     Text("Latest", bundle: .module, comment: "prefix for string that is the most recent string")
                        // }
                        if let ref = ref {
                            Text(ref.name)
                        } else {
                            Text(appName)
                        }
                        Spacer()
                        if let date = date {
                            Text("\(date, format: .relative(presentation: .named, unitsStyle: .abbreviated))", bundle: .module, comment: "list comment title describing the current version")
                                .font(.caption.monospacedDigit())
                        }
                    }
                    //.font(.footnote.monospacedDigit())
                }
            } icon: {
                iconView()
            }
            //.labelStyle(CentreAlignedLabelStyle())
            .frame(alignment: .center)
        }
        .sheet(isPresented: $isPresented) {
            ModuleRefView(ref: ref) { viewBuilder() }
                .environmentObject(versionManager)
        }
    }

    @MainActor func iconView() -> Image {
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

struct ModuleRefView<Content: View> : View {
    let ref: HubModuleSource.Ref?
    let content: () -> Content
    @EnvironmentObject var versionManager: HubVersionManager
    @State var loading: Bool = true
    @EnvironmentObject var store: Store

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

        return await store.trying {
            try await versionManager.downloadArchive(for: ref, overwrite: overwrite)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Store())
    }
}
