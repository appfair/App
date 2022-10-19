/**
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import FairApp
import FairKit
import AVKit
import AVFoundation
import VideoToolbox
import WebKit
import SwiftUI
#if os(iOS)
import MediaPlayer
#endif
#if canImport(TabularDataXXX)
import TabularData
#endif


struct StationView: View {
    let station: Station
    @State var collapseInfo = false
    @EnvironmentObject var tuner: RadioTuner
    @EnvironmentObject var store: Store
    @Binding var itemTitle: String?
    /// The current play rate
    @State var rate: Float = 0.0

    init(station: Station, itemTitle: Binding<String?>) {
        self.station = station
        self._itemTitle = itemTitle
    }

    #if os(iOS)
    typealias VForm = VStack
    #else
    typealias VForm = Form
    #endif

    let unknown = Text("Unknown", bundle: .module, comment: "generic unknown label")

    var body: some View {
        VideoPlayer(player: tuner.player) {
            ZStack {
                Rectangle()
                    .fill(.clear)
                    .background(Material.ultraThin)
                    .opacity(collapseInfo ? 0.0 : 1.0)

                ScrollView {
                    Section(header: sectionHeaderView()) {
                        if !collapseInfo {
                            trackInfoView()
                            //.editable(false)
                            .textFieldStyle(.roundedBorder)
                            .disableAutocorrection(true)
                        }

                        Spacer()
                    }
                    .padding()

                }
            }
            //.textFieldStyle(.plain)
            //.background(station.imageView().blur(radius: 20, opaque: true))
            //.background(Material.thin)
            //.frame(maxHeight: collapseInfo ? 40 : nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: AVPlayer.rateDidChangeNotification, object: tuner.player)) { note in
            // the rate change is also how we know if the player is started or stopped
            self.rate = (note.object as! AVPlayer).rate
        }
        .onAppear {
            //tuner.player.prepareToPlay()
            if let url = station.streamingURL {
                tuner.stream(url: url)
                if store.autoplayStation == true {
                    tuner.player.play()
                } else {
                    tuner.player.pause()
                }
            } else {
                tuner.player.pause()
            }
        }
        .onDisappear {
            tuner.stream(url: nil)
            tuner.player.pause()
        }
        .toolbar(id: "playpausetoolbar") {
            playPauseToolbarItem()
        }
        .onChange(of: tuner.itemTitle, perform: updateTitle)
        //.preference(key: TrackTitleKey.self, value: tuner.itemTitle)
        //.focusedSceneValue(\.trackTitle, tuner.itemTitle)
        .navigation(title: station.name.flatMap(Text.init) ?? Text("Unknown Station", bundle: .module, comment: "title for a station that is not known"), subtitle: itemOrStatonTitle)
    }

    var itemOrStatonTitle: Text {
        Text(tuner.itemTitle ?? station.name ?? "")
    }

    func sectionHeaderView() -> some View {
        ZStack {
            // the background buttons
            HStack {
                station
                    .iconView(size: 50, blurFlag: 0)

                itemOrStatonTitle
                    .textSelection(.enabled)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity)
                    .help(itemOrStatonTitle)

                Button {
                    withAnimation {
                        collapseInfo.toggle()
                    }
                } label: {
                    (collapseInfo ? Text("Expand", bundle: .module, comment: "expand section title") : Text("Collapse", bundle: .module, comment: "collapse section title"))
                        .label(image: Image(systemName: collapseInfo ? "chevron.down.circle" : "chevron.up.circle"))
                        .help(Text("Show or hide the station information", bundle: .module, comment: "expand/collapse tooltip title"))
                }
                .hoverSymbol(activeVariant: .fill, inactiveVariant: .none, animation: .easeInOut)
                .symbolRenderingMode(.hierarchical)
                .buttonStyle(PlainButtonStyle())
                .labelStyle(.iconOnly)
            }
            .font(.largeTitle) // also affects the symbol size
            .frame(maxHeight: 50)
        }
    }

    func trackInfoView() -> some View {
        VForm { // doesn't scroll correctly in iOS if this is a Form, but VStack does work
            Group {
                TextField(text: .constant(station.name ?? ""), prompt: unknown) {
                    Text("Station Name:", bundle: .module, comment: "text field label")
                }
                TextField(text: .constant(station.stationuuid ?? ""), prompt: unknown) {
                    Text("ID:", bundle: .module, comment: "text field label")
                }
                TextField(text: .constant(station.homepage ?? ""), prompt: unknown) {
                    Text("Home Page:", bundle: .module, comment: "text field label")
                }
                //.overlink(to: station.homepage.flatMap(URL.init(string:)))
                TextField(text: .constant(station.tags ?? ""), prompt: unknown) {
                    Text("Tags:", bundle: .module, comment: "text field label")
                }
                TextField(text: .constant(paranthetically(station.country, station.countrycode)), prompt: unknown) {
                    Text("Country:", bundle: .module, comment: "text field label")
                }
                TextField(text: .constant(station.state ?? ""), prompt: unknown) {
                    Text("State:", bundle: .module, comment: "text field label")
                }
                TextField(text: .constant(paranthetically(station.language, station.languagecodes)), prompt: unknown) {
                    Text("Language:", bundle: .module, comment: "text field label")
                }
            }

            Group {
                TextField(text: .constant(station.codec ?? ""), prompt: unknown) {
                    Text("Codec:", bundle: .module, comment: "text field label")
                }
                TextField(text: .constant(station.lastchangetime ?? ""), prompt: unknown) {
                    Text("Last Change:", bundle: .module, comment: "text field label")
                }
            }

            Group {
                TextField(value: .constant(station.bitrate), format: .number, prompt: unknown) {
                    Text("Bitrate:", bundle: .module, comment: "text field label")
                }
                TextField(value: .constant(station.votes), format: .number, prompt: unknown) {
                    Text("Votes:", bundle: .module, comment: "text field label")
                }
                TextField(value: .constant(station.clickcount), format: .number, prompt: unknown) {
                    Text("Clicks:", bundle: .module, comment: "text field label")
                }
                TextField(value: .constant(station.clicktrend), format: .number, prompt: unknown) {
                    Text("Trend:", bundle: .module, comment: "text field label")
                }
            }
        }
    }

    func paranthetically(_ first: String?, _ second: String?) -> String {
        switch (first, second) {
        case (.none, .none): return ""
        case (.some(let s1), .none): return "\(s1)"
        case (.none, .some(let s2)): return "(\(s2))"
        case (.some(let s1), .some(let s2)): return "\(s1) (\(s2))"
        }
    }

    func playPauseToolbarItem() -> some CustomizableToolbarContent {
        ToolbarItem(id: "playpause", placement: ToolbarItemPlacement.navigation, showsByDefault: true) {
            Button {
                if self.rate <= 0 {
                    dbg("playing")
                    tuner.player.play()
                } else {
                    dbg("pausing")
                    tuner.player.pause()
                }
            } label: {
                Group {
                    if self.rate <= 0 {
                        Text("Play", bundle: .module, comment: "play button title").label(symbol: "play")
                    } else {
                        Text("Pause", bundle: .module, comment: "pause button title").label(symbol: "pause")
                    }
                }
            }
            .keyboardShortcut(.space, modifiers: [])
            .symbolVariant(.fill)
            .help(self.rate <= 0 ? Text("Play the current track", bundle: .module, comment: "play button tooltip") : Text("Pause the current track", bundle: .module, comment: "pause button tooltip"))
        }
//        } else {
//            ToolbarItem(id: "play", placement: ToolbarItemPlacement.accessory(), showsByDefault: true) {
//                Button {
//                    dbg("playing")
//                    tuner.player.play()
//                } label: {
//                    Text("Play").label(symbol: "play").symbolVariant(.fill)
//                }
//                .keyboardShortcut(.space, modifiers: [])
//                .disabled(self.rate > 0)
//                .help(Text("Play the current track"))
//            }
//            ToolbarItem(id: "pause", placement: ToolbarItemPlacement.accessory(), showsByDefault: true) {
//                Button {
//                    dbg("pausing")
//                    tuner.player.pause()
//                } label: {
//                    Text("Pause").label(symbol: "pause").symbolVariant(.fill)
//                }
//                .keyboardShortcut(.space, modifiers: [])
//                .disabled(self.rate == 0)
//                .help(Text("Pause the current track"))
//            }
//        }
    }

    func updateTitle(title: String?) {
        self.itemTitle = title

        #if os(iOS)
        // NOTE: seems to not be working yet

        // update the shared playing information for the lock screen
        let center = MPNowPlayingInfoCenter.default()
        var info = center.nowPlayingInfo ?? [String: Any]()

        //let title = "title"
        //let album = "album"

        info[MPMediaItemPropertyTitle] = title
        info[MPMediaItemPropertyAlbumTitle] = station.name

        if false {
            let artworkData = Data()
            let image = UIImage(data: artworkData) ?? UIImage()

            // TODO: use iconView() by wrapping it in UXViewRep
            let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: {  (_) -> UIImage in
                return image
            })
            info[MPMediaItemPropertyArtwork] = artwork
        }


        center.nowPlayingInfo = info
        #endif
    }
}


struct StationLabelStyle : LabelStyle {
    public func makeBody(configuration: LabelStyleConfiguration) -> some View {
        HStack {
            configuration.icon
                .cornerRadius(6)
                .padding(.trailing, 8)
            configuration.title
        }
    }
}
