import FairApp
import Media
import AVKit

/// The main content view for the app.
public struct ContentView: View {
    public var body: some View {
        PlayerView()
            .environmentObject(MediaManager.shared)
    }
}

public struct PlayerView: View {
    static let mediaResource = Result {
        try Bundle.mediaBundle.url(forResource: "Bundle/Sita_Sings_the_Blues.mp4.parts", withExtension: "")?.assemblePartsCache()
    }

    @EnvironmentObject var store: Store
    @EnvironmentObject var manager: MediaManager

    public var body: some View {
        VideoPlayer(player: manager.player) {
            //Text("MEDIA")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            switch Self.mediaResource {
            case .success(let url):
                manager.stream(url: url)
            case .failure(let error):
                dbg("error loading embedded media:", error)
                store.errors.append(error)
            }
        }
    }
}

/// The shared app environment
@MainActor public final class Store: SceneManager {
    @AppStorage("someToggle") public var someToggle = false

    @Published public var errors: [Error] = []
}

public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        WindowGroup {
            ContentView().environmentObject(store)
        }
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store: Store) -> some SwiftUI.View {
        AppSettingsView().environmentObject(store)
    }
}

extension URL {
    /// Attempts to create a cached file based on the contents of the given URL's folder ending with ".parts".
    /// This folder is expected to contain individual files which, when concatinated in alphabetical order, will re-create the specified file
    ///
    /// This allows large files to be split into individual parts to work around [SPM's lack of git LFS support](https://forums.swift.org/t/swiftpm-with-git-lfs/42396/6).
    public func assemblePartsCache(overwrite: Bool = false) throws -> URL {
        let fm = FileManager.default

        if fm.isDirectory(url: self) != true {
            throw CocoaError(.fileReadUnsupportedScheme)
        }

        let cacheBase = self.deletingPathExtension().lastPathComponent
        let cacheFile = try fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: self, create: true).appendingPathComponent(cacheBase)

        let parts = try self.fileChildren(deep: false, keys: [.fileSizeKey, .contentModificationDateKey])
            .filter { fm.isDirectory(url: $0) == false }
            .filter { $0.lastPathComponent.hasPrefix(".") == false }
            .sorting(by: \.lastPathComponent)

        let totalSize = try parts.compactMap({ try $0.fileSize() }).reduce(0, +)
        let lastModified = parts.compactMap(\.modificationDate).sorted().last

        if fm.isReadableFile(atPath: cacheFile.path) && overwrite == false {
            // ensure that the file size is equal to the sum of the individual path components
            // note that we skip any checksum validation here, so we expect the resource to be trusted (which it will be if it is included in a signed app bundle)
            let cacheNewerThanParts = (cacheFile.modificationDate ?? Date()) > (lastModified ?? Date())
            if try cacheFile.fileSize() == totalSize && cacheNewerThanParts == true {
                return cacheFile
            } else {
                if !cacheNewerThanParts {
                    dbg("rebuilding cache file:", cacheFile.path, "modified:", cacheFile.modificationDate, "latest part:", lastModified)
                }
            }
        }

        dbg("assembling parts in", self.path, "into:", cacheFile.path, "size:", totalSize.localizedByteCount(), "from:", parts.map(\.lastPathComponent))

        // clear any existing cache file that we aren't using (e.g., due to bad size)
        try? FileManager.default.removeItem(at: cacheFile)

        // file must exist before writing
        FileManager.default.createFile(atPath: cacheFile.path, contents: nil, attributes: nil)
        let fh = try FileHandle(forWritingTo: cacheFile)
        defer { try? fh.close() }

        for part in parts {
            try fh.write(contentsOf: Data(contentsOf: part))
        }

        return cacheFile
    }

    /// Returns the contents of the given file URL's folder.
    /// - Parameter deep: whether to retrieve the deep or shallow contents
    /// - Parameter skipHidden: whether to skip hidden files
    /// - Parameter keys: resource keys to pre-cache, such as `[.fileSizeKey]`
    /// - Returns: the list of URL children relative to the current URL's folder
    public func fileChildren(deep: Bool, skipHidden: Bool = false, keys: [URLResourceKey]? = nil) throws -> [URL] {
        let fm = FileManager.default

        if fm.isDirectory(url: self) != true {
            throw CocoaError(.fileReadUnknown)
        }

        var mask: FileManager.DirectoryEnumerationOptions = skipHidden ? [.skipsHiddenFiles] : []

        if deep == false {
            // we could alternatively use `enumerator` with the `FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants` mask
            return try fm.contentsOfDirectory(at: self, includingPropertiesForKeys: keys, options: mask) // “the only supported option is skipsHiddenFiles”
        } else {
            #if !os(Linux) && !os(Windows)
            mask.insert(.producesRelativePathURLs) // unavailable on windows
            #endif

            guard let walker = fm.enumerator(at: self, includingPropertiesForKeys: keys, options: mask) else {
                throw CocoaError(.fileReadNoSuchFile)
            }

            var paths: [URL] = []
            for path in walker {
                if let url = path as? URL {
                    paths.append(url)
                } else if let path = path as? String {
                    paths.append(URL(fileURLWithPath: path, relativeTo: self))
                }
            }

            return paths
        }
    }
}


public struct AppSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Toggle(isOn: $store.someToggle) {
            Text("Toggle")
        }
        .padding()
    }
}

@available(macOS 12.0, iOS 15.0, *)
@MainActor final class MediaManager: NSObject, ObservableObject, AVPlayerItemMetadataOutputPushDelegate {
    static let shared = MediaManager()

    @Published var itemTitle: String? = nil
    @Published var playerItem: AVPlayerItem?

    let player: AVPlayer = AVPlayer()

    private override init() {
        super.init()
    }

    func stream(url: URL?) {
        guard let url = url else {
            itemTitle = nil
            return player.replaceCurrentItem(with: nil)
        }

        let asset = AVAsset(url: url)

        let item = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: [AVPartialAsyncProperty<AVAsset>.isPlayable])
        self.playerItem = item

        let metaOutput = AVPlayerItemMetadataOutput(identifiers: [
            AVMetadataIdentifier.commonIdentifierTitle.rawValue,
        ])
        metaOutput.setDelegate(self, queue: DispatchQueue.main)
        item.add(metaOutput)

        player.replaceCurrentItem(with: item)
    }

    func outputSequenceWasFlushed(_ output: AVPlayerItemOutput) {
        dbg(output)
    }

    func metadataOutput(_ output: AVPlayerItemMetadataOutput, didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup], from track: AVPlayerItemTrack?) {

        dbg("received metadata:", output, "groups:", groups, "track:", track)

        if let group = groups.first,
           let item = group.items.first {
            self.itemTitle = item.stringValue ?? "Unknown"
        }
    }
}

