import FairApp
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
