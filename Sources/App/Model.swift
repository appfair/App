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
import TabularData


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
    var hls: String?
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
    static let hlsColumn = ColumnID("hls", String.self)
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


extension Station {
    /// The parsed `Tags` field
    var tagElements: [String] {
        (self.tags ?? "").split(separator: ",")
            .map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }
    }

    /// Returns the text and image for known tags
    static func tagInfo(tagString: String) -> (key: String, title: Text, image: Image, tint: Color)? {
        // check the top 100 tag list with:
        // cat Sources/App/Resources/stations.csv | tr '"' '\n' | grep ',' | tr ',' '\n' | tr '[A-Z]' '[a-z]' | grep '[a-z]' | sort | uniq -c | sort -nr | head -n 100

        let tint = Color(hue: tagString.hueComponent, saturation: 0.8, brightness: 0.8)

        switch tagString {
        case "60s": return (tagString, Text("tag-60s", bundle: .module, comment: "station tag name"), Image(systemName: "6.circle"), tint)
        case "70s": return (tagString, Text("tag-70s", bundle: .module, comment: "station tag name"), Image(systemName: "7.circle"), tint)
        case "80s": return (tagString, Text("tag-80s", bundle: .module, comment: "station tag name"), Image(systemName: "8.circle"), tint)
        case "90s": return (tagString, Text("tag-90s", bundle: .module, comment: "station tag name"), Image(systemName: "9.circle"), tint)

        case "pop": return (tagString, Text("tag-pop", bundle: .module, comment: "station tag name"), Image(systemName: "sparkles"), tint)
        case "news": return (tagString, Text("tag-news", bundle: .module, comment: "station tag name"), Image(systemName: "newspaper"), tint)

        case "rock": return (tagString, Text("tag-rock", bundle: .module, comment: "station tag name"), Image(systemName: "guitars"), tint)
        case "classic rock": return (tagString, Text("tag-classic-rock", bundle: .module, comment: "station tag name"), Image(systemName: "guitars"), tint)
        case "pop rock": return (tagString, Text("tag-pop-rock", bundle: .module, comment: "station tag name"), Image(systemName: "guitars"), tint)

        case "metal": return (tagString, Text("tag-metal", bundle: .module, comment: "station tag name"), Image(systemName: "amplifier"), tint)
        case "hard rock": return (tagString, Text("tag-hard-rock", bundle: .module, comment: "station tag name"), Image(systemName: "amplifier"), tint)

        case "npr": return (tagString, Text("tag-npr", bundle: .module, comment: "station tag name"), Image(systemName: "building.columns"), tint)
        case "public radio": return (tagString, Text("tag-public-radio", bundle: .module, comment: "station tag name"), Image(systemName: "building.columns"), tint)
        case "community radio": return (tagString, Text("tag-community-radio", bundle: .module, comment: "station tag name"), Image(systemName: "building.columns"), tint)

        case "classical": return (tagString, Text("tag-classical", bundle: .module, comment: "station tag name"), Image(systemName: "theatermasks"), tint)

        case "music": return (tagString, Text("tag-music", bundle: .module, comment: "station tag name"), Image(systemName: "music.note"), tint)
        case "talk": return (tagString, Text("tag-talk", bundle: .module, comment: "station tag name"), Image(systemName: "mic.square"), tint)
        case "dance": return (tagString, Text("tag-dance", bundle: .module, comment: "station tag name"), Image(systemName: "figure.walk"), tint)
        case "spanish": return (tagString, Text("tag-spanish", bundle: .module, comment: "station tag name"), Image(systemName: "globe.europe.africa"), tint)
        case "top 40": return (tagString, Text("tag-top-40", bundle: .module, comment: "station tag name"), Image(systemName: "chart.bar"), tint)
        case "greek": return (tagString, Text("tag-greek", bundle: .module, comment: "station tag name"), Image(systemName: "globe.europe.africa"), tint)
        case "radio": return (tagString, Text("tag-radio", bundle: .module, comment: "station tag name"), Image(systemName: "radio"), tint)
        case "oldies": return (tagString, Text("tag-oldies", bundle: .module, comment: "station tag name"), Image(systemName: "tortoise"), tint)
        case "fm": return (tagString, Text("tag-fm", bundle: .module, comment: "station tag name"), Image(systemName: "antenna.radiowaves.left.and.right"), tint)
        case "méxico": return (tagString, Text("tag-méxico", bundle: .module, comment: "station tag name"), Image(systemName: "globe.americas"), tint)
        case "christian": return (tagString, Text("tag-christian", bundle: .module, comment: "station tag name"), Image(systemName: "cross"), tint)
        case "hits": return (tagString, Text("tag-hits", bundle: .module, comment: "station tag name"), Image(systemName: "sparkle"), tint)
        case "mexico": return (tagString, Text("tag-mexico", bundle: .module, comment: "station tag name"), Image(systemName: "globe.americas"), tint)
        case "local news": return (tagString, Text("tag-local-news", bundle: .module, comment: "station tag name"), Image(systemName: "newspaper"), tint)
        case "german": return (tagString, Text("tag-german", bundle: .module, comment: "station tag name"), Image(systemName: "globe.europe.africa"), tint)
        case "deutsch": return (tagString, Text("tag-deutsch", bundle: .module, comment: "station tag name"), Image(systemName: "globe.europe.africa"), tint)
        case "university radio": return (tagString, Text("tag-university-radio", bundle: .module, comment: "station tag name"), Image(systemName: "graduationcap"), tint)
        case "chillout": return (tagString, Text("tag-chillout", bundle: .module, comment: "station tag name"), Image(systemName: "snowflake"), tint)
        case "ambient": return (tagString, Text("tag-ambient", bundle: .module, comment: "station tag name"), Image(systemName: "headphones"), tint)
        case "world music": return (tagString, Text("tag-world-music", bundle: .module, comment: "station tag name"), Image(systemName: "globe"), tint)
        case "french": return (tagString, Text("tag-french", bundle: .module, comment: "station tag name"), Image(systemName: "globe.europe.africa"), tint)
        case "local music": return (tagString, Text("tag-local-music", bundle: .module, comment: "station tag name"), Image(systemName: "flag"), tint)
        case "disco": return (tagString, Text("tag-disco", bundle: .module, comment: "station tag name"), Image(systemName: "dot.arrowtriangles.up.right.down.left.circle"), tint)
        case "regional mexican": return (tagString, Text("tag-regional-mexican", bundle: .module, comment: "station tag name"), Image(systemName: "globe.americas"), tint)
        case "electro": return (tagString, Text("tag-electro", bundle: .module, comment: "station tag name"), Image(systemName: "cable.connector.horizontal"), tint)
        case "talk & speech": return (tagString, Text("tag-talk-&-speech", bundle: .module, comment: "station tag name"), Image(systemName: "text.bubble"), tint)
        case "college radio": return (tagString, Text("tag-college-radio", bundle: .module, comment: "station tag name"), Image(systemName: "graduationcap"), tint)
        case "catholic": return (tagString, Text("tag-catholic", bundle: .module, comment: "station tag name"), Image(systemName: "cross"), tint)
        case "regional radio": return (tagString, Text("tag-regional-radio", bundle: .module, comment: "station tag name"), Image(systemName: "flag"), tint)
        case "musica regional mexicana": return (tagString, Text("tag-musica-regional-mexicana", bundle: .module, comment: "station tag name"), Image(systemName: "m.circle"), tint)
        case "charts": return (tagString, Text("tag-charts", bundle: .module, comment: "station tag name"), Image(systemName: "chart.bar"), tint)
        case "regional": return (tagString, Text("tag-regional", bundle: .module, comment: "station tag name"), Image(systemName: "flag"), tint)
        case "russian": return (tagString, Text("tag-russian", bundle: .module, comment: "station tag name"), Image(systemName: "globe.asia.australia"), tint)
        case "musica regional": return (tagString, Text("tag-musica-regional", bundle: .module, comment: "station tag name"), Image(systemName: "flag"), tint)

        case "religion": return (tagString, Text("tag-religion", bundle: .module, comment: "station tag name"), Image(systemName: "staroflife"), tint)
        case "pop music": return (tagString, Text("tag-pop-music", bundle: .module, comment: "station tag name"), Image(systemName: "person.3"), tint)
        case "easy listening": return (tagString, Text("tag-easy-listening", bundle: .module, comment: "station tag name"), Image(systemName: "dial.min"), tint)
        case "culture": return (tagString, Text("tag-culture", bundle: .module, comment: "station tag name"), Image(systemName: "metronome"), tint)
        case "mainstream": return (tagString, Text("tag-mainstream", bundle: .module, comment: "station tag name"), Image(systemName: "gauge"), tint)
        case "news talk": return (tagString, Text("tag-news-talk", bundle: .module, comment: "station tag name"), Image(systemName: "captions.bubble"), tint)
        case "commercial": return (tagString, Text("tag-commercial", bundle: .module, comment: "station tag name"), Image(systemName: "coloncurrencysign.circle"), tint)
        case "folk": return (tagString, Text("tag-folk", bundle: .module, comment: "station tag name"), Image(systemName: "tuningfork"), tint)

        case "sport": return (tagString, Text("tag-sport", bundle: .module, comment: "station tag name"), Image(systemName: "figure.walk.diamond"), tint)
        case "jazz": return (tagString, Text("tag-jazz", bundle: .module, comment: "station tag name"), Image(systemName: "ear"), tint)
        case "country": return (tagString, Text("tag-country", bundle: .module, comment: "station tag name"), Image(systemName: "photo"), tint)
        case "house": return (tagString, Text("tag-house", bundle: .module, comment: "station tag name"), Image(systemName: "house"), tint)
        case "soul": return (tagString, Text("tag-soul", bundle: .module, comment: "station tag name"), Image(systemName: "suit.heart"), tint)
        case "reggae": return (tagString, Text("tag-reggae", bundle: .module, comment: "station tag name"), Image(systemName: "smoke"), tint)

            // default (letter) icons
        case "classic hits": return (tagString, Text("tag-classic-hits", bundle: .module, comment: "station tag name"), Image(systemName: "c.circle"), tint)
        case "electronic": return (tagString, Text("tag-electronic", bundle: .module, comment: "station tag name"), Image(systemName: "e.circle"), tint)
        case "funk": return (tagString, Text("tag-funk", bundle: .module, comment: "station tag name"), Image(systemName: "f.circle"), tint)
        case "blues": return (tagString, Text("tag-blues", bundle: .module, comment: "station tag name"), Image(systemName: "b.circle"), tint)

        case "english": return (tagString, Text("tag-english", bundle: .module, comment: "station tag name"), Image(systemName: "e.circle"), tint)
        case "español": return (tagString, Text("tag-español", bundle: .module, comment: "station tag name"), Image(systemName: "e.circle"), tint)
        case "estación": return (tagString, Text("tag-estación", bundle: .module, comment: "station tag name"), Image(systemName: "e.circle"), tint)
        case "mex": return (tagString, Text("tag-mex", bundle: .module, comment: "station tag name"), Image(systemName: "m.circle"), tint)
        case "mx": return (tagString, Text("tag-mx", bundle: .module, comment: "station tag name"), Image(systemName: "m.circle"), tint)
        case "adult contemporary": return (tagString, Text("tag-adult-contemporary", bundle: .module, comment: "station tag name"), Image(systemName: "a.circle"), tint)
        case "alternative": return (tagString, Text("tag-alternative", bundle: .module, comment: "station tag name"), Image(systemName: "a.circle"), tint)
        case "música": return (tagString, Text("tag-música", bundle: .module, comment: "station tag name"), Image(systemName: "m.circle"), tint)
        case "hiphop": return (tagString, Text("tag-hiphop", bundle: .module, comment: "station tag name"), Image(systemName: "h.circle"), tint)
        case "musica": return (tagString, Text("tag-musica", bundle: .module, comment: "station tag name"), Image(systemName: "m.circle"), tint)
        case "s": return (tagString, Text("tag-s", bundle: .module, comment: "station tag name"), Image(systemName: "s.circle"), tint)
        case "indie": return (tagString, Text("tag-indie", bundle: .module, comment: "station tag name"), Image(systemName: "i.circle"), tint)
        case "information": return (tagString, Text("tag-information", bundle: .module, comment: "station tag name"), Image(systemName: "i.circle"), tint)
        case "techno": return (tagString, Text("tag-techno", bundle: .module, comment: "station tag name"), Image(systemName: "t.circle"), tint)
        case "noticias": return (tagString, Text("tag-noticias", bundle: .module, comment: "station tag name"), Image(systemName: "n.circle"), tint)
        case "música pop": return (tagString, Text("tag-música-pop", bundle: .module, comment: "station tag name"), Image(systemName: "m.circle"), tint)
        case "lounge": return (tagString, Text("tag-lounge", bundle: .module, comment: "station tag name"), Image(systemName: "l.circle"), tint)
        case "alternative rock": return (tagString, Text("tag-alternative-rock", bundle: .module, comment: "station tag name"), Image(systemName: "a.circle"), tint)
        case "on": return (tagString, Text("tag-on", bundle: .module, comment: "station tag name"), Image(systemName: "o.circle"), tint)
        case "aac": return (tagString, Text("tag-aac", bundle: .module, comment: "station tag name"), Image(systemName: "a.circle"), tint)
        case "rnb": return (tagString, Text("tag-rnb", bundle: .module, comment: "station tag name"), Image(systemName: "r.circle"), tint)
        case "juvenil": return (tagString, Text("tag-juvenil", bundle: .module, comment: "station tag name"), Image(systemName: "j.circle"), tint)
        case "grupera": return (tagString, Text("tag-grupera", bundle: .module, comment: "station tag name"), Image(systemName: "g.circle"), tint)
        case "trance": return (tagString, Text("tag-trance", bundle: .module, comment: "station tag name"), Image(systemName: "t.circle"), tint)
        case "rap": return (tagString, Text("tag-rap", bundle: .module, comment: "station tag name"), Image(systemName: "r.circle"), tint)
        case "latin music": return (tagString, Text("tag-latin-music", bundle: .module, comment: "station tag name"), Image(systemName: "l.circle"), tint)
        case "edm": return (tagString, Text("tag-edm", bundle: .module, comment: "station tag name"), Image(systemName: "e.circle"), tint)
        case "entertainment": return (tagString, Text("tag-entertainment", bundle: .module, comment: "station tag name"), Image(systemName: "e.circle"), tint)
        case "variety": return (tagString, Text("tag-variety", bundle: .module, comment: "station tag name"), Image(systemName: "v.circle"), tint)
        case "entretenimiento": return (tagString, Text("tag-entretenimiento", bundle: .module, comment: "station tag name"), Image(systemName: "e.circle"), tint)
        case "xp_5": return (tagString, Text("tag-xp_5", bundle: .module, comment: "station tag name"), Image(systemName: "u.circle"), tint)
        case "g_7": return (tagString, Text("tag-g_7", bundle: .module, comment: "station tag name"), Image(systemName: "g.circle"), tint)

        default: return nil
        }
    }

}

extension Station {
    var streamingURL: URL? {
        self.url.flatMap(URL.init(string:))
    }

    func iconView(size: CGFloat, blurFlag: CGFloat? = 1.5) -> some View {
        let url = URL(string: self.favicon ?? "about:blank") ?? URL(string: "about:blank")!
        return AsyncImage(url: url, content: { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
        }, placeholder: {
            ZStack {
                if let blurFlag = blurFlag {
                    // use a blurred color flag backdrop
                    let countryCode = self.countrycode?.isEmpty != false ? "UN" : (self.countrycode ?? "")
                    Text(emojiFlag(countryCode: countryCode))
                        .font(Font.system(size: size))
                        .frame(maxHeight: size)
                        .blur(radius: blurFlag)
                    //.clipShape(Capsule())
                }
            }
        })
        .frame(maxHeight: size)
    }
}

private extension String {
    /// Returns a pseudo-random value from 0.0-1.0 based on the word's SHA hash
    var hueComponent: CGFloat {
        let i: UInt8 = self.utf8Data.sha256().last ?? 0
        return CGFloat(i) / CGFloat(UInt8.max)
    }
}

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

    /// The stations frame sorted on the click trends
    static let trending: Result<DataFrame, Error> = {
        prf {
            Result { try stations.get().frame.sorted(on: Station.clicktrendColumn, order: .descending) }
        }
    }()

    static let stations: Result<StationCatalog, Error> = {
        //let _ = try! stationsPlist.get()
        return stationsCSV
    }()


    /// To fetch the latest catalog, run:
    ///
    /// `curl -fsSL https://nl1.api.radio-browser.info/csv/stations/search > Sources/App/Resources/stations.csv`
    private static let stationsCSV: Result<StationCatalog, Error> = {
        prf { // 1075ms
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
                    return StationCatalog(frame: df.sorted(on: Station.votesColumn, Station.clickcountColumn, order: .descending))
                } catch {
                    dbg("error loading from URL:", url, "error:", error)
                    throw error
                }
            }
        }
    }()

    /// To fetch the latest catalog in plist form, run (note that removing nulls is needed for plist encoding):
    ///
    /// `curl -fsSL https://nl1.api.radio-browser.info/json/stations/search | jq 'del(.[][] | nulls)' | plutil -convert binary1 -o Sources/App/Resources/stations.plist -`
    private static let stationsPlist: Result<Any, Error> = {
        // TODO: it is much faster parsing this from the binary format, but we would need to perform a lot of transformations to get the model lined up
        prf { // 264ms
            Result {
                guard let url = Bundle.module.url(forResource: "stations", withExtension: "plist") else {
                    throw CocoaError(.fileReadNoSuchFile)
                }

                let contents = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), options: [], format: nil)
                return contents
            }
        }
    }()


    /// To fetch the latest catalog, run:
    ///
    /// `curl -fsSL https://nl1.api.radio-browser.info/json/stations/search > Sources/App/Resources/stations.json`
    @available(*, deprecated, message: "too slow")
    private static let stationsJSON: Result<JSum, Error> = {
        prf { // 6872ms: too slow!
            Result {
                guard let url = Bundle.module.url(forResource: "stations", withExtension: "json") else {
                    throw CocoaError(.fileReadNoSuchFile)
                }

                let contents = try JSum.parse(json: Data(contentsOf: url))
                return contents
            }
        }
    }()


    static let countryCounts: Result<[ValueCount<String>], Error> = {
        Result { try stations.get().frame.valueCounts(column: Station.countrycodeColumn) }
    }()

    static let languageCounts: Result<[ValueCount<String>], Error> = {
        Result { try stations.get().frame.valueCounts(column: Station.languageColumn) }
    }()

    /// The counts of the raw comma-separated tags field
    static let rawTagsCounts: Result<[ValueCount<String>], Error> = {
        Result { try stations.get().frame.valueCounts(column: Station.tagsColumn) }
    }()

    /// The top 50 counts of the tags field after splitting them by commas
    static let tagsCounts: Result<[ValueCount<String>], Error> = {
        Result {
            // group by the set of comma-separated strings
            let tagGroups: RowGrouping<Set<String>> = try stations.get().frame.grouped(by: Station.tagsColumn) { tags in
                tags?.tagsSet ?? []
            }

            let tagGroupCounts = tagGroups.counts(order: nil)

            var tagCounts: [String: Int] = [:]
            for row in tagGroupCounts.rows {
                if let count = row["count"] as? Int {
                    if let tags = row[Station.tagsColumn.name] as? Set<String> { // need to duck the columns type, or else: “Could not cast value of type 'TabularData.Column<Swift.Set<Swift.String>>' (0x7fe7a3063d50) to 'TabularData.Column<Swift.String>' (0x7fe7a70226b0).”
                        for tag in tags {
                            tagCounts[tag] = count + tagCounts[tag, default: 0]
                        }
                    }
                }
            }

            return tagCounts.map {
                ValueCount(value: $0, count: $1)
            }
            .sorted(by: { $0.count > $1.count })
            .prefix(50)
            .filter { _ in true }
        }
    }()


    
}

extension String {
    var tagsSet: Set<String> {
        Set(self
                .split(separator: ",")
                .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines )})
                .filter({ !$0.isEmpty }))
    }
}

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
