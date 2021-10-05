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

/// To fetch the latest catalog, run:
/// curl https://nl1.api.radio-browser.info/csv/stations/search > Sources/App/Resources/stations.csv
@available(macOS 12.0, iOS 15.0, *)
struct Station : Pure {
    // possible, but slow to parse
    //typealias DateString = Date
    typealias DateString = String
    typealias URLString = String
    typealias UUIDString = String

    var changeuuid: UUIDString?
    var stationuuid: UUIDString?
    var name: String?
    var url: URLString?
    var url_resolved: URLString?
    var homepage: URLString?
    var favicon: URLString?
    var tags: String?
    var country: String?
    var countrycode: String?
    var iso_3166_2: String?
    var state: String?
    var language: String?
    var languagecodes: String?
    var votes: Int?
    var lastchangetime: DateString?
    var lastchangetime_iso8601: DateString?
    var codec: String? // e.g., "MP3" or "AAC,H.264"
    var bitrate: Double?
    var hls: DateString?
    var lastcheckok: DateString?
    var lastchecktime: DateString?
    var lastchecktime_iso8601: DateString?
    var lastcheckoktime: DateString?
    var lastcheckoktime_iso8601: DateString?
    var lastlocalchecktime: DateString?
    var lastlocalchecktime_iso8601: DateString?
    var clicktimestamp: DateString?
    var clicktimestamp_iso8601: DateString?
    var clickcount: Int?
    var clicktrend: Int?
    var ssl_error: String?
    var geo_lat: Double?
    var geo_long: Double?
    var has_extended_info: Bool?

    static let changeuuidColumn = ColumnID("changeuuid", UUIDString.self)
    static let stationuuidColumn = ColumnID("stationuuid", UUIDString.self)
    static let nameColumn = ColumnID("name", String.self)
    static let urlColumn = ColumnID("url", URLString.self)
    static let url_resolvedColumn = ColumnID("url_resolved", URLString.self)
    static let homepageColumn = ColumnID("homepage", URLString.self)
    static let faviconColumn = ColumnID("favicon", URLString.self)
    static let tagsColumn = ColumnID("tags", String.self)
    static let countryColumn = ColumnID("country", String.self)
    static let countrycodeColumn = ColumnID("countrycode", String.self)
    static let iso_3166_2Column = ColumnID("iso_3166_2", String.self)
    static let stateColumn = ColumnID("state", String.self)
    static let languageColumn = ColumnID("language", String.self)
    static let languagecodesColumn = ColumnID("languagecodes", String.self)
    static let votesColumn = ColumnID("votes", Int.self)
    static let lastchangetimeColumn = ColumnID("lastchangetime", DateString.self)
    static let lastchangetime_iso8601Column = ColumnID("lastchangetime_iso8601", DateString.self)
    static let codecColumn = ColumnID("codec", String.self) // e.g., "MP3" or "AAC,H.264.self)
    static let bitrateColumn = ColumnID("bitrate", Double.self)
    static let hlsColumn = ColumnID("hls", DateString.self)
    static let lastcheckokColumn = ColumnID("lastcheckok", DateString.self)
    static let lastchecktimeColumn = ColumnID("lastchecktime", DateString.self)
    static let lastchecktime_iso8601Column = ColumnID("lastchecktime_iso8601", DateString.self)
    static let lastcheckoktimeColumn = ColumnID("lastcheckoktime", DateString.self)
    static let lastcheckoktime_iso8601Column = ColumnID("lastcheckoktime_iso8601", DateString.self)
    static let lastlocalchecktimeColumn = ColumnID("lastlocalchecktime", DateString.self)
    static let lastlocalchecktime_iso8601Column = ColumnID("lastlocalchecktime_iso8601", DateString.self)
    static let clicktimestampColumn = ColumnID("clicktimestamp", DateString.self)
    static let clicktimestamp_iso8601Column = ColumnID("clicktimestamp_iso8601", DateString.self)
    static let clickcountColumn = ColumnID("clickcount", Int.self)
    static let clicktrendColumn = ColumnID("clicktrend", Int.self)
    static let ssl_errorColumn = ColumnID("ssl_error", String.self)
    static let geo_latColumn = ColumnID("geo_lat", Double.self)
    static let geo_longColumn = ColumnID("geo_long", Double.self)
    static let has_extended_infoColumn = ColumnID("has_extended_info", Bool.self)

    static let allColumns: [String: CSVType] = [
        Self.changeuuidColumn.name : CSVType.string,
        Self.stationuuidColumn.name : CSVType.string,
        Self.nameColumn.name : CSVType.string,
        Self.urlColumn.name : CSVType.string,
        Self.url_resolvedColumn.name : CSVType.string,
        Self.homepageColumn.name : CSVType.string,
        Self.faviconColumn.name : CSVType.string,
        Self.tagsColumn.name : CSVType.string,
        Self.countryColumn.name : CSVType.string,
        Self.countrycodeColumn.name : CSVType.string,
        Self.iso_3166_2Column.name : CSVType.string,
        Self.stateColumn.name : CSVType.string,
        Self.languageColumn.name : CSVType.string,
        Self.languagecodesColumn.name : CSVType.string,
        Self.votesColumn.name : CSVType.integer,
        Self.lastchangetimeColumn.name : CSVType.string,
        Self.lastchangetime_iso8601Column.name : CSVType.string,
        Self.codecColumn.name : CSVType.string,
        Self.bitrateColumn.name : CSVType.double,
        Self.hlsColumn.name : CSVType.string,
        Self.lastcheckokColumn.name : CSVType.string,
        Self.lastchecktimeColumn.name : CSVType.string,
        Self.lastchecktime_iso8601Column.name : CSVType.string,
        Self.lastcheckoktimeColumn.name : CSVType.string,
        Self.lastcheckoktime_iso8601Column.name : CSVType.string,
        Self.lastlocalchecktimeColumn.name : CSVType.string,
        Self.lastlocalchecktime_iso8601Column.name : CSVType.string,
        Self.clicktimestampColumn.name : CSVType.string,
        Self.clicktimestamp_iso8601Column.name : CSVType.string,
        Self.clickcountColumn.name : CSVType.integer,
        Self.clicktrendColumn.name : CSVType.integer,
        Self.ssl_errorColumn.name : CSVType.string,
        Self.geo_latColumn.name : CSVType.double,
        Self.geo_longColumn.name : CSVType.double,
        Self.has_extended_infoColumn.name : CSVType.boolean,
    ]
}

@available(macOS 12.0, iOS 15.0, *)
extension Station : Identifiable {
    /// The identifier of the station
    var id: UUID? {
        stationuuid.flatMap(UUID.init(uuidString:))
    }

    init(row: DataFrame.Row) {
        self.changeuuid = row[Self.changeuuidColumn]
        self.stationuuid = row[Self.stationuuidColumn]
        self.name = row[Self.nameColumn]
        self.url = row[Self.urlColumn]
        self.url_resolved = row[Self.url_resolvedColumn]
        self.homepage = row[Self.homepageColumn]
        self.favicon = row[Self.faviconColumn]
        self.tags = row[Self.tagsColumn]
        self.country = row[Self.countryColumn]
        self.countrycode = row[Self.countrycodeColumn]
        self.iso_3166_2 = row[Self.iso_3166_2Column]
        self.state = row[Self.stateColumn]
        self.language = row[Self.languageColumn]
        self.languagecodes = row[Self.languagecodesColumn]
        self.votes = row[Self.votesColumn]
        self.lastchangetime = row[Self.lastchangetimeColumn]
        self.lastchangetime_iso8601 = row[Self.lastchangetime_iso8601Column]
        self.codec = row[Self.codecColumn]
        self.bitrate = row[Self.bitrateColumn]
        self.hls = row[Self.hlsColumn]
        self.lastcheckok = row[Self.lastcheckokColumn]
        self.lastchecktime = row[Self.lastchecktimeColumn]
        self.lastchecktime_iso8601 = row[Self.lastchecktime_iso8601Column]
        self.lastcheckoktime = row[Self.lastcheckoktimeColumn]
        self.lastcheckoktime_iso8601 = row[Self.lastcheckoktime_iso8601Column]
        self.lastlocalchecktime = row[Self.lastlocalchecktimeColumn]
        self.lastlocalchecktime_iso8601 = row[Self.lastlocalchecktime_iso8601Column]
        self.clicktimestamp = row[Self.clicktimestampColumn]
        self.clicktimestamp_iso8601 = row[Self.clicktimestamp_iso8601Column]
        self.clickcount = row[Self.clickcountColumn]
        self.clicktrend = row[Self.clicktrendColumn]
        self.ssl_error = row[Self.ssl_errorColumn]
        self.geo_lat = row[Self.geo_latColumn]
        self.geo_long = row[Self.geo_longColumn]
        self.has_extended_info = row[Self.has_extended_infoColumn]
    }

    var streamingURL: URL? {
        self.url.flatMap(URL.init(string:))
    }

    func iconView(size: CGFloat) -> some View {
        let url = URL(string: self.favicon ?? "about:blank") ?? URL(string: "about:blank")!
        return AsyncImage(url: url, content: { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
        }, placeholder: {
            ZStack {
                Rectangle()
                    .fill(Material.thin)

                // use a blurred color flag backdrop
                let countryCode = self.countrycode?.isEmpty != false ? "UN" : (self.countrycode ?? "")
                Text(emojiFlag(countryCode: countryCode))
                    .font(Font.system(size: size * 1.5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blur(radius: 5)
                }
        })
            .clipped()
            .frame(width: size, height: size)
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct StationCatalog {
    // StationID,Name,Url,Homepage,Favicon,Creation,Country,Language,Tags,Votes,Subcountry,clickcount,ClickTrend,ClickTimestamp,Codec,LastCheckOK,LastCheckTime,Bitrate,UrlCache,LastCheckOkTime,Hls,ChangeUuid,StationUuid,CountryCode,LastLocalCheckTime,CountrySubdivisionCode,GeoLat,GeoLong,SslError,LanguageCodes,ExtendedInfo
    var frame: DataFrame

    /// The number of stations in the catalog
    var count: Int { frame.rows.count }

    //    subscript(element index: Int) -> Station? {
    //        get {
    //            let row = frame.rows[index]
    //            let StationID = row["StationID"]
    //            return wip(nil)
    //        }
    //    }


    /// The stations frame, if the
    static var stationsFrame: DataFrame? {
        stations.successValue?.frame
    }

    static var stations: Result<StationCatalog, Error> = {
        Result {
            guard let url = Bundle.module.url(forResource: "stations", withExtension: "csv") else {
                throw CocoaError(.fileReadNoSuchFile)
            }

            // the old ways are better
            let options = CSVReadingOptions(hasHeaderRow: true, nilEncodings: ["NULL"], trueEncodings: [], falseEncodings: [], floatingPointType: TabularData.CSVType.double, ignoresEmptyLines: true, usesQuoting: true, usesEscaping: true, delimiter: ",", escapeCharacter: "\\")

            // Parsing the dates as dates slows parsing 28,576 by 30x (from 0.434 seconds to 13.296); since we don't need the dates up front (e.g., for sorting), simply parse them as strings and parse them later
            //let dateFieldParse = CSVType.string
            //let dateFieldParse = CSVType.date


            dbg("loading from URL:", url)
            do {
                let df = try DataFrame(contentsOfCSVFile: url, columns: nil, rows: nil, types: Station.allColumns, options: options)
                return StationCatalog(frame: df)
            } catch {
                dbg("error loading from URL:", url, "error:", error)
                throw error
            }
        }
    }()

    static var countryCounts: Result<[ValueCount<String>], Error> {
        Result { try stations.get().frame.valueCounts(column: "CountryCode") }
    }

    static var languageCounts: Result<[ValueCount<String>], Error> {
        Result { try stations.get().frame.valueCounts(column: "Language") }
    }

    static var tagsCounts: Result<[ValueCount<String>], Error> {
        Result { try stations.get().frame.valueCounts(column: "Tags") }
    }
}

@available(macOS 12.0, iOS 15.0, *)
extension DataFrame {
    func valueCounts<T>(column: String) -> [ValueCount<T>] {
        self
            .grouped(by: column)
            .counts(order: .descending)
            .rows
            .compactMap { row in
                (row[column] as? T).flatMap { value in
                    (row["count"] as? Int).flatMap { count in
                        ValueCount(value: value, count: count)
                    }
                }
            }
    }
}

/// A value with a count
struct ValueCount<T> {
    let value: T
    let count: Int
}


struct Catalog : Pure {
    var sources: [Source]
}

struct Source : Pure {
    var name: String
    var url: URL
    var logo: URL?
    var category: String?
}

extension Catalog {
    /// The default catalog bundled with the app
    static let defaultCatalog = Result {
        // the default catalog is localizable so different languages can have different default sources
        try Bundle.module.url(forResource: "catalog", withExtension: "json").flatMap {
            try Catalog(json: Data(contentsOf: $0))
        }
    }
}

extension Source : Identifiable {
    /// The identifier for a source is the URL itself, which should be unique
    var id: URL { url }
}

@available(macOS 12.0, iOS 15.0, *)
public struct TuneOutView: View {
    @EnvironmentObject var store: Store

    public var body: some View {
        NavigationView {
            Sidebar()
            if let frame = StationCatalog.stationsFrame {
//                StationList(frame: frame, onlyFiltered: true)
//                    .navigationTitle(Text("All Stations"))
                EmptyView()
            } else {
                EmptyView()
            }
            Text("Select Station").font(.largeTitle).foregroundColor(.secondary)
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
extension DataFrame.Row {
    var stationID: Station.UUIDString? {
        self[Station.stationuuidColumn]
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct StationList<Frame: DataFrameProtocol> : View {
    @State var selection: Station? = nil
    @State var queryString: String = ""
    @AppStorage("pinned") var pinnedStations: Set<String> = []
    let frame: Frame
    /// Whether to only display the table if there is a filter active
    var onlyFiltered: Bool = false

    var selectedStations: [DataFrame.Row] {
        frame.rows
            .filter({ queryString.isEmpty || ($0[Station.nameColumn]?.localizedCaseInsensitiveContains(queryString) == true) })
    }

    var body: some View {
        Group {
            if onlyFiltered == false || !queryString.isEmpty {
                List {
                    ForEach(selectedStations, id: \.stationID) {
                        stationElement(stationRow: $0)
                    }
                }
            } else {
                Text("Station List").font(.largeTitle).foregroundColor(.secondary)
            }
        }
        .searchable(text: $queryString, placement: .automatic, prompt: Text("Search"))
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
        return NavigationLink(tag: station, selection: $selection, destination: {
            StationView(source: station)
        }) {
            Label(title: { stationLabelTitle(station) }) {
                station.iconView(size: 50)
            }
            .labelStyle(StationLabelStyle())
            //.badge(station.Bitrate ?? wip(0))
            //.badge(station.Votes?.localizedNumber())

        }
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
                    ForEach(enumerated: tags) { offset, titleImage in
                        titleImage.image
                            .symbolRenderingMode(.hierarchical)
//                            .foregroundStyle(Color(hue: titleImage.key.seededRandom, saturation: 0.7, brightness: 0.99))
                            .foregroundStyle(Color(hue: titleImage.key.seededRandom, saturation: 0.7, brightness: 0.99), Color(hue: String(titleImage.key.reversed()).seededRandom, saturation: 0.7, brightness: 0.99))
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
            countriesSection
            //languagesSection
            //tagsSection
        }
        .listStyle(SidebarListStyle())
    }

    var languagesSection: some View {
        Section {
            if let frame = StationCatalog.stationsFrame,
               let languageCounts = StationCatalog.languageCounts.successValue {
                ForEach(languageCounts, id: \.value) { lang in
                    let title = Text(lang.value)

                    NavigationLink(destination: StationList(frame: frame.filter({ $0[Station.languageColumn] == lang.value })).navigationTitle(Text("Language: ") + title)) {
                        title
                    }
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
                    let title = Text(tag.value)

                    NavigationLink(destination: StationList(frame: frame.filter({ $0[Station.tagsColumn] == tag.value })).navigationTitle(Text("Tag: ") + title)) {
                        Label(title: {
                            //                        if let langName = (Locale.current as NSLocale).displayName(forKey: .languageCode, value: lang.value) {
                            //                            Text(langName)
                            //                        } else {
                            Text(tag.value)
                            //                        }
                        }, icon: {
                            //Text(emojiFlag(countryCode: lang.value))

                        })
                            .badge(tag.count)
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
                //                count
                //                ? (svc1.valueCount?.count ?? Int.min) < (svc2.valueCount?.count ?? Int.max)
                //                :
                (svc1.localName ?? String(UnicodeScalar(.min))) < (svc2.localName ?? String(UnicodeScalar(.max)))
            }
    }

    func countryName(for code: String) -> String? {
        (Locale.current as NSLocale).displayName(forKey: .countryCode, value: code)
    }

    func stationsSectionPopular(frame: DataFrame, count: Int = 500, title: Text = Text("Popular")) -> some View {
        NavigationLink(destination: StationList(frame: frame.sorted(on: Station.clickcountColumn, order: .descending).prefix(count)).navigationTitle(title)) {
            title.label(symbol: "star")
        }
    }

    func stationsSectionPinned(frame: DataFrame, title: Text = Text("Pinned")) -> some View {
        NavigationLink(destination: StationList(frame: frame.filter({ row in
            pinnedStations.contains(row[Station.stationuuidColumn] ?? "")
        })).navigationTitle(title)) {
            title.label(symbol: "pin")
        }
        .badge(pinnedStations.count)
    }

    var stationsSection: some View {
        Section {
            if let frame = StationCatalog.stationsFrame {
                Group {
                    stationsSectionPopular(frame: frame)
                        .keyboardShortcut("1")
                    if !pinnedStations.isEmpty {
                        stationsSectionPinned(frame: frame)
                            .keyboardShortcut("2")
                    }
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

                    NavigationLink(destination: StationList(frame: frame.filter({ $0[Station.countrycodeColumn] == country.valueCount.value })).navigationTitle(navTitle)) {
                        title.label(image: Text(emojiFlag(countryCode: country.valueCount.value.isEmpty ? "UN" : country.valueCount.value)))
                            .badge(country.valueCount.count)
                    }
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
    let source: Station
    @StateObject var tuner: RadioTuner

    init(source: Station) {
        self.source = source
        self._tuner = StateObject(wrappedValue: RadioTuner(streamingURL: wip(source.streamingURL!))) // TODO: check for bad url
    }

    var body: some View {
        VideoPlayer(player: tuner.player) {
            VStack {
                Spacer()
                Text(source.name ?? "")
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity)

                Text("Now Playing: \(tuner.itemTitle)")
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity)

                Spacer()
                Spacer()

            }
            //.background(source.imageView().blur(radius: 20, opaque: true))
            .background(Material.thick)
        }
        .textSelection(.enabled)
        .onAppear {
            tuner.player.play()
        }
    }
}

// TODO: figure out: App[20783:6049981] [] [19:59:59.139] FigICYBytePumpCopyProperty signalled err=-12784 (kFigBaseObjectError_PropertyNotFound) (no such property) at FigICYBytePump.c:1396


@available(macOS 12.0, iOS 15.0, *)
final class RadioTuner: NSObject, ObservableObject, AVPlayerItemMetadataOutputPushDelegate {
    @Published var itemTitle: String = "Unknown"

    let streamingURL: URL

    let player: AVPlayer
    let playerItem: AVPlayerItem

    init(streamingURL: URL) {
        self.streamingURL = streamingURL
        self.playerItem = AVPlayerItem(url: self.streamingURL)
        self.player = AVPlayer(playerItem: self.playerItem)

        super.init()

        let metaOutput = AVPlayerItemMetadataOutput(identifiers: allAVMetadataIdentifiers.map(\.rawValue))
        metaOutput.setDelegate(self, queue: DispatchQueue.main)
        self.playerItem.add(metaOutput)
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

@available(macOS 12.0, iOS 15.0, *)
extension Station {
    /// The parsed `Tags` field
    var tagElements: [String] {
        (self.tags ?? "").split(separator: ",")
            .map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }
    }

    /// Returns the text and image for known tags
    static func tagInfo(tagString: String) -> (key: String, title: Text, image: Image)? {
        // check the top 100 tag list with:
        // cat Sources/App/Resources/stations.csv | tr '"' '\n' | grep ',' | tr ',' '\n' | tr '[A-Z]' '[a-z]' | grep '[a-z]' | sort | uniq -c | sort -nr | head -n 100

        switch tagString {
        case "pop": return (tagString, Text("pop"), Image(systemName: "sparkles"))
        case "news": return (tagString, Text("news"), Image(systemName: "newspaper"))
        case "rock": return (tagString, Text("rock"), Image(systemName: "guitars"))
        case "music": return (tagString, Text("music"), Image(systemName: "music.note"))
        case "talk": return (tagString, Text("talk"), Image(systemName: "mic.square"))
        case "public radio": return (tagString, Text("public radio"), Image(systemName: "building.columns"))
        //case "english": return (tagString, Text("english"), Image(systemName: "e.circle"))
        //case "dance": return (tagString, Text("dance"), Image(systemName: "d.circle"))
        //case "spanish": return (tagString, Text("spanish"), Image(systemName: "s.circle"))
        //case "top 40": return (tagString, Text("top 40"), Image(systemName: "t.circle"))
        case "80s": return (tagString, Text("80s"), Image(systemName: "8.circle"))
        //case "español": return (tagString, Text("español"), Image(systemName: "e.circle"))
        //case "greek": return (tagString, Text("greek"), Image(systemName: "g.circle"))
        case "radio": return (tagString, Text("radio"), Image(systemName: "radio"))
        case "oldies": return (tagString, Text("oldies"), Image(systemName: "tortoise"))
        //case "estación": return (tagString, Text("estación"), Image(systemName: "e.circle"))
        //case "community radio": return (tagString, Text("community radio"), Image(systemName: "c.circle"))
        //case "mex": return (tagString, Text("mex"), Image(systemName: "m.circle"))
        //case "fm": return (tagString, Text("fm"), Image(systemName: "f.circle"))
        case "méxico": return (tagString, Text("méxico"), Image(systemName: "globe.americas"))
        case "christian": return (tagString, Text("christian"), Image(systemName: "cross"))
        //case "mx": return (tagString, Text("mx"), Image(systemName: "m.circle"))
        //case "jazz": return (tagString, Text("jazz"), Image(systemName: "j.circle"))
        case "hits": return (tagString, Text("hits"), Image(systemName: "sparkle"))
        //case "classical": return (tagString, Text("classical"), Image(systemName: "c.circle"))
        case "90s": return (tagString, Text("90s"), Image(systemName: "9.circle"))
        //case "electronic": return (tagString, Text("electronic"), Image(systemName: "e.circle"))
        //case "folk": return (tagString, Text("folk"), Image(systemName: "f.circle"))
        //case "classic rock": return (tagString, Text("classic rock"), Image(systemName: "c.circle"))
        //case "adult contemporary": return (tagString, Text("adult contemporary"), Image(systemName: "a.circle"))
        case "mexico": return (tagString, Text("mexico"), Image(systemName: "globe.americas"))
        //case "local news": return (tagString, Text("local news"), Image(systemName: "l.circle"))
        //case "house": return (tagString, Text("house"), Image(systemName: "h.circle"))
        //case "alternative": return (tagString, Text("alternative"), Image(systemName: "a.circle"))
        case "german": return (tagString, Text("german"), Image(systemName: "globe.europe.africa"))
        case "70s": return (tagString, Text("70s"), Image(systemName: "7.circle"))
        //case "música": return (tagString, Text("música"), Image(systemName: "m.circle"))
        //case "classic hits": return (tagString, Text("classic hits"), Image(systemName: "c.circle"))
        //case "commercial": return (tagString, Text("commercial"), Image(systemName: "c.circle"))
        //case "npr": return (tagString, Text("npr"), Image(systemName: "n.circle"))
        //case "hiphop": return (tagString, Text("hiphop"), Image(systemName: "h.circle"))
        //case "country": return (tagString, Text("country"), Image(systemName: "c.circle"))
        //case "pop music": return (tagString, Text("pop music"), Image(systemName: "p.circle"))
        //case "soul": return (tagString, Text("soul"), Image(systemName: "s.circle"))
        //case "musica": return (tagString, Text("musica"), Image(systemName: "m.circle"))
        //case "s": return (tagString, Text("s"), Image(systemName: "s.circle"))
        //case "indie": return (tagString, Text("indie"), Image(systemName: "i.circle"))
        //case "deutsch": return (tagString, Text("deutsch"), Image(systemName: "d.circle"))
        //case "information": return (tagString, Text("information"), Image(systemName: "i.circle"))
        case "university radio": return (tagString, Text("university radio"), Image(systemName: "graduationcap"))
        case "chillout": return (tagString, Text("chillout"), Image(systemName: "snowflake"))
        case "ambient": return (tagString, Text("ambient"), Image(systemName: "headphones"))
        //case "xp_5": return (tagString, Text("xp_5"), Image(systemName: "u.circle"))
        //case "g_7": return (tagString, Text("g_7"), Image(systemName: "g.circle"))
        //case "techno": return (tagString, Text("techno"), Image(systemName: "t.circle"))
        //case "sport": return (tagString, Text("sport"), Image(systemName: "s.circle"))
        case "world music": return (tagString, Text("world music"), Image(systemName: "globe"))
        //case "noticias": return (tagString, Text("noticias"), Image(systemName: "n.circle"))
        //case "french": return (tagString, Text("french"), Image(systemName: "f.circle"))
        //case "música pop": return (tagString, Text("música pop"), Image(systemName: "m.circle"))
        //case "pop rock": return (tagString, Text("pop rock"), Image(systemName: "p.circle"))
        case "local music": return (tagString, Text("local music"), Image(systemName: "flag"))
        case "metal": return (tagString, Text("metal"), Image(systemName: "hammer"))
        //case "lounge": return (tagString, Text("lounge"), Image(systemName: "l.circle"))
        case "disco": return (tagString, Text("disco"), Image(systemName: "dot.arrowtriangles.up.right.down.left.circle"))
        //case "mainstream": return (tagString, Text("mainstream"), Image(systemName: "m.circle"))
        //case "alternative rock": return (tagString, Text("alternative rock"), Image(systemName: "a.circle"))
        //case "religion": return (tagString, Text("religion"), Image(systemName: "r.circle"))
        case "regional mexican": return (tagString, Text("regional mexican"), Image(systemName: "globe.americas"))
        case "60s": return (tagString, Text("60s"), Image(systemName: "6.circle"))
        //case "on": return (tagString, Text("on"), Image(systemName: "o.circle"))
        case "electro": return (tagString, Text("electro"), Image(systemName: "cable.connector.horizontal"))
        case "talk & speech": return (tagString, Text("talk & speech"), Image(systemName: "mic"))
        //case "funk": return (tagString, Text("funk"), Image(systemName: "f.circle"))
        case "college radio": return (tagString, Text("college radio"), Image(systemName: "graduationcap"))
        case "catholic": return (tagString, Text("catholic"), Image(systemName: "cross"))
        //case "regional radio": return (tagString, Text("regional radio"), Image(systemName: "r.circle"))
        //case "aac": return (tagString, Text("aac"), Image(systemName: "a.circle"))
        //case "musica regional mexicana": return (tagString, Text("musica regional mexicana"), Image(systemName: "m.circle"))
        //case "rnb": return (tagString, Text("rnb"), Image(systemName: "r.circle"))
        //case "hard rock": return (tagString, Text("hard rock"), Image(systemName: "h.circle"))
        //case "juvenil": return (tagString, Text("juvenil"), Image(systemName: "j.circle"))
        //case "charts": return (tagString, Text("charts"), Image(systemName: "c.circle"))
        //case "regional": return (tagString, Text("regional"), Image(systemName: "r.circle"))
        //case "grupera": return (tagString, Text("grupera"), Image(systemName: "g.circle"))
        //case "blues": return (tagString, Text("blues"), Image(systemName: "b.circle"))
        //case "reggae": return (tagString, Text("reggae"), Image(systemName: "r.circle"))
        //case "russian": return (tagString, Text("russian"), Image(systemName: "r.circle"))
        //case "news talk": return (tagString, Text("news talk"), Image(systemName: "n.circle"))
        //case "trance": return (tagString, Text("trance"), Image(systemName: "t.circle"))
        //case "rap": return (tagString, Text("rap"), Image(systemName: "r.circle"))
        //case "musica regional": return (tagString, Text("musica regional"), Image(systemName: "m.circle"))
        //case "latin music": return (tagString, Text("latin music"), Image(systemName: "l.circle"))
        //case "edm": return (tagString, Text("edm"), Image(systemName: "e.circle"))
        //case "easy listening": return (tagString, Text("easy listening"), Image(systemName: "e.circle"))
        //case "culture": return (tagString, Text("culture"), Image(systemName: "c.circle"))
        //case "entertainment": return (tagString, Text("entertainment"), Image(systemName: "e.circle"))
        //case "variety": return (tagString, Text("variety"), Image(systemName: "v.circle"))
        //case "entretenimiento": return (tagString, Text("entretenimiento"), Image(systemName: "a.circle"))
        default: return nil
        }
    }

}

