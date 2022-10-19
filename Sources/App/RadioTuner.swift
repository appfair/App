import FairApp
import AVKit

// TODO: figure out: App[20783:6049981] [] [19:59:59.139] FigICYBytePumpCopyProperty signalled err=-12784 (kFigBaseObjectError_PropertyNotFound) (no such property) at FigICYBytePump.c:1396


class RadioTunerBase: NSObject, ObservableObject {
}

extension RadioTunerBase : AVPlayerItemMetadataOutputPushDelegate {

}

@MainActor final class RadioTuner: RadioTunerBase {
    static let shared = RadioTuner()

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

        let metaOutput = AVPlayerItemMetadataOutput(identifiers: allAVMetadataIdentifiers.map(\.rawValue))
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

/// Converts a country code like "US" into the Emoji symbol for the country
func emojiFlag(countryCode: String) -> String {
    let codes = countryCode.unicodeScalars.compactMap {
        UnicodeScalar(127397 + $0.value)
    }
    return String(codes.map(Character.init))
}

