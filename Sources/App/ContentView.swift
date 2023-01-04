import FairApp
import JXSwiftUI
import JXKit
import JXPod
import PetStore
import AnimalFarm

/// The main content view for the app. This is the starting point for customizing you app's behavior.
struct ContentView: View {
    let context = JXContext()
    @EnvironmentObject var store: Store

    var body: some View {
        NavigationView {
            PlaygroundListView()
        }
    }
}

// TODO: move JXDynamicModule down to JXBride and move implementation into PetStore and AnimalFarm themselves
extension PetStoreModule : JXDynamicModule {
}

extension AnimalFarmModule : JXDynamicModule {
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
            dbg("available refs:", refs)
        } catch {
            dbg("error getting source:", error)
        }
    }
}

struct PlaygroundListView: View {
    var body: some View {
        List {
            Section("Applications") {
                if let source = try? PetStoreModule.hubSource {
                    NavigationLink("Pet Store") {
                        ModuleVersionsListView(appName: "Pet Store", versionManager: HubVersionManager(source: source, installedVersion: PetStoreVersion.flatMap(SemVer.init(string:)))) {
                            PetStoreView() // the root view that will be shown
                        }
                    }
                }

                if let source = try? AnimalFarmModule.hubSource {
                    NavigationLink("Animal Farm") {
                        ModuleVersionsListView(appName: "Animal Farm", versionManager: HubVersionManager(source: source, installedVersion: AnimalFarmVersion.flatMap(SemVer.init(string:)))) {
                            AnimalFarmView() // the root view that will be shown
                        }
                    }
                }

                // TODO: add more applications here…
            }
        }
        .navigationTitle("Showcase")
    }
}


struct ModuleVersionsListView<V: View>: View {
    let appName: String
    @StateObject var versionManager: HubVersionManager
    let viewBuilder: () -> V

    var body: some View {
        List {
            Section("Versions") {
                ForEach(versionManager.refs, id: \.ref.name) { refDate in
                    moduleVersionLink(version: refDate.ref, date: refDate.date)
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
            LazyView(view: { viewBuilder() })
        } label: {
            Label {
                VStack(alignment: .leading) {
                    Text(appName)
                    Text("\(version.name) (\(date ?? .now, format: .relative(presentation: .named, unitsStyle: .abbreviated)))", bundle: .module, comment: "list comment title describing the current version")
                        .font(.footnote)
                }
            } icon: {
                iconView()
            }
            //            .disabled(compatible == false)
            .frame(alignment: .center)
        }

        @ViewBuilder func iconView() -> some View {
            if version.name == versionManager.installedVersion?.versionString {
                Image(systemName: "checkmark.circle.fill")
                    .tint(.green)
            } else if compatible != true {
                Image(systemName: "xmark.circle")
                    .tint(.red)
            } else {
                Image(systemName: "circle")
                    .tint(.accentColor)
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
