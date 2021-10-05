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

@available(macOS 12.0, iOS 15.0, *)
struct Station : Pure, Identifiable {

    var id: Int { StationID }
    let StationID: Int
    let Name: String?
    let Url: String?
    let Homepage: String?
    let Favicon: String?
    let Creation: String?
    let Country: String?
    let Language: String?
    let Tags: String?
    let Votes: Int?
    let Subcountry: String?
    let clickcount: Int?
    let ClickTrend: String?
    let ClickTimestamp: String?
    let Codec: String?
    let LastCheckOK: String?
    let LastCheckTime: String?
    let Bitrate: Int?
    let UrlCache: String?
    let LastCheckOkTime: String?
    let Hls: String?
    let ChangeUuid: String?
    let StationUuid: String?
    let CountryCode: String?
    let LastLocalCheckTime: String?
    let CountrySubdivisionCode: String?
    let GeoLat: String?
    let GeoLong: String?
    let SslError: String?
    let LanguageCodes: String?
    let ExtendedInfo: String?

    static let StationIDID = ColumnID("StationID", Int.self)
    static let NameID = ColumnID("Name", String.self)
    static let UrlID = ColumnID("Url", String.self)
    static let HomepageID = ColumnID("Homepage", String.self)
    static let FaviconID = ColumnID("Favicon", String.self)
    static let CreationID = ColumnID("Creation", String.self)
    static let CountryID = ColumnID("Country", String.self)
    static let LanguageID = ColumnID("Language", String.self)
    static let TagsID = ColumnID("Tags", String.self)
    static let VotesID = ColumnID("Votes", Int.self)
    static let SubcountryID = ColumnID("Subcountry", String.self)
    static let clickcountID = ColumnID("clickcount", Int.self)
    static let ClickTrendID = ColumnID("ClickTrend", String.self)
    static let ClickTimestampID = ColumnID("ClickTimestamp", String.self)
    static let CodecID = ColumnID("Codec", String.self)
    static let LastCheckOKID = ColumnID("LastCheckOK", String.self)
    static let LastCheckTimeID = ColumnID("LastCheckTime", String.self)
    static let BitrateID = ColumnID("Bitrate", Int.self)
    static let UrlCacheID = ColumnID("UrlCache", String.self)
    static let LastCheckOkTimeID = ColumnID("LastCheckOkTime", String.self)
    static let HlsID = ColumnID("Hls", String.self)
    static let ChangeUuidID = ColumnID("ChangeUuid", String.self)
    static let StationUuidID = ColumnID("StationUuid", String.self)
    static let CountryCodeID = ColumnID("CountryCode", String.self)
    static let LastLocalCheckTimeID = ColumnID("LastLocalCheckTime", String.self)
    static let CountrySubdivisionCodeID = ColumnID("CountrySubdivisionCode", String.self)
    static let GeoLatID = ColumnID("GeoLat", String.self)
    static let GeoLongID = ColumnID("GeoLong", String.self)
    static let SslErrorID = ColumnID("SslError", String.self)
    static let LanguageCodesID = ColumnID("LanguageCodes", String.self)
    static let ExtendedInfoID = ColumnID("ExtendedInfo", String.self)

    init(row: DataFrame.Row) {
        self.StationID = row[Self.StationIDID] ?? 0
        self.Name = row[Self.NameID]
        self.Url = row[Self.UrlID]
        self.Homepage = row[Self.HomepageID]
        self.Favicon = row[Self.FaviconID]
        self.Creation = row[Self.CreationID]
        self.Country = row[Self.CountryID]
        self.Language = row[Self.LanguageID]
        self.Tags = row[Self.TagsID]
        self.Votes = row[Self.VotesID]
        self.Subcountry = row[Self.SubcountryID]
        self.clickcount = row[Self.clickcountID]
        self.ClickTrend = row[Self.ClickTrendID]
        self.ClickTimestamp = row[Self.ClickTimestampID]
        self.Codec = row[Self.CodecID]
        self.LastCheckOK = row[Self.LastCheckOKID]
        self.LastCheckTime = row[Self.LastCheckTimeID]
        self.Bitrate = row[Self.BitrateID]
        self.UrlCache = row[Self.UrlCacheID]
        self.LastCheckOkTime = row[Self.LastCheckOkTimeID]
        self.Hls = row[Self.HlsID]
        self.ChangeUuid = row[Self.ChangeUuidID]
        self.StationUuid = row[Self.StationUuidID]
        self.CountryCode = row[Self.CountryCodeID]
        self.LastLocalCheckTime = row[Self.LastLocalCheckTimeID]
        self.CountrySubdivisionCode = row[Self.CountrySubdivisionCodeID]
        self.GeoLat = row[Self.GeoLatID]
        self.GeoLong = row[Self.GeoLongID]
        self.SslError = row[Self.SslErrorID]
        self.LanguageCodes = row[Self.LanguageCodesID]
        self.ExtendedInfo = row[Self.ExtendedInfoID]
    }

    var url: URL? {
        Url.flatMap(URL.init(string:))
    }

    func iconView(size: CGFloat) -> some View {
        let url = URL(string: self.Favicon ?? "about:blank") ?? URL(string: "about:blank")!
        return AsyncImage(url: url, content: { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
        }, placeholder: {
            ZStack {
                Rectangle()
                    .fill(Material.thin)

                // use a blurred color flag backdrop
                let countryCode = self.CountryCode?.isEmpty != false ? "UN" : (self.CountryCode ?? "")
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
            let dateFieldParse = CSVType.string
            //let dateFieldParse = CSVType.date

            /*
             StationID: 1
             Name: "Austrian Rock Radio"
             Url: "http://live.antenne.at/arr"
             Homepage: "http://www.austrianrockradio.at/"
             Favicon: "http://www.austrianrockradio.at/radioplayer/img/logo.png"
             Creation: "2021-08-06 08:36:43"
             Country: "Austria"
             Language: ""
             Tags: "rock"
             Votes: 287
             Subcountry: ""
             clickcount: 20
             ClickTrend: 1
             ClickTimestamp: "2021-09-23 13:10:07"
             Codec: "MP3"
             LastCheckOK: 1
             LastCheckTime: "2021-09-23 22:30:53"
             Bitrate: 128
             UrlCache: "http://live.antenne.at/arr"
             LastCheckOkTime: "2021-09-23 22:30:53"
             Hls: 0
             ChangeUuid: "96057c1d-0601-11e8-ae97-52543be04c81"
             StationUuid: "96057c18-0601-11e8-ae97-52543be04c81"
             CountryCode: "AT"
             LastLocalCheckTime: "2021-09-23 18:25:57"
             CountrySubdivisionCode: NULL
             GeoLat: NULL
             GeoLong: NULL
             SslError: 0
             LanguageCodes: NULL
             ExtendedInfo: 0
             */
            let columns = [
                Station.StationIDID.name : CSVType.integer,
                Station.NameID.name : CSVType.string,
                Station.UrlID.name : CSVType.string,
                Station.HomepageID.name : CSVType.string,
                Station.FaviconID.name : CSVType.string,
                Station.CreationID.name : dateFieldParse,
                Station.CountryID.name : CSVType.string,
                Station.LanguageID.name : CSVType.string,
                Station.TagsID.name : CSVType.string,
                Station.VotesID.name : CSVType.integer,
                Station.SubcountryID.name : CSVType.string,
                Station.clickcountID.name : CSVType.integer,
                Station.ClickTrendID.name : CSVType.string,
                Station.ClickTimestampID.name : CSVType.string,
                Station.CodecID.name : CSVType.string,
                Station.LastCheckOKID.name : CSVType.string,
                Station.LastCheckTimeID.name : dateFieldParse,
                Station.BitrateID.name : CSVType.integer,
                Station.UrlCacheID.name : CSVType.string,
                Station.LastCheckOkTimeID.name : dateFieldParse,
                Station.HlsID.name : CSVType.string,
                Station.ChangeUuidID.name : CSVType.string,
                Station.StationUuidID.name : CSVType.string,
                Station.CountryCodeID.name : CSVType.string,
                Station.LastLocalCheckTimeID.name : dateFieldParse,
                Station.CountrySubdivisionCodeID.name : CSVType.string,
                Station.GeoLatID.name : CSVType.string,
                Station.GeoLongID.name : CSVType.string,
                Station.SslErrorID.name : CSVType.string,
                Station.LanguageCodesID.name : CSVType.string,
                Station.ExtendedInfoID.name : CSVType.string,
            ]
            
            let df = try DataFrame(contentsOfCSVFile: url, columns: nil, rows: nil, types: columns, options: options)
            return StationCatalog(frame: df)
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
    var stationID: Int? {
        self[Station.StationIDID]
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
            .filter({ queryString.isEmpty || ($0[Station.NameID]?.localizedCaseInsensitiveContains(queryString) == true) })
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
            guard let uuid = station.StationUuid else {
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
                        .disabled(station.StationUuid == nil)
                })
            }
            .tint(.yellow)
        }
    }


    func stationLabelTitle(_ station: Station) -> some View {
        VStack(alignment: .leading) {
            (station.Name.map(Text.init) ?? Text("Unknown Name"))
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


                let br = station.Bitrate ?? 0
                (Text(station.Bitrate == nil ? Double.nan : Double(br), format: .number) + Text("k"))
                    .foregroundColor(br >= 256 ? Color.green : br < 128 ? Color.gray : Color.blue)
                    .font(.body.monospaced())

                HStack(spacing: 2) {
                    let tags = station.tagElements
                        .compactMap(Station.tagInfo(tagString:))
                    ForEach(enumerated: tags) { offset, titleImage in
                        titleImage.image
                            .symbolRenderingMode(.hierarchical)
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

                    NavigationLink(destination: StationList(frame: frame.filter({ $0[Station.LanguageID] == lang.value })).navigationTitle(Text("Language: ") + title)) {
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

                    NavigationLink(destination: StationList(frame: frame.filter({ $0[Station.TagsID] == tag.value })).navigationTitle(Text("Tag: ") + title)) {
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
        NavigationLink(destination: StationList(frame: frame.sorted(on: Station.clickcountID, order: .descending).prefix(count)).navigationTitle(title)) {
            title.label(symbol: "star")
        }
    }

    func stationsSectionPinned(frame: DataFrame, title: Text = Text("Pinned")) -> some View {
        NavigationLink(destination: StationList(frame: frame.filter({ row in
            pinnedStations.contains(row[Station.StationUuidID] ?? "")
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

                    NavigationLink(destination: StationList(frame: frame.filter({ $0[Station.CountryCodeID] == country.valueCount.value })).navigationTitle(navTitle)) {
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
        self._tuner = StateObject(wrappedValue: RadioTuner(streamingURL: wip(source.url!))) // TODO: check for bad url
    }

    var body: some View {
        VideoPlayer(player: tuner.player) {
            VStack {
                Spacer()
                Text(source.Name ?? "")
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

//@available(macOS 12.0, iOS 15.0, *)
//struct StationsListView: View {
//    let category: String?
//    let catalog = Catalog.defaultCatalog
//    @State var selection: Source? = nil
//
//    var body: some View {
//        List((try? catalog.get()?.sources.filter({ $0.category == category })) ?? [], id: \.self) { source in
//            // public init<V>(tag: V, selection: Binding<V?>, @ViewBuilder destination: () -> Destination, @ViewBuilder label: () -> Label) where V : Hashable
//
//            NavigationLink(tag: source, selection: $selection, destination: { StationViewOLD(source: source) }) {
//                Label(title: {
//                    Text(source.name)
//                        .lineLimit(1)
//                        .allowsTightening(true)
//                        .truncationMode(.middle)
//                }) {
//                    AsyncImage(url: source.logo)
//                        .frame(width: 20, height: 20)
//                }
//
//            }
//        }
//        //        .navigationTitle("World")
//        //        .toolbar {
//        //            Button(action: { }) {
//        //                Image(systemName: "line.horizontal.3.decrease.circle")
//        //            }
//        //        }
//    }
//}


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
        (Tags ?? "").split(separator: ",")
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

