import FairApp
import JXSwiftUI
import JXKit
import JXPod
import JXBridge
import PetStore

public protocol JXDynamicModule : JXModule {
    static var localURL: URL? { get }
    static var remoteURL: URL? { get }
}

extension PetStoreModule: JXDynamicModule {
}

extension JXDynamicModule {
    /// The tags for this module
    public static var tags: [(tag: String, date: Date)] {
        get async throws {
            return try await source.tags
        }
    }

    public static var versions: [SemVer: URL] {
        get async throws {
            return try await source.versions
        }
    }

    static var source: HubModuleSource {
        get throws {
            guard let remoteBase = Self.remoteURL?.baseURL else {
                throw URLError(.badURL)
            }
            guard remoteBase.pathExtension == "git" else {
                throw URLError(.unsupportedURL) // only .git URL bases are accepted
            }

            return HubModuleSource(repository: remoteBase)
        }
    }
}

public protocol ModuleSource {
    /// The available tags for this source
    var tags: [(tag: String, date: Date)] { get async throws }

    /// The URL for downloading an archive of the module at the given tag
    func archiveURL(for tag: String) -> URL
}

/// A module source that uses a GitHub repository's tags and zipball archive URL for checking versions.
public struct HubModuleSource : ModuleSource {
    // GitHub:
    //  repository: https://github.com/ORG/REPO.git
    //  tag list: https://github.com/ORG/REPO/tags.atom
    //  download: https://github.com/ORG/REPO/archive/refs/tags/TAG.zip

    // Gitea:
    //  repository: https://try.gitea.io/ORG/REPO.git
    //  tag list: https://try.gitea.io/ORG/REPO/tags.atom
    //  download: https://try.gitea.io/ORG/REPO/archive/TAG.zip

    // GitLab:
    //  repository: https://gitlab.com/ORG/REPO.git
    //  tag list: ???
    //  download: https://gitlab.com/ORG/REPO/-/archive/TAG/REPO-TAG.zip

    public let repository: URL // e.g., https://github.com/Magic-Loupe/PetStore.git

    public init(repository: URL) {
        self.repository = repository
    }

    func url(_ relativeTo: String) -> URL {
        // convert "/PetStore.git" to "/PetStore"
        repository.deletingPathExtension().appendingPathComponent(relativeTo, isDirectory: false)
    }

    /// Returns true if the repository is managed by the given host
    func isHost(_ domain: String) -> Bool {
        ("." + (repository.host ?? "")).hasSuffix(domain)
    }

    public func archiveURL(for tag: String) -> URL {
        if isHost("github.com") {
            return url("archive/refs/tags/" + tag).appendingPathExtension("zip")
        } else if isHost("gitlab.com") {
            let repo = repository.pathComponents.dropFirst().first ?? "" // extract REPO from https://gitlab.com/ORG/REPO/…
            return url("-/archive/" + tag + "/" + repo + "-" + tag).appendingPathExtension("zip")
        } else { // Gitea-style
            return url("archive/" + tag).appendingPathExtension("zip")
        }
    }

    public var tags: [(tag: String, date: Date)] {
        get async throws {
            let (data, _) = try await URLSession.shared.fetch(request: URLRequest(url: url("tags.atom")))
            let feed = try RSSFeed.parse(xml: data)
            return feed.feed.entry.collectionMulti.map({ ($0.title, $0.updated) })
        }
    }

    /// All the tags that can be parsed as a `SemVer`.
    public var tagVersions: [SemVer] {
        get async throws {
            try await tags.map(\.tag).compactMap(SemVer.init(string:))
        }
    }

    /// The versions available, along with the associated download URL.
    public var versions: [SemVer: URL] {
        get async throws {
            try await tagVersions.map({ ($0, archiveURL(for: $0.versionString)) }).dictionary(keyedBy: \.0).mapValues(\.1)
        }
    }
}

extension RSSFeed {
    /// Parses the given XML as an RSS feed
    static func parse(xml: Data) throws -> Self {
        try RSSFeed(jsum: XMLNode.parse(data: xml).jsum(), options: .init(dateDecodingStrategy: .iso8601))
    }
}

/// A minimal RSS feed implementation for parsing GitHub tag feeds like https://github.com/Magic-Loupe/PetStore/tags.atom
struct RSSFeed : Decodable {
    var feed: Feed

    struct Feed : Decodable {
        var id: String // tag:github.com,2008:https://github.com/Magic-Loupe/PetStore/releases
        var title: String
        var updated: Date

        /// The list of links, which when converted from XML might be translated as a single or multiple element
        typealias LinkList = ElementOrArray<Link> // i.e. XOr<Link>.Or<[Link]>
        var link: LinkList

        struct Link : Decodable {
            var type: String // text/html
            var rel: String // alternate
            var href: String // https://github.com/Magic-Loupe/PetStore/releases
        }

        /// The list of entries, which when converted from XML might be translated as a single or multiple element
        typealias EntryList = ElementOrArray<Entry> // i.e. XOr<Entry>.Or<[Entry]>
        var entry: EntryList

        struct Entry : Decodable {
            var id: String // tag:github.com,2008:Repository/584868941/0.0.2
            var title: String // 0.0.2
            var updated: Date // "2023-01-03T20:28:34Z"
            var link: LinkList // https://github.com/Magic-Loupe/PetStore/releases/tag/0.0.2

//            var author: Author
//
//            struct Author : Decodable {
//                var name: String
//            }
//
//            var thumbnail: Thumbnail
//
//            struct Thumbnail : Decodable {
//                var height: String // 30
//                var width: String // 30
//                var url: URL // https://avatars.githubusercontent.com/u/659086?s=60&v=4
//            }
        }
    }
}
