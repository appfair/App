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
    @MainActor @ViewBuilder static func entryLink<V: View>(store: Store, host: Bundle?, name: String, symbol: String, branches: [String], view: @escaping (JXContext) -> V) -> some View {
        let version = host?.packageVersion(for: Self.remoteURL.baseURL)
        let source = Self.hubSource
        NavigationLink {
            ModuleVersionsListView(versionManager: source.versionManager(for: self, refName: version), appName: name, branches: branches, developmentMode: store.developmentMode, strictMode: store.strictMode, errorHandler: { store.reportError($0) }) { ctx in
                view(ctx) // the root view that will be shown
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
                PetStoreModule.entryLink(store: store, host: .module, name: "Pet Store", symbol: "hare", branches: branches) { ctx in
                    PetStoreView(context: ctx)
                }
                AnimalFarmModule.entryLink(store: store, host: .module, name: "Animal Farm", symbol: "pawprint", branches: branches) { ctx in
                    AnimalFarmView(context: ctx)
                }
                AboutMeModule.entryLink(store: store, host: .module, name: "About Me", symbol: "person", branches: branches) { ctx in
                    AboutMeView(context: ctx)
                }
                DatePlannerModule.entryLink(store: store, host: .module, name: "Date Planner", symbol: "calendar", branches: branches) { ctx in
                    DatePlannerView(context: ctx)
                }
                // add more applications here…
            }
            .symbolVariant(.fill)
        }
        .navigationTitle("Showcase")
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
