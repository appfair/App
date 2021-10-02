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
    let Bitrate: String?
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

    init(row: DataFrame.Row) {
        self.StationID = row["StationID"] as? Int ?? 0
        self.Name = row["Name"] as? String
        self.Url = row["Url"] as? String
        self.Homepage = row["Homepage"] as? String
        self.Favicon = row["Favicon"] as? String
        self.Creation = row["Creation"] as? String
        self.Country = row["Country"] as? String
        self.Language = row["Language"] as? String
        self.Tags = row["Tags"] as? String
        self.Votes = row["Votes"] as? Int
        self.Subcountry = row["Subcountry"] as? String
        self.clickcount = row["clickcount"] as? Int
        self.ClickTrend = row["ClickTrend"] as? String
        self.ClickTimestamp = row["ClickTimestamp"] as? String
        self.Codec = row["Codec"] as? String
        self.LastCheckOK = row["LastCheckOK"] as? String
        self.LastCheckTime = row["LastCheckTime"] as? String
        self.Bitrate = row["Bitrate"] as? String
        self.UrlCache = row["UrlCache"] as? String
        self.LastCheckOkTime = row["LastCheckOkTime"] as? String
        self.Hls = row["Hls"] as? String
        self.ChangeUuid = row["ChangeUuid"] as? String
        self.StationUuid = row["StationUuid"] as? String
        self.CountryCode = row["CountryCode"] as? String
        self.LastLocalCheckTime = row["LastLocalCheckTime"] as? String
        self.CountrySubdivisionCode = row["CountrySubdivisionCode"] as? String
        self.GeoLat = row["GeoLat"] as? String
        self.GeoLong = row["GeoLong"] as? String
        self.SslError = row["SslError"] as? String
        self.LanguageCodes = row["LanguageCodes"] as? String
        self.ExtendedInfo = row["ExtendedInfo"] as? String
    }

    var url: URL? {
        Url.flatMap(URL.init(string:))
    }

    func imageView() -> some View {
        self.Favicon.flatMap {
            URL(string: $0).flatMap {
                AsyncImage(url: $0, content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipped()
                }, placeholder: {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.gray.opacity(0.4))
                })
            }
        }
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
                "StationID" : CSVType.integer,
                "Name" : CSVType.string,
                "Url" : CSVType.string,
                "Homepage" : CSVType.string,
                "Favicon" : CSVType.string,
                "Creation" : dateFieldParse,
                "Country" : CSVType.string,
                "Language" : CSVType.string,
                "Tags" : CSVType.string,
                "Votes" : CSVType.integer,
                "Subcountry" : CSVType.string,
                "clickcount" : CSVType.integer,
                "ClickTrend" : CSVType.string,
                "ClickTimestamp" : CSVType.string,
                "Codec" : CSVType.string,
                "LastCheckOK" : CSVType.string,
                "LastCheckTime" : dateFieldParse,
                "Bitrate" : CSVType.string,
                "UrlCache" : CSVType.string,
                "LastCheckOkTime" : dateFieldParse,
                "Hls" : CSVType.string,
                "ChangeUuid" : CSVType.string,
                "StationUuid" : CSVType.string,
                "CountryCode" : CSVType.string,
                "LastLocalCheckTime" : dateFieldParse,
                "CountrySubdivisionCode" : CSVType.string,
                "GeoLat" : CSVType.string,
                "GeoLong" : CSVType.string,
                "SslError" : CSVType.string,
                "LanguageCodes" : CSVType.string,
                "ExtendedInfo" : CSVType.string,
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
            .sorted(on: column)
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
        // Bundle.module.loadResource(named: "catalog.json") // non-localized

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
            Text("No Sidebar Selection")
            Text("Select Station").font(.headline)
        }

    }
}


@available(macOS 12.0, iOS 15.0, *)
struct StationList<T: Equatable> : View {
    let column: ColumnID<T>
    let valueCount: ValueCount<T>?
    @State var selection: Station?

    var body: some View {
        List {
            ForEach(filteredElements, content: stationElement)
        }
    }

    var filteredElements: [Station] {
        ((StationCatalog.stations.successValue?.frame.rows)?
            .filter { row in
                row[column] == valueCount?.value
            } ?? [])
            .map(Station.init(row:))
    }

    func stationElement(station: Station) -> some View {
        // Text(station.Name ?? "Unknown")
        NavigationLink(tag: station, selection: $selection, destination: {
            StationView(source: station)
        }) {
            Label(title: {
                (station.Name.map(Text.init) ?? Text("Unknown Name"))
                    .lineLimit(1)
                    .allowsTightening(true)
                    .truncationMode(.middle)
                //(station.Tags.map(Text.init) ?? Text("No Tags"))
                //    .lineLimit(1)
                //    .allowsTightening(true)
                //    .truncationMode(.middle)
            }) {
                Rectangle()
                    .fill(.clear)
                    .background(station.imageView().clipped())
                    .frame(width: 25, height: 25)
            }
            .badge(station.Bitrate)
            //.badge(station.Votes?.localizedNumber())

        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct Sidebar: View {
    var body: some View {
        List {
            countriesSection
            tagsSection
            languagesSection
        }
        .listStyle(SidebarListStyle())
    }

    var languagesSection: some View {
        Section {
            ForEach(StationCatalog.languageCounts.successValue ?? [], id: \.value) { lang in
                NavigationLink(destination: StationList(column: ColumnID("Language", String.self), valueCount: lang)) {
                    Label(title: {
                        Text(lang.value)
                    }, icon: {
                        //Text(emojiFlag(countryCode: lang.value))
                    })
                        .badge(lang.count)
                }
            }
        } header: {
            Text("Tags")
        }
    }

    var tagsSection: some View {
        Section {
            ForEach(StationCatalog.tagsCounts.successValue ?? [], id: \.value) { tag in
                NavigationLink(destination: StationList(column: ColumnID("Tags", String.self), valueCount: tag)) {
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
        } header: {
            Text("Languages")
        }
    }

    var countriesSection: some View {
        Section {
            ForEach(StationCatalog.countryCounts.successValue ?? [], id: \.value) { country in
                NavigationLink(destination: StationList(column: ColumnID("CountryCode", String.self), valueCount: country)) {
                    Label(title: {
                        if let countryName = (Locale.current as NSLocale).displayName(forKey: .countryCode, value: country.value) {
                            Text(countryName)
                        } else {
                            Text("Unknown")
                        }
                    }, icon: {
                        Text(emojiFlag(countryCode: country.value))
                    })
                        .badge(country.count)
                }
            }
        } header: {
            Text("Countries")
        }
    }

    func emojiFlag(countryCode: String) -> String {
        let codes = countryCode.unicodeScalars.compactMap {
            UnicodeScalar(127397 + $0.value)
        }
        return String(codes.map(Character.init))
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
