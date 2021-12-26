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
import AVKit
import AVFoundation
import VideoToolbox
import WebKit
import TabularData
import AudioKit
import SwiftUI
#if os(iOS)
import MediaPlayer
#endif

@available(macOS 12.0, iOS 15.0, *)
public struct TuneOutView: View {
    @EnvironmentObject var store: Store
    @SceneStorage("displayMode") var displayMode: TriptychOrient = TriptychOrient.allCases.first!

    public var body: some View {
        TriptychView(orient: $displayMode) {
            Sidebar()
        } list: {
            if let frame = StationCatalog.stationsFrame {
                StationList(title: Text("Stations"), frame: { frame }, hideEmpty: true)
            } else {
                EmptyView()
            }
        } table: {
            #if os(macOS)
            if let frame = StationCatalog.stationsFrame {
                StationsTableView(frame: frame)
            } else {
                EmptyView()
            }
            #endif
        } content: {
            // needs a third placeholder view to get the three-column NavigationView behavior
            Text("Select Station")
                .font(.largeTitle)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItem(id: "DisplayModePicker", placement: .automatic, showsByDefault: true) {
                DisplayModePicker(mode: $displayMode)
            }
        }
        //.environmentObject(RadioTuner.shared) // having this at this high a level results in dreadful performance
    }
}

@available(macOS 12.0, iOS 15.0, *)
extension DataFrame.Row {
    var stationID: Station.UUIDString? {
        self[Station.stationuuidColumn]
    }
}

struct StationRowAccessor : Identifiable {
    let row: DataFrame.Row

    var id: String? { stationID}
    var stationID: String? { row[Station.stationuuidColumn] }
    var stationName: String? { row[Station.nameColumn] }

    var changeuuid: String? { row[Station.changeuuidColumn] }
    var stationuuid: String? { row[Station.stationuuidColumn] }
    var name: String? { row[Station.nameColumn] }
    var url: String? { row[Station.urlColumn] }
    var url_resolved: String? { row[Station.url_resolvedColumn] }
    var homepage: String? { row[Station.homepageColumn] }
    var favicon: String? { row[Station.faviconColumn] }
    var tags: String? { row[Station.tagsColumn] }
    var country: String? { row[Station.countryColumn] }
    var countrycode: String? { row[Station.countrycodeColumn] }
    var iso_3166_2: String? { row[Station.iso_3166_2Column] }
    var state: String? { row[Station.stateColumn] }
    var language: String? { row[Station.languageColumn] }
    var languagecodes: String? { row[Station.languagecodesColumn] }
    //var votes: String? { row[Station.votesColumn] }
    var lastchangetime: String? { row[Station.lastchangetimeColumn] }
    var lastchangetime_iso8601: String? { row[Station.lastchangetime_iso8601Column] }
    var codec: String? { row[Station.codecColumn] }
    var bitrate: Double? { row[Station.bitrateColumn] }
    var hls: String? { row[Station.hlsColumn] }
    var lastcheckok: Int? { row[Station.lastcheckokColumn] }
    //var lastchecktime: Int? { row[Station.lastchecktimeColumn] }
    var lastchecktime_iso8601: String? { row[Station.lastchecktime_iso8601Column] }
    //var lastcheckoktime: String? { row[Station.lastcheckoktimeColumn] }
    var lastcheckoktime_iso8601: String? { row[Station.lastcheckoktime_iso8601Column] }
    //var lastlocalchecktime: String? { row[Station.lastlocalchecktimeColumn] }
    var lastlocalchecktime_iso8601: String? { row[Station.lastlocalchecktime_iso8601Column] }
    //var clicktimestamp: String? { row[Station.clicktimestampColumn] }
    var clicktimestamp_iso8601: String? { row[Station.clicktimestamp_iso8601Column] }
    var clickcount: Int? { row[Station.clickcountColumn] }
    var clicktrend: Int? { row[Station.clicktrendColumn] }
    var ssl_error: String? { row[Station.ssl_errorColumn] }
    var geo_lat: Double? { row[Station.geo_latColumn] }
    var geo_long: Double? { row[Station.geo_longColumn] }
    var has_extended_info: Bool? { row[Station.has_extended_infoColumn] }
}



#if os(macOS)
@available(macOS 12.0, *)
struct StationsTableView : View {
    let frame: DataFrame
    @State var selection: StationRowAccessor.ID? = nil
    @State var sortOrder: [KeyPathComparator<StationRowAccessor>] = []

    private static let stationNameKeypath = \StationRowAccessor.stationName[defaulting: ""]
    private static let stationNameColumn = TableColumn("Station", value: stationNameKeypath, comparator: .localizedStandard)

    var sortedFrame: DataFrame {
        var df = self.frame
        for order in sortOrder {
            if order.keyPath == Self.stationNameKeypath {
                df = df.sorted(on: Station.nameColumn, order: order.order == .forward ? .ascending : .descending)
            }
        }
        return df
    }

    var body: some View {
        Table(frame.rows.map({ StationRowAccessor(row: $0) }), selection: $selection, sortOrder: $sortOrder, columns: {
            //TableColumn("ID", value: \.stationID[defaulting: ""])
            Self.stationNameColumn

//            TableColumn("Home", value: \.stationName[defaulting: ""]) { url in
//                Link(destination: URL(string: url)!)
//            }
            TableColumn("Tags", value: \.tags[defaulting: ""])
            TableColumn("Country", value: \.countrycode[defaulting: ""])
            TableColumn("Languages", value: \.languagecodes[defaulting: ""])
        })
    }
}
#endif

private extension Optional {
    subscript(defaulting defaultValue: Wrapped) -> Wrapped { self ?? defaultValue }
}

@available(macOS 12.0, iOS 15.0, *)
struct StationList<Frame: DataSlice> : View {
    /// The navigation title for this view
    let navTitle: Text

    /// The title of the currently-playing track
    @State var nowPlayingTitle: String? = nil

    //@FocusedBinding(\.selection) var selectionFocus: Station?? // not working
    @State var selectedStation: Station? = nil {
        didSet {
            nowPlayingTitle = nil
        }
    }

    @State var queryString: String = ""

    /// The shuffled identifiers for sorting
    @State var shuffledIDs: [String : Int]? = nil

    //@FocusedValue(\.trackTitle) var trackTitle

    @AppStorage("pinned") var pinnedStations: Set<String> = []
    @AppStorage("searchCount") var searchCount: Int = 250

    let frame: () -> Frame
    /// Whether to only display the table if there is a filter active
    let hideEmpty: Bool

    let sortByName = false

    /// Initialize the the lazilly evaluated frame (which is critical for performance)
    init(title navTitle: Text, frame: @escaping () -> Frame, hideEmpty: Bool = false) {
        self.navTitle = navTitle
        self.frame = frame
        self.hideEmpty = hideEmpty
    }

    var queriedStations: DataFrame.Slice {
        if queryString.isEmpty {
            return frame().prefix(Int.max)
        } else {
            return frame().filter(on: Station.nameColumn, matchesQueryString).prefix(searchCount)
        }
    }

    var sortedStations: DataFrame {
        let stations = self.queriedStations

        if sortByName {
            return stations.sorted(on: Station.nameColumn) { a, b in
                a.localizedCompare(b) == .orderedAscending
            }
        } else {
            return stations.sorted(on: Station.votesColumn, order: .descending)
        }
    }

    var arrangedFrame: DataFrame {
        if let shuffledIDs = shuffledIDs {
            return sortedStations.sorted(on: Station.stationuuidColumn, by: { a, b in
                (shuffledIDs[a] ?? .min) < (shuffledIDs[b] ?? .max)
            })
        } else {
            return sortedStations
        }
    }

    var arrangedRows: DataFrame.Rows {
        arrangedFrame.rows
    }

    var arrangedStations: [DataFrame.Row] {
        arrangedRows.prefix(while: { _ in true })
    }

    func matchesQueryString(name: String?) -> Bool {
        queryString.isEmpty || name?.localizedCaseInsensitiveContains(queryString) == true
    }

    var body: some View {
        Group {
            if hideEmpty == false || !queryString.isEmpty {
                List {
                    ForEach(arrangedStations, id: \.stationID) { station in
                        stationElement(stationRow: station)
                            .frame(height: 50)
                    }
                }
            } else {
                Text("Station List").font(.largeTitle).foregroundColor(.secondary)
            }
        }
        .searchable(text: $queryString, placement: .automatic, prompt: Text("Search"))
        .onSubmit(of: .search) {
            Task {
                print("###")
                //await viewModel.executeQuery()
            }
        }
        .toolbar(id: "navtoolbar") {
            ToolbarItem(id: "previous", placement: ToolbarItemPlacement.accessory(or: .navigation), showsByDefault: true) {
                Button {
                    dbg("previous")
                    selectStation(next: false, query: false)
                } label: {
                    Text("Previous").label(symbol: "backward.frame").symbolVariant(.fill)
                }
                .symbolVariant(.fill)
                .symbolRenderingMode(.hierarchical)
                .disabled(!selectStation(next: false, query: true))
                .keyboardShortcut("[")
                .help(Text("Select the previous station"))
            }

            ToolbarItem(id: "shuffle", placement: ToolbarItemPlacement.navigation, showsByDefault: true) {
                Button {
                    dbg("shuffling")
                    withAnimation {
                        self.shuffledIDs = Dictionary(grouping: frame().rows.compactMap(\.stationID).shuffled().enumerated(), by: \.element).compactMapValues(\.first).mapValues(\.offset)
                        if let randomStation = arrangedRows.first {
                            // shuffling selected the first row in the list
                            self.selectedStation = Station(row: randomStation)
                        }
                    }
                } label: {
                    Text("Shuffle").label(symbol: "shuffle")
                }
                .keyboardShortcut("\\")
                //.symbolVariant(self.shuffledIDs == nil ? .none : .circle)
                .foregroundStyle(self.shuffledIDs == nil ? Color.primary : Color.accentColor)
                .symbolRenderingMode(.hierarchical)
                .help(Text("Shuffle the current selection"))
            }

            ToolbarItem(id: "next", placement: ToolbarItemPlacement.accessory(or: .navigation), showsByDefault: true) {
                Button {
                    dbg("next")
                    selectStation(next: true, query: false)
                } label: {
                    Text("Next").label(symbol: "forward.frame").symbolVariant(.fill)
                }
                .symbolVariant(.fill)
                .symbolRenderingMode(.hierarchical)
                .disabled(!selectStation(next: true, query: true))
                .keyboardShortcut("]")
                .help(Text("Select the next station"))
            }
        }
        .navigation(title: nowPlayingTitleText, subtitle: subtitle)
    }

    @discardableResult func selectStation(next: Bool, query: Bool) -> Bool {
        if queriedStations.shape.rows <= 1 {
            return false
        }

        if !query {
            let stations = (next ? arrangedStations.reversed() : arrangedStations)
            var index = stations.firstIndex(where: { row in
                selectedStation?.stationuuid == row[Station.stationuuidColumn]
            }) ?? 0

            if index == 0 { index = stations.count } // wrap around
            self.selectedStation = Station(row: stations[index-1])
        }

        return true
    }

    /// The title of tjhe currently playing track and station
    var nowPlayingTitleText: Text {
        var title = navTitle
        if let station = self.selectedStation,
           let stationName = station.name,
           !stationName.isEmpty {
            title = title + Text(": ") + Text(stationName)
        }
        return title
    }

    var subtitle: Text? {
        if let nowPlayingTitle = nowPlayingTitle,
           !nowPlayingTitle.isEmpty {
            return Text(nowPlayingTitle)
        } else {
            // it might be better to return nil here, but it messes up the navigation headers
            return Text("")
        }
    }

    func stationElement(stationRow: DataFrame.Row) -> some View {
        let station = Station(row: stationRow)

        @discardableResult func pinned(add: Bool? = nil) -> Bool {
            guard let uuid = station.stationuuid else {
                return false
            }
            if add == true {
                pinnedStations.insert(uuid)
            } else if add == false {
                pinnedStations.remove(uuid)
            }

            return pinnedStations.contains(uuid)
        }

        // Text(station.Name ?? "Unknown")
        return NavigationLink(tag: station, selection: $selectedStation, destination: {
            StationView(station: station, itemTitle: $nowPlayingTitle)
                .environmentObject(RadioTuner.shared)

                //.focusedValue(\.selectedStation, Binding.constant(station)) // causes a hang!
        }) {
            Label(title: { stationLabelTitle(station) }) {
                station.iconView(size: 50)
                    .frame(width: 50)
            }
            .labelStyle(StationLabelStyle())
            //.badge(station.Bitrate ?? wip(0))
            //.badge(station.Votes?.localizedNumber())
        }
        .detailLink(true)
        .swipeActions {
            Button(role: ButtonRole.destructive) {
                pinned(add: !pinned()) // toggle pinned
            } label: {
                Label(title: {
                    Text("Pin")
                }, icon: {
                    Image(systemName: "pin")
                        .symbolVariant(pinned() ? SymbolVariants.slash : SymbolVariants.fill)
                        .disabled(station.stationuuid == nil)
                })
            }
            .tint(.yellow)
        }
    }


    func stationLabelTitle(_ station: Station) -> some View {
        VStack(alignment: .leading) {
            (station.name.map(Text.init) ?? Text("Unknown Name"))
                .font(.title3)
            .lineLimit(1)
            .allowsTightening(true)
            .truncationMode(.middle)


            HStack {
//                if let lang = station.Language, !lang.isEmpty {
//                    (Text("Language: ") + Text(lang))
//                }
//                if let tags = station.Tags, !tags.isEmpty {
//                    (Text("Tags: ") + Text(tags))
//                }


                let br = station.bitrate ?? 0
                (Text(station.bitrate == nil ? Double.nan : Double(br), format: .number) + Text("k"))
                    .foregroundColor(br >= 256 ? Color.green : br < 128 ? Color.gray : Color.blue)
                    .font(.body.monospaced())

                HStack(spacing: 2) {
                    let tags = station.tagElements
                        .compactMap(Station.tagInfo(tagString:))
                        .prefix(10) // maximum of 10 tags we display
                    ForEach(enumerated: tags) { offset, titleImage in
                        titleImage.image
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(titleImage.tint)
                            .help(titleImage.title)
                    }
                }
                .symbolRenderingMode(.monochrome)
                .symbolVariant(.circle)

            }
            .lineLimit(1)
//            .allowsTightening(true)
//            .truncationMode(.middle)
//            .foregroundColor(Color.secondary)
        }
    }
}

extension ToolbarItemPlacement {
    /// A toolbar item that is placed in the bottom accessory on iOS
    static func accessory(or alternative: ToolbarItemPlacement = .automatic) -> Self {
        #if os(iOS)
        Self.bottomBar
        #else
        alternative
        #endif
    }
}

public struct StationLabelStyle : LabelStyle {
    public func makeBody(configuration: LabelStyleConfiguration) -> some View {
        HStack {
            configuration.icon
                .cornerRadius(6)
                .padding(.trailing, 8)
            configuration.title
        }
    }
}

extension Set: RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode(Set<Element>.self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct Sidebar: View {
    @AppStorage("pinned") var pinnedStations: Set<String> = []

    var body: some View {
        List {
            stationsSection
            tagsSection
            countriesSection
            //languagesSection
        }
        .listStyle(SidebarListStyle())
    }

    var languagesSection: some View {
        Section {
            if let frame = StationCatalog.stationsFrame,
               let languageCounts = StationCatalog.languageCounts.successValue {
                ForEach(languageCounts, id: \.value) { lang in
//                    if let langName = (Locale.current as NSLocale).displayName(forKey: .languageCode, value: lang.value) {
//                        Text(langName)
//                    } else {
//                    }

                    let title = Text(lang.value)
                    let languageFrame = {
                        frame.filter(on: Station.languageColumn, { $0 == lang.value })
                    }
                    NavigationLink(destination: StationList(title: Text("Language: ") + title, frame: languageFrame)) {
                        title
                    }
                    .detailLink(false)
                    .badge(lang.count)
                }
            }

        } header: {
            Text("Languages")
        }
    }

    var tagsSection: some View {
        Section {
            if let frame = StationCatalog.stationsFrame {
                ForEach(StationCatalog.tagsCounts.successValue ?? [], id: \.value) { tag in
                    let tagsFrame = {
                        frame.filter(on: Station.tagsColumn, { $0?.tagsSet.contains(tag.value) == true })
                    }
                    // let title = Text(tag.value) // un-localized
                    if let info = Station.tagInfo(tagString: tag.value) {
                        NavigationLink(destination: StationList(title: Text("Tag: ") + info.title, frame: tagsFrame)) {
                            info.title.label(image: info.image.foregroundStyle(info.tint))
                                .symbolVariant(.fill)
                                .badge(tag.count)
                        }
                        .detailLink(false)
                    }
                }
            }
        } header: {
            Text("Tags")
        }
    }

    func sortedCountries(count: Bool) -> [(localName: String?, valueCount: ValueCount<String>)] {
        (StationCatalog.countryCounts.successValue ?? [])
            .map {
                (countryName(for: $0.value), $0)
            }
            .sorted { svc1, svc2 in
                // count
                // ? (svc1.valueCount?.count ?? Int.min) < (svc2.valueCount?.count ?? Int.max)
                // :
                (svc1.localName ?? String(UnicodeScalar(.min))) < (svc2.localName ?? String(UnicodeScalar(.max)))
            }
    }

    func countryName(for code: String) -> String? {
        (Locale.current as NSLocale).displayName(forKey: .countryCode, value: code)
    }

    func stationsSectionTrending(frame: DataFrame, count: Int = 200, title: Text = Text("Trending")) -> some View {
        let trendingFrame = { frame.sorted(on: Station.clicktrendColumn, order: .descending).prefix(count) }
        return NavigationLink(destination: StationList(title: title, frame: trendingFrame)) {
            title.label(symbol: "flame", color: .orange)
        }
        .detailLink(false)
    }

    func stationsSectionPopular(frame: DataFrame, count: Int = 200, title: Text = Text("Popular")) -> some View {
        //let popularFrame = { frame.sorted(on: Station.clickcountColumn, order: .descending).prefix(count) }
        let popularFrame = { frame.sorted(on: Station.votesColumn, order: .descending).prefix(count) }
        return NavigationLink(destination: StationList(title: title, frame: popularFrame)) {
            title.label(symbol: "star", color: .yellow)
        }
        .detailLink(false)
    }

    func stationsSectionQuality(frame: DataFrame, targetBitrate: Double = 320, count: Int = 200, title: Text = Text("Hi–Fi")) -> some View {
        // filted by high-quality audio feeds,
        let selection = {
            frame
                .filter(on: Station.bitrateColumn, { ($0 ?? 0) == targetBitrate }) // things over tend to be video feeds
                .sorted(on: Station.votesColumn, order: .descending)
                .prefix(count)
        }

        return NavigationLink(destination: StationList(title: title, frame: selection)) {
            title.label(symbol: "headphones", color: .yellow)
        }
        .detailLink(false)
    }

    func stationsSectionAll(frame: DataFrame, count: Int = .max, title: Text = Text("All Stations")) -> some View {
        let selection = {
            frame
                .prefix(count)
        }

        return NavigationLink(destination: StationList(title: title, frame: selection)) {
            title.label(symbol: "globe", color: .purple)
        }
        .detailLink(false)
    }

    func stationsSectionPinned(frame: DataFrame, title: Text = Text("Pinned")) -> some View {
        let stationsFrame = {
            frame.filter({ row in
                pinnedStations.contains(row[Station.stationuuidColumn] ?? "")
            })
        }

        return NavigationLink(destination: StationList(title: title, frame: stationsFrame)) {
            title.label(symbol: "pin", color: .green)
        }
        .detailLink(false)
        .badge(pinnedStations.count)
    }

    var stationsSection: some View {
        Section {
            if let frame = StationCatalog.stationsFrame {
                Group {
                    stationsSectionPinned(frame: frame)
                        .keyboardShortcut("1")
                    stationsSectionTrending(frame: frame)
                        .keyboardShortcut("2")
                    stationsSectionPopular(frame: frame)
                        .keyboardShortcut("3")
                    stationsSectionQuality(frame: frame)
                        .keyboardShortcut("4")
                    // too slow, sadly
                    // stationsSectionAll(frame: frame)
                    //     .keyboardShortcut("5")
                }
                .symbolVariant(.fill)
                .symbolRenderingMode(.multicolor)
            }
        } header: {
            Text("Stations")
        }
    }

    var countriesSection: some View {
        Section {
            if let frame = StationCatalog.stationsFrame {
                ForEach(sortedCountries(count: false), id: \.valueCount.value) { country in
                    let title: Text = country.localName.flatMap(Text.init) ?? Text("Unknown")
                    let navTitle = Text("Country: ") + title
                    let countriesFrame = {
                        frame.filter(on: Station.countrycodeColumn, { $0 == country.valueCount.value })
                    }
                    NavigationLink(destination: StationList(title: navTitle, frame: countriesFrame)) {
                        title.label(image: Text(emojiFlag(countryCode: country.valueCount.value.isEmpty ? "UN" : country.valueCount.value)))
                            .badge(country.valueCount.count)
                    }
                    .detailLink(false)
                }
            }
        } header: {
            Text("Countries")
        }
    }

    var categories: Set<String> {
        Set(sources.compactMap(\.category))
    }

    var sources: [Source] {
        (try? Catalog.defaultCatalog.get())?.sources ?? []
    }
}


@available(macOS 12.0, iOS 15.0, *)
struct StationView: View {
    let station: Station
    @State var collapseInfo = false
    @EnvironmentObject var tuner: RadioTuner
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

    let unknown = Text("Unknown")

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
                tuner.player.play()
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
        .navigation(title: station.name.flatMap(Text.init) ?? Text("Unknown Station"), subtitle: itemOrStatonTitle)
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
                    (collapseInfo ? Text("Expand") : Text("Collapse"))
                        .label(image: Image(systemName: collapseInfo ? "chevron.down.circle" : "chevron.up.circle"))
                        .help(Text("Show or hide the station information"))
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
                    Text("Station Name") + Text(":")
                }
                TextField(text: .constant(station.stationuuid ?? ""), prompt: unknown) {
                    Text("ID") + Text(":")
                }
                TextField(text: .constant(station.homepage ?? ""), prompt: unknown) {
                    (Text("Home Page") + Text(":"))
                }
                .overlink(to: station.homepage.flatMap(URL.init(string:)))
                TextField(text: .constant(station.tags ?? ""), prompt: unknown) {
                    Text("Tags") + Text(":")
                }
                TextField(text: .constant(paranthetically(station.country, station.countrycode)), prompt: unknown) {
                    Text("Country") + Text(":")
                }
                TextField(text: .constant(station.state ?? ""), prompt: unknown) {
                    Text("State") + Text(":")
                }
                TextField(text: .constant(paranthetically(station.language, station.languagecodes)), prompt: unknown) {
                    Text("Language") + Text(":")
                }
            }

            Group {
                TextField(text: .constant(station.codec ?? ""), prompt: unknown) {
                    Text("Codec") + Text(":")
                }
                TextField(text: .constant(station.lastchangetime ?? ""), prompt: unknown) {
                    Text("Last Change") + Text(":")
                }
            }

            Group {
                TextField(value: .constant(station.bitrate), format: .number, prompt: unknown) {
                    Text("Bitrate") + Text(":")
                }
                TextField(value: .constant(station.votes), format: .number, prompt: unknown) {
                    Text("Votes") + Text(":")
                }
                TextField(value: .constant(station.clickcount), format: .number, prompt: unknown) {
                    Text("Clicks") + Text(":")
                }
                TextField(value: .constant(station.clicktrend), format: .number, prompt: unknown) {
                    Text("Trend") + Text(":")
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
                        Text("Play").label(symbol: "play")
                    } else {
                        Text("Pause").label(symbol: "pause")
                    }
                }
            }
            .keyboardShortcut(.space, modifiers: [])
            .symbolVariant(.fill)
            .help(self.rate <= 0 ? Text("Play the current track") : Text("Pause the current track"))
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


// TODO: figure out: App[20783:6049981] [] [19:59:59.139] FigICYBytePumpCopyProperty signalled err=-12784 (kFigBaseObjectError_PropertyNotFound) (no such property) at FigICYBytePump.c:1396


@available(macOS 12.0, iOS 15.0, *)
@MainActor final class RadioTuner: NSObject, ObservableObject, AVPlayerItemMetadataOutputPushDelegate {
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
