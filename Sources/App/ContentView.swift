import FairApp
import JXSwiftUI
import JXKit
import JXPod
import PetStore

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

@MainActor class PetStoreVersionManager : ObservableObject {
    /// All the available tags and their dates for the pet store module
    @Published var tags: [(tag: String, date: Date?)] = [(PetStoreVersion ?? "", nil)]

    /// The currently-active version of the local module
    @Published var currentVersion = PetStoreVersion.flatMap(SemVer.init(string:))

    init() {
    }

    func refreshModules() async {
        dbg("refreshing modules")
        do {
            self.tags = try await PetStoreModule.tags
            dbg("available tags:", tags)
        } catch {
            dbg("error getting source")
        }
    }

}

struct PlaygroundListView: View {
    @StateObject var versionManager = PetStoreVersionManager()

    var body: some View {
        List {
            Section("Versions") {
                ForEach(versionManager.tags, id: \.tag) { tagDate in
                    petStoreVersionLink(version: tagDate.tag, date: tagDate.date)
                }
            }
        }
        .navigationTitle("Showcase")
        .refreshable {
            await versionManager.refreshModules()
        }
        .task {
            await versionManager.refreshModules()
        }
    }

    func petStoreVersionLink(version: String, date: Date?) -> some View {
        NavigationLink {
            LazyView(view: { PetStoreView() })
        } label: {
            Label {
                VStack(alignment: .leading) {
                    Text("Pet Store", bundle: .module, comment: "list title for pet store app")
                    Text("version \(version) (\(date ?? .now, format: .relative(presentation: .named, unitsStyle: .abbreviated)))", bundle: .module, comment: "list comment title describing the current version")
                        .font(.footnote)
                }
            } icon: {
                if version == PetStoreVersion {
                    Image(systemName: "checkmark.circle.fill")
                } else if SemVer(string: version)?.minorCompatible(with: versionManager.currentVersion) != true {
                    Image(systemName: "xmark.circle")
                } else {
                    Image(systemName: "circle")
                }
            }
        }
    }
}

extension SemVer {
    /// True when the major and minor versions are the same as the other version
    func minorCompatible(with version: SemVer?) -> Bool {
        self.major == version?.major && self.minor == version?.minor
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
