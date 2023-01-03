import FairApp
import JXSwiftUI
import JXKit
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

struct PlaygroundListView: View {
    var body: some View {
        List {
            Section("Applications") {
                NavigationLink {
                    LazyView(view: { PetStoreView() })
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Pet Store", bundle: .module, comment: "list title for pet store app")
                            Text("Version: \(PetStoreVersion)", bundle: .module, comment: "list comment title describing the current version")
                                .font(.footnote)
                        }
                    } icon: {
                        // Image(systemName: "building")
                        EmptyView()
                    }

                }
            }
        }
        .navigationTitle("Showcase")
        .refreshable {
            await refreshModules()
        }
        .task {
            await refreshModules()
        }
    }

    func refreshModules() async {
        dbg("refreshing modules")
        // TODO: check the latest versions of all the available modules
        do {
            let updateURL = URL(string: "https://github.com/Magic-Loupe/PetStore/tags.atom")!
            let (data, response) = try await URLSession.shared.fetch(request: URLRequest(url: updateURL))
            dbg(response, data.count)
            let parsed = try XMLNode.parse(data: data).jsum()
            dbg(parsed)
            let feed = try RSSFeed(jsum: parsed, options: .init(dateDecodingStrategy: .iso8601))
            dbg("feed:", feed)
        } catch {
            dbg("error getting source")
        }
    }
}

/// A minimal RSS feed implementation of parsing GitHub tag feeds like https://github.com/Magic-Loupe/PetStore/tags.atom
public struct RSSFeed : Decodable {
    public var feed: Feed

    public struct Feed : Decodable {
        public var id: String // tag:github.com,2008:https://github.com/Magic-Loupe/PetStore/releases
        public var title: String
        public var updated: Date

        public var link: [Link]
        public struct Link : Decodable {
            public var type: String // text/html
            public var rel: String // alternate
            public var href: String // https://github.com/Magic-Loupe/PetStore/releases
        }

        public var entry: [Entry]
        public struct Entry : Decodable {
            public var id: String // tag:github.com,2008:Repository/584868941/0.0.2
            public var title: String // 0.0.2
            public var updated: Date // "2023-01-03T20:28:34Z"
            public var link: [Link] // https://github.com/Magic-Loupe/PetStore/releases/tag/0.0.2
            // content:
            public var author: Author

            public struct Author : Decodable {
                public var name: String
            }

            public var thumbnail: Thumbnail

            public struct Thumbnail : Decodable {
                public var height: String // 30
                public var width: String // 30
                public var url: URL // https://avatars.githubusercontent.com/u/659086?s=60&v=4
            }
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
