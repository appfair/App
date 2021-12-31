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
    @EnvironmentObject var store: Store
    @EnvironmentObject var manager: MediaManager

    public var body: some View {
        VideoPlayer(player: manager.player) {
            //Text("MEDIA")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            manager.stream(url: Bundle.mediaBundle.url(forResource: "Bundle/Sita_Sings_the_Blues", withExtension: "mp4"))
        }
    }
}

/// The shared app environment
@MainActor public final class Store: SceneManager {
    @AppStorage("someToggle") public var someToggle = false
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

