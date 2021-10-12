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

/// To fetch the latest catalog, run:
/// curl https://nl1.api.radio-browser.info/csv/stations/search > Sources/App/Resources/stations.csv
@available(macOS 12.0, iOS 15.0, *)
struct Station : Pure {
    // parsing as takes takes it from 500ms -> 12724ms
    // typealias DateString = Date
    // static let dateStringType = CSVType.date
    typealias DateString = String
    static let dateStringType = CSVType.string

    @available(*, deprecated, message: "prefer ISO8601 fields")
    typealias OldDateString = String
    @available(*, deprecated, message: "prefer ISO8601 fields")
    static let oldDateStringType = CSVType.string

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
    var lastcheckok: Int?
    //var lastchecktime: OldDateString?
    var lastchecktime_iso8601: DateString?
    //var lastcheckoktime: OldDateString?
    var lastcheckoktime_iso8601: DateString?
    //var lastlocalchecktime: OldDateString?
    var lastlocalchecktime_iso8601: DateString?
    //var clicktimestamp: OldDateString?
    var clicktimestamp_iso8601: DateString?
    var clickcount: Int?
    var clicktrend: Int?
    var ssl_error: String?
    var geo_lat: Double?
    var geo_long: Double?
    var has_extended_info: Bool?
}

@available(macOS 12.0, iOS 15.0, *)
extension Station : Identifiable {
    /// The identifier of the station
    var id: UUID? {
        stationuuid.flatMap(UUID.init(uuidString:))
    }

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
    static let lastcheckokColumn = ColumnID("lastcheckok", Int.self)
    //static let lastchecktimeColumn = ColumnID("lastchecktime", OldDateString.self)
    static let lastchecktime_iso8601Column = ColumnID("lastchecktime_iso8601", DateString.self)
    //static let lastcheckoktimeColumn = ColumnID("lastcheckoktime", OldDateString.self)
    static let lastcheckoktime_iso8601Column = ColumnID("lastcheckoktime_iso8601", DateString.self)
    //static let lastlocalchecktimeColumn = ColumnID("lastlocalchecktime", OldDateString.self)
    static let lastlocalchecktime_iso8601Column = ColumnID("lastlocalchecktime_iso8601", DateString.self)
    //static let clicktimestampColumn = ColumnID("clicktimestamp", OldDateString.self)
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
        //Self.lastchangetimeColumn.name : Self.oldDateStringType,
        Self.lastchangetime_iso8601Column.name : Self.dateStringType,
        Self.codecColumn.name : CSVType.string,
        Self.bitrateColumn.name : CSVType.double,
        Self.hlsColumn.name : CSVType.string,
        Self.lastcheckokColumn.name : CSVType.integer,
        //Self.lastchecktimeColumn.name : Self.oldDateStringType,
        Self.lastchecktime_iso8601Column.name : Self.dateStringType,
        //Self.lastcheckoktimeColumn.name : Self.oldDateStringType,
        Self.lastcheckoktime_iso8601Column.name : Self.dateStringType,
        //Self.lastlocalchecktimeColumn.name : Self.oldDateStringType,
        Self.lastlocalchecktime_iso8601Column.name : Self.dateStringType,
        //Self.clicktimestampColumn.name : Self.oldDateStringType,
        Self.clicktimestamp_iso8601Column.name : Self.dateStringType,
        Self.clickcountColumn.name : CSVType.integer,
        Self.clicktrendColumn.name : CSVType.integer,
        Self.ssl_errorColumn.name : CSVType.string,
        Self.geo_latColumn.name : CSVType.double,
        Self.geo_longColumn.name : CSVType.double,
        Self.has_extended_infoColumn.name : CSVType.boolean,
    ]

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
        //self.lastchecktime = row[Self.lastchecktimeColumn]
        self.lastchecktime_iso8601 = row[Self.lastchecktime_iso8601Column]
        //self.lastcheckoktime = row[Self.lastcheckoktimeColumn]
        self.lastcheckoktime_iso8601 = row[Self.lastcheckoktime_iso8601Column]
        //self.lastlocalchecktime = row[Self.lastlocalchecktimeColumn]
        self.lastlocalchecktime_iso8601 = row[Self.lastlocalchecktime_iso8601Column]
        //self.clicktimestamp = row[Self.clicktimestampColumn]
        self.clicktimestamp_iso8601 = row[Self.clicktimestamp_iso8601Column]
        self.clickcount = row[Self.clickcountColumn]
        self.clicktrend = row[Self.clicktrendColumn]
        self.ssl_error = row[Self.ssl_errorColumn]
        self.geo_lat = row[Self.geo_latColumn]
        self.geo_long = row[Self.geo_longColumn]
        self.has_extended_info = row[Self.has_extended_infoColumn]
    }
}

@available(macOS 12.0, iOS 15.0, *)
extension Station {
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
        prf { // 479ms
            Result {
                guard let url = Bundle.module.url(forResource: "stations", withExtension: "csv") else {
                    throw CocoaError(.fileReadNoSuchFile)
                }

                // the old ways are better
                var options = CSVReadingOptions(hasHeaderRow: true, nilEncodings: ["NULL", ""], trueEncodings: ["true"], falseEncodings: ["false"], floatingPointType: TabularData.CSVType.double, ignoresEmptyLines: true, usesQuoting: true, usesEscaping: false, delimiter: ",", escapeCharacter: "\\")

                options.addDateParseStrategy(Date.ISO8601FormatStyle())

                dbg("loading from URL:", url)
                do {
                    let df = try DataFrame(contentsOfCSVFile: url, columns: nil, rows: nil, types: Station.allColumns, options: options)
                    return StationCatalog(frame: df)
                } catch {
                    dbg("error loading from URL:", url, "error:", error)
                    throw error
                }
            }
        }
    }()

    static var countryCounts: Result<[ValueCount<String>], Error> {
        Result { try stations.get().frame.valueCounts(column: Station.countrycodeColumn) }
    }

    static var languageCounts: Result<[ValueCount<String>], Error> {
        Result { try stations.get().frame.valueCounts(column: Station.languageColumn) }
    }

    static var tagsCounts: Result<[ValueCount<String>], Error> {
        Result { try stations.get().frame.valueCounts(column: Station.tagsColumn) }
    }
}

@available(macOS 12.0, iOS 15.0, *)
extension DataFrame {
    func valueCounts<T: Hashable>(column: ColumnID<T>) -> [ValueCount<T>] {
        self
            .grouped(by: column)
            .counts(order: .descending)
            .rows
            .compactMap { row in
                row[column].flatMap { value in
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
                StationList(title: Text("Stations"), frame: { frame }, hideEmpty: true)
            } else {
                EmptyView()
            }
            #if os(macOS)
            // needs a third placeholder view to get the three-column NavigationView behavior
            Text("Select Station")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            #endif
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct StationCommands: Commands {
    private struct MenuContent: View {
        //@FocusedBinding(\.selectedStation) var selectedStation

        var body: some View {
            wip(EmptyView())
        }
    }

    var body: some Commands {
        SidebarCommands()
    }
}


//@available(macOS 12.0, iOS 15.0, *)
//extension FocusedValues {
//    var selectedStation: Binding<Station>? {
//        get { self[SelectedStationKey.self] }
//        set { self[SelectedStationKey.self] = newValue }
//    }
//
//    private struct SelectedStationKey: FocusedValueKey {
//        typealias Value = Binding<Station>
//    }
//}

//@available(macOS 12.0, iOS 15.0, *)
//private struct TrackTitleKey: PreferenceKey {
//    static var defaultValue: String? { nil }
//    static func reduce(value: inout String?, nextValue: () -> String?) {
//        nextValue() ?? value
//    }
//}

//extension FocusedValues {
//    var trackTitle: String? {
//        get { self[TrackTitleKey.self] }
//        set { self[TrackTitleKey.self] = newValue }
//    }
//
//    private struct TrackTitleKey: FocusedValueKey {
//        typealias Value = String
//    }
//}


/// A `DataFrameProtocol` that can filter itself efficiently.
@available(macOS 12.0, iOS 15.0, *)
public protocol FilterableFrame : DataFrameProtocol {
    /// Filter on a specific column value. Since this is already implemented in both
    /// `DataFrame` and `DataFrame.Slice`, its absence from `DataFrameProtocol` is assumed to be an
    /// oversight.
    func filter<T>(on: ColumnID<T>, _ isIncluded: (T?) throws -> Bool) throws -> DataFrame.Slice
}

@available(macOS 12.0, iOS 15.0, *)
extension DataFrame : FilterableFrame { }

@available(macOS 12.0, iOS 15.0, *)
extension DataFrame.Slice : FilterableFrame { }


/// Making `DataFrame.Rows` implement `RandomAccessCollection` would allow
/// us to use it directly in a `ForEach`, but the performance with
/// large row sets is abyssmal
//@available(macOS 12.0, iOS 15.0, *)
//extension DataFrame.Rows : RandomAccessCollection { }

@available(macOS 12.0, iOS 15.0, *)
extension DataFrame.Row {
    var stationID: Station.UUIDString? {
        self[Station.stationuuidColumn]
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct StationList<Frame: FilterableFrame> : View {
    /// The navigation title for this view
    let navTitle: Text

    /// The title of the currently-playing track
    @State var nowPlayingTitle: String? = ""

    //@FocusedBinding(\.selection) var selectionFocus: Station?? // not working
    @State var selectedStation: Station? = nil

    @State var queryString: String = ""

    /// The shuffled identifiers for sorting
    @State var shuffledIDs: [String : Int]? = nil

    //@FocusedValue(\.trackTitle) var trackTitle

    @AppStorage("pinned") var pinnedStations: Set<String> = []
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

//    var sortComparators: [SortComparator] {
//        wip([])
//    }

    var selectedStations: DataFrame.Slice {
        // queryString.isEmpty ? frame()
        try! frame()
            .filter(on: Station.nameColumn, matchesQueryString)
    }

    var sortedStations: DataFrame {
        let stations = self.selectedStations

        if sortByName {
            return stations.sorted(on: Station.nameColumn) { a, b in
                a.localizedCompare(b) == .orderedAscending
            }
        } else {
            return stations.sorted(on: Station.clicktrendColumn, Station.bitrateColumn, order: .descending)
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
        arrangedRows.filter({ _ in true })
    }

    func matchesQueryString(name: String?) -> Bool {
        queryString.isEmpty || name?.localizedCaseInsensitiveContains(queryString) == true
    }

    var body: some View {
        Group {
            if hideEmpty == false || !queryString.isEmpty {
                List {
                    ForEach(arrangedStations, id: \.stationID, content: stationElement(stationRow:))
                }
            } else {
                Text("Station List").font(.largeTitle).foregroundColor(.secondary)
            }
        }
        .searchable(text: $queryString, placement: .automatic, prompt: Text("Search"))
        .toolbar(id: "navtoolbar") {
            ToolbarItem(id: "previous", placement: ToolbarItemPlacement.navigation, showsByDefault: true) {
                Button {
                    dbg("previous")
                    selectStation(next: false, query: false)
                } label: {
                    Text("Previous").label(symbol: "backward").symbolVariant(.fill)
                }
                .disabled(!selectStation(next: false, query: true))
                .keyboardShortcut("[")
                .help(Text("Select the previous station"))
            }

            ToolbarItem(id: "shuffle", placement: ToolbarItemPlacement.navigation, showsByDefault: true) {
                Button {
                    dbg("shuffling")
                    withAnimation {
                        self.shuffledIDs = Dictionary(grouping: frame().rows.compactMap(\.stationID).shuffled().enumerated(), by: \.element).compactMapValues(\.first).mapValues(\.offset)
                        if let randomStation = arrangedStations.first {
                            // shuffling selected the first row in the list
                            self.selectedStation = Station(row: randomStation)
                        }
                    }
                } label: {
                    Text("Shuffle").label(symbol: "shuffle", color: .teal)
                }
                .keyboardShortcut("\\")
                .help(Text("Shuffle the current selection"))
                .symbolRenderingMode(self.shuffledIDs == nil ? .monochrome : .multicolor)
            }

            ToolbarItem(id: "next", placement: ToolbarItemPlacement.navigation, showsByDefault: true) {
                Button {
                    dbg("next")
                    selectStation(next: true, query: false)
                } label: {
                    Text("Next").label(symbol: "forward").symbolVariant(.fill)
                }
                .disabled(!selectStation(next: true, query: true))
                .keyboardShortcut("]")
                .help(Text("Select the next station"))
            }
        }
        .navigation(title: nowPlayingTitleText, subtitle: subtitle)
    }

    @discardableResult func selectStation(next: Bool, query: Bool) -> Bool {
        if arrangedFrame.shape.rows <= 1 {
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
        if let nowPlayingTitle = nowPlayingTitle,
           !nowPlayingTitle.isEmpty {
            title = title + Text(": ") + Text(nowPlayingTitle)
        }
        return title
    }

    var subtitle: Text? {
        wip(nil)
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
                //.focusedValue(\.selectedStation, Binding.constant(station)) // causes a hang!
        }) {
            Label(title: { stationLabelTitle(station) }) {
                station.iconView(size: 50)
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
                    let title = Text(tag.value)
                    let tagsFrame = {
                        frame.filter(on: Station.tagsColumn, { $0 == tag.value })
                    }
                    NavigationLink(destination: StationList(title: Text("Tag: ") + title, frame: tagsFrame)) {
                        Label(title: {
                            // if let langName = (Locale.current as NSLocale).displayName(forKey: .languageCode, value: lang.value) {
                            // Text(langName)
                            // } else {
                            Text(tag.value)
                            // }
                        }, icon: {
                            // Text(emojiFlag(countryCode: lang.value))
                        })
                        .badge(tag.count)
                    }
                    .detailLink(false)
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

    func stationsSectionTrending(frame: DataFrame, count: Int = 256, title: Text = Text("Trending")) -> some View {
        let trendingFrame = { frame.sorted(on: Station.clicktrendColumn, order: .descending).prefix(count) }
        return NavigationLink(destination: StationList(title: title, frame: trendingFrame)) {
            title.label(symbol: "flame", color: .orange)
        }
        .detailLink(false)
    }

    func stationsSectionPopular(frame: DataFrame, count: Int = 256, title: Text = Text("Popular")) -> some View {
        let popularFrame = { frame.sorted(on: Station.clickcountColumn, order: .descending).prefix(count) }
        return NavigationLink(destination: StationList(title: title, frame: popularFrame)) {
            title.label(symbol: "star", color: .yellow)
        }
        .detailLink(false)
    }

    func stationsSectionQuality(frame: DataFrame, targetBitrate: Double = 320, count: Int = 256, title: Text = Text("Hi–Fi")) -> some View {
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
    @StateObject var tuner: RadioTuner
    @Binding var itemTitle: String?
    /// The current play rate
    @State var rate: Float = 0.0

    init(station: Station, itemTitle: Binding<String?>) {
        self.station = station
        self._itemTitle = itemTitle
        self._tuner = StateObject(wrappedValue: RadioTuner(streamingURL: wip(station.streamingURL!))) // TODO: check for bad url
    }

    var body: some View {
        VideoPlayer(player: tuner.player) {
            VStack {
                Spacer()
                Text(station.name ?? "")
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity)

                Text("Now Playing: \(tuner.itemTitle)")
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity)

                Spacer()
                Spacer()

            }
            //.background(station.imageView().blur(radius: 20, opaque: true))
            .background(Material.thick)
        }
        .onReceive(NotificationCenter.default.publisher(for: AVPlayer.rateDidChangeNotification, object: tuner.player)) { note in
            self.rate = (note.object as! AVPlayer).rate
        }
        .textSelection(.enabled)
        .onAppear {
            //tuner.player.prepareToPlay()
            tuner.player.play()
        }
        .toolbar(id: "playpausetoolbar") {
            ToolbarItem(id: "play", placement: ToolbarItemPlacement.navigation, showsByDefault: true) {
                Button {
                    dbg("playing")
                    tuner.player.play()
                } label: {
                    Text("Play").label(symbol: "play").symbolVariant(.fill)
                }
                .keyboardShortcut(.space, modifiers: [])
                .disabled(self.rate > 0)
                .help(Text("Play the current track"))
            }
            ToolbarItem(id: "pause", placement: ToolbarItemPlacement.navigation, showsByDefault: true) {
                Button {
                    dbg("pausing")
                    tuner.player.pause()
                } label: {
                    Text("Pause").label(symbol: "pause").symbolVariant(.fill)
                }
                .keyboardShortcut(.space, modifiers: [])
                .disabled(self.rate == 0)
                .help(Text("Pause the current track"))
            }
        }
        .onChange(of: tuner.itemTitle, perform: updateTitle)
        //.preference(key: TrackTitleKey.self, value: tuner.itemTitle)
        //.focusedSceneValue(\.trackTitle, tuner.itemTitle)
        .navigation(title: station.name.flatMap(Text.init) ?? Text("Unknown Station"), subtitle: Text(tuner.itemTitle))
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
        case "60s": return (tagString, Text("tag-60s"), Image(systemName: "6.circle"))
        case "70s": return (tagString, Text("tag-70s"), Image(systemName: "7.circle"))
        case "80s": return (tagString, Text("tag-80s"), Image(systemName: "8.circle"))
        case "90s": return (tagString, Text("tag-90s"), Image(systemName: "9.circle"))

        case "pop": return (tagString, Text("tag-pop"), Image(systemName: "sparkles"))
        case "news": return (tagString, Text("tag-news"), Image(systemName: "newspaper"))

        case "rock": return (tagString, Text("tag-rock"), Image(systemName: "guitars"))
        case "classic rock": return (tagString, Text("tag-classic-rock"), Image(systemName: "guitars"))
        case "pop rock": return (tagString, Text("tag-pop-rock"), Image(systemName: "guitars"))

        case "metal": return (tagString, Text("tag-metal"), Image(systemName: "amplifier"))
        case "hard rock": return (tagString, Text("tag-hard-rock"), Image(systemName: "amplifier"))

        case "npr": return (tagString, Text("tag-npr"), Image(systemName: "building.columns"))
        case "public radio": return (tagString, Text("tag-public-radio"), Image(systemName: "building.columns"))
        case "community radio": return (tagString, Text("tag-community-radio"), Image(systemName: "building.columns"))

        case "classical": return (tagString, Text("tag-classical"), Image(systemName: "theatermasks"))

        case "music": return (tagString, Text("tag-music"), Image(systemName: "music.note"))
        case "talk": return (tagString, Text("tag-talk"), Image(systemName: "mic.square"))
        case "dance": return (tagString, Text("tag-dance"), Image(systemName: "figure.walk"))
        case "spanish": return (tagString, Text("tag-spanish"), Image(systemName: "globe.europe.africa"))
        case "top 40": return (tagString, Text("tag-top-40"), Image(systemName: "chart.bar"))
        case "greek": return (tagString, Text("tag-greek"), Image(systemName: "globe.europe.africa"))
        case "radio": return (tagString, Text("tag-radio"), Image(systemName: "radio"))
        case "oldies": return (tagString, Text("tag-oldies"), Image(systemName: "tortoise"))
        case "fm": return (tagString, Text("tag-fm"), Image(systemName: "antenna.radiowaves.left.and.right"))
        case "méxico": return (tagString, Text("tag-méxico"), Image(systemName: "globe.americas"))
        case "christian": return (tagString, Text("tag-christian"), Image(systemName: "cross"))
        case "hits": return (tagString, Text("tag-hits"), Image(systemName: "sparkle"))
        case "mexico": return (tagString, Text("tag-mexico"), Image(systemName: "globe.americas"))
        case "local news": return (tagString, Text("tag-local-news"), Image(systemName: "newspaper"))
        case "german": return (tagString, Text("tag-german"), Image(systemName: "globe.europe.africa"))
        case "deutsch": return (tagString, Text("tag-deutsch"), Image(systemName: "globe.europe.africa"))
        case "university radio": return (tagString, Text("tag-university-radio"), Image(systemName: "graduationcap"))
        case "chillout": return (tagString, Text("tag-chillout"), Image(systemName: "snowflake"))
        case "ambient": return (tagString, Text("tag-ambient"), Image(systemName: "headphones"))
        case "world music": return (tagString, Text("tag-world-music"), Image(systemName: "globe"))
        case "french": return (tagString, Text("tag-french"), Image(systemName: "globe.europe.africa"))
        case "local music": return (tagString, Text("tag-local-music"), Image(systemName: "flag"))
        case "disco": return (tagString, Text("tag-disco"), Image(systemName: "dot.arrowtriangles.up.right.down.left.circle"))
        case "regional mexican": return (tagString, Text("tag-regional-mexican"), Image(systemName: "globe.americas"))
        case "electro": return (tagString, Text("tag-electro"), Image(systemName: "cable.connector.horizontal"))
        case "talk & speech": return (tagString, Text("tag-talk-&-speech"), Image(systemName: "text.bubble"))
        case "college radio": return (tagString, Text("tag-college-radio"), Image(systemName: "graduationcap"))
        case "catholic": return (tagString, Text("tag-catholic"), Image(systemName: "cross"))
        case "regional radio": return (tagString, Text("tag-regional-radio"), Image(systemName: "flag"))
        case "musica regional mexicana": return (tagString, Text("tag-musica-regional-mexicana"), Image(systemName: "m.circle"))
        case "charts": return (tagString, Text("tag-charts"), Image(systemName: "chart.bar"))
        case "regional": return (tagString, Text("tag-regional"), Image(systemName: "flag"))
        case "russian": return (tagString, Text("tag-russian"), Image(systemName: "globe.asia.australia"))
        case "musica regional": return (tagString, Text("tag-musica-regional"), Image(systemName: "flag"))

        case "religion": return (tagString, Text("tag-religion"), Image(systemName: "staroflife"))
        case "pop music": return (tagString, Text("tag-pop-music"), Image(systemName: "person.3"))
        case "easy listening": return (tagString, Text("tag-easy-listening"), Image(systemName: "dial.min"))
        case "culture": return (tagString, Text("tag-culture"), Image(systemName: "metronome"))
        case "mainstream": return (tagString, Text("tag-mainstream"), Image(systemName: "gauge"))
        case "news talk": return (tagString, Text("tag-news-talk"), Image(systemName: "captions.bubble"))
        case "commercial": return (tagString, Text("tag-commercial"), Image(systemName: "coloncurrencysign.circle"))
        case "folk": return (tagString, Text("tag-folk"), Image(systemName: "tuningfork"))

        case "sport": return (tagString, Text("tag-sport"), Image(systemName: "figure.walk.diamond"))
        case "jazz": return (tagString, Text("tag-jazz"), Image(systemName: "ear"))
        case "country": return (tagString, Text("tag-country"), Image(systemName: "photo"))
        case "house": return (tagString, Text("tag-house"), Image(systemName: "house"))
        case "soul": return (tagString, Text("tag-soul"), Image(systemName: "suit.heart"))
        case "reggae": return (tagString, Text("tag-reggae"), Image(systemName: "smoke"))

        // default (letter) icons
        case "classic hits": return (tagString, Text("tag-classic-hits"), Image(systemName: "c.circle"))
        case "electronic": return (tagString, Text("tag-electronic"), Image(systemName: "e.circle"))
        case "funk": return (tagString, Text("tag-funk"), Image(systemName: "f.circle"))
        case "blues": return (tagString, Text("tag-blues"), Image(systemName: "b.circle"))

        case "english": return (tagString, Text("tag-english"), Image(systemName: "e.circle"))
        case "español": return (tagString, Text("tag-español"), Image(systemName: "e.circle"))
        case "estación": return (tagString, Text("tag-estación"), Image(systemName: "e.circle"))
        case "mex": return (tagString, Text("tag-mex"), Image(systemName: "m.circle"))
        case "mx": return (tagString, Text("tag-mx"), Image(systemName: "m.circle"))
        case "adult contemporary": return (tagString, Text("tag-adult-contemporary"), Image(systemName: "a.circle"))
        case "alternative": return (tagString, Text("tag-alternative"), Image(systemName: "a.circle"))
        case "música": return (tagString, Text("tag-música"), Image(systemName: "m.circle"))
        case "hiphop": return (tagString, Text("tag-hiphop"), Image(systemName: "h.circle"))
        case "musica": return (tagString, Text("tag-musica"), Image(systemName: "m.circle"))
        case "s": return (tagString, Text("tag-s"), Image(systemName: "s.circle"))
        case "indie": return (tagString, Text("tag-indie"), Image(systemName: "i.circle"))
        case "information": return (tagString, Text("tag-information"), Image(systemName: "i.circle"))
        case "techno": return (tagString, Text("tag-techno"), Image(systemName: "t.circle"))
        case "noticias": return (tagString, Text("tag-noticias"), Image(systemName: "n.circle"))
        case "música pop": return (tagString, Text("tag-música-pop"), Image(systemName: "m.circle"))
        case "lounge": return (tagString, Text("tag-lounge"), Image(systemName: "l.circle"))
        case "alternative rock": return (tagString, Text("tag-alternative-rock"), Image(systemName: "a.circle"))
        case "on": return (tagString, Text("tag-on"), Image(systemName: "o.circle"))
        case "aac": return (tagString, Text("tag-aac"), Image(systemName: "a.circle"))
        case "rnb": return (tagString, Text("tag-rnb"), Image(systemName: "r.circle"))
        case "juvenil": return (tagString, Text("tag-juvenil"), Image(systemName: "j.circle"))
        case "grupera": return (tagString, Text("tag-grupera"), Image(systemName: "g.circle"))
        case "trance": return (tagString, Text("tag-trance"), Image(systemName: "t.circle"))
        case "rap": return (tagString, Text("tag-rap"), Image(systemName: "r.circle"))
        case "latin music": return (tagString, Text("tag-latin-music"), Image(systemName: "l.circle"))
        case "edm": return (tagString, Text("tag-edm"), Image(systemName: "e.circle"))
        case "entertainment": return (tagString, Text("tag-entertainment"), Image(systemName: "e.circle"))
        case "variety": return (tagString, Text("tag-variety"), Image(systemName: "v.circle"))
        case "entretenimiento": return (tagString, Text("tag-entretenimiento"), Image(systemName: "e.circle"))
        case "xp_5": return (tagString, Text("tag-xp_5"), Image(systemName: "u.circle"))
        case "g_7": return (tagString, Text("tag-g_7"), Image(systemName: "g.circle"))

        default: return nil
        }
    }

}
