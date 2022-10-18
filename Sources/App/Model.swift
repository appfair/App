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
    static func tagInfo(tagString: String) -> (key: String, title: String, image: Image, tint: Color)? {
        // check the top 100 tag list with:
        // cat Sources/App/Resources/stations.csv | tr '"' '\n' | grep ',' | tr ',' '\n' | tr '[A-Z]' '[a-z]' | grep '[a-z]' | sort | uniq -c | sort -nr | head -n 100

        let tint = Color(hue: tagString.hueComponent, saturation: 0.8, brightness: 0.8)

        switch tagString {
        case "60s": return (tagString, NSLocalizedString("tag-60s", bundle: .module, value: "60s", comment: "station tag name"), Image(systemName: "6.circle"), tint)
        case "70s": return (tagString, NSLocalizedString("tag-70s", bundle: .module, value: "70s", comment: "station tag name"), Image(systemName: "7.circle"), tint)
        case "80s": return (tagString, NSLocalizedString("tag-80s", bundle: .module, value: "80s", comment: "station tag name"), Image(systemName: "8.circle"), tint)
        case "90s": return (tagString, NSLocalizedString("tag-90s", bundle: .module, value: "90s", comment: "station tag name"), Image(systemName: "9.circle"), tint)

        case "pop": return (tagString, NSLocalizedString("tag-pop", bundle: .module, value: "Pop", comment: "station tag name"), Image(systemName: "sparkles"), tint)
        case "news": return (tagString, NSLocalizedString("tag-news", bundle: .module, value: "News", comment: "station tag name"), Image(systemName: "newspaper"), tint)

        case "rock": return (tagString, NSLocalizedString("tag-rock", bundle: .module, value: "Rock", comment: "station tag name"), Image(systemName: "guitars"), tint)
        case "classic rock": return (tagString, NSLocalizedString("tag-classic-rock", bundle: .module, value: "Classic Rock", comment: "station tag name"), Image(systemName: "guitars"), tint)
        case "pop rock": return (tagString, NSLocalizedString("tag-pop-rock", bundle: .module, value: "Pop Rock", comment: "station tag name"), Image(systemName: "guitars"), tint)

        case "metal": return (tagString, NSLocalizedString("tag-metal", bundle: .module, value: "Metal", comment: "station tag name"), Image(systemName: "amplifier"), tint)
        case "hard rock": return (tagString, NSLocalizedString("tag-hard-rock", bundle: .module, value: "Hard Rock", comment: "station tag name"), Image(systemName: "amplifier"), tint)

        case "npr": return (tagString, NSLocalizedString("tag-npr", bundle: .module, value: "NPR", comment: "station tag name"), Image(systemName: "building.columns"), tint)
        case "public radio": return (tagString, NSLocalizedString("tag-public-radio", bundle: .module, value: "Public Radio", comment: "station tag name"), Image(systemName: "building.columns"), tint)
        case "community radio": return (tagString, NSLocalizedString("tag-community-radio", bundle: .module, value: "Community Radio", comment: "station tag name"), Image(systemName: "building.columns"), tint)

        case "classical": return (tagString, NSLocalizedString("tag-classical", bundle: .module, value: "Classical", comment: "station tag name"), Image(systemName: "theatermasks"), tint)

        case "music": return (tagString, NSLocalizedString("tag-music", bundle: .module, value: "Music", comment: "station tag name"), Image(systemName: "music.note"), tint)
        case "talk": return (tagString, NSLocalizedString("tag-talk", bundle: .module, value: "Talk", comment: "station tag name"), Image(systemName: "mic.square"), tint)
        case "dance": return (tagString, NSLocalizedString("tag-dance", bundle: .module, value: "Dance", comment: "station tag name"), Image(systemName: "figure.walk"), tint)
        case "spanish": return (tagString, NSLocalizedString("tag-spanish", bundle: .module, value: "Spanish", comment: "station tag name"), Image(systemName: "globe.europe.africa"), tint)
        case "top 40": return (tagString, NSLocalizedString("tag-top-40", bundle: .module, value: "Top 40", comment: "station tag name"), Image(systemName: "chart.bar"), tint)
        case "greek": return (tagString, NSLocalizedString("tag-greek", bundle: .module, value: "Greek", comment: "station tag name"), Image(systemName: "globe.europe.africa"), tint)
        case "radio": return (tagString, NSLocalizedString("tag-radio", bundle: .module, value: "Radio", comment: "station tag name"), Image(systemName: "radio"), tint)
        case "oldies": return (tagString, NSLocalizedString("tag-oldies", bundle: .module, value: "Oldies", comment: "station tag name"), Image(systemName: "tortoise"), tint)
        case "fm": return (tagString, NSLocalizedString("tag-fm", bundle: .module, value: "FM", comment: "station tag name"), Image(systemName: "antenna.radiowaves.left.and.right"), tint)
        case "méxico": return (tagString, NSLocalizedString("tag-méxico", bundle: .module, value: "México", comment: "station tag name"), Image(systemName: "globe.americas"), tint)
        case "christian": return (tagString, NSLocalizedString("tag-christian", bundle: .module, value: "Christian", comment: "station tag name"), Image(systemName: "cross"), tint)
        case "hits": return (tagString, NSLocalizedString("tag-hits", bundle: .module, value: "Hits", comment: "station tag name"), Image(systemName: "sparkle"), tint)
        case "mexico": return (tagString, NSLocalizedString("tag-mexico", bundle: .module, value: "Mexico", comment: "station tag name"), Image(systemName: "globe.americas"), tint)
        case "local news": return (tagString, NSLocalizedString("tag-local-news", bundle: .module, value: "Local News", comment: "station tag name"), Image(systemName: "newspaper"), tint)
        case "german": return (tagString, NSLocalizedString("tag-german", bundle: .module, value: "German", comment: "station tag name"), Image(systemName: "globe.europe.africa"), tint)
        case "deutsch": return (tagString, NSLocalizedString("tag-deutsch", bundle: .module, value: "Deutsch", comment: "station tag name"), Image(systemName: "globe.europe.africa"), tint)
        case "university radio": return (tagString, NSLocalizedString("tag-university-radio", bundle: .module, value: "University Radio", comment: "station tag name"), Image(systemName: "graduationcap"), tint)
        case "chillout": return (tagString, NSLocalizedString("tag-chillout", bundle: .module, value: "Chillout", comment: "station tag name"), Image(systemName: "snowflake"), tint)
        case "ambient": return (tagString, NSLocalizedString("tag-ambient", bundle: .module, value: "Ambient", comment: "station tag name"), Image(systemName: "headphones"), tint)
        case "world music": return (tagString, NSLocalizedString("tag-world-music", bundle: .module, value: "World Music", comment: "station tag name"), Image(systemName: "globe"), tint)
        case "french": return (tagString, NSLocalizedString("tag-french", bundle: .module, value: "French", comment: "station tag name"), Image(systemName: "globe.europe.africa"), tint)
        case "local music": return (tagString, NSLocalizedString("tag-local-music", bundle: .module, value: "Local Music", comment: "station tag name"), Image(systemName: "flag"), tint)
        case "disco": return (tagString, NSLocalizedString("tag-disco", bundle: .module, value: "Disco", comment: "station tag name"), Image(systemName: "dot.arrowtriangles.up.right.down.left.circle"), tint)
        case "regional mexican": return (tagString, NSLocalizedString("tag-regional-mexican", bundle: .module, value: "Regional Mexican", comment: "station tag name"), Image(systemName: "globe.americas"), tint)
        case "electro": return (tagString, NSLocalizedString("tag-electro", bundle: .module, value: "Electro", comment: "station tag name"), Image(systemName: "cable.connector.horizontal"), tint)
        case "talk & speech": return (tagString, NSLocalizedString("tag-talk-&-speech", bundle: .module, value: "Talk & Speech", comment: "station tag name"), Image(systemName: "text.bubble"), tint)
        case "college radio": return (tagString, NSLocalizedString("tag-college-radio", bundle: .module, value: "College Radio", comment: "station tag name"), Image(systemName: "graduationcap"), tint)
        case "catholic": return (tagString, NSLocalizedString("tag-catholic", bundle: .module, value: "Catholic", comment: "station tag name"), Image(systemName: "cross"), tint)
        case "regional radio": return (tagString, NSLocalizedString("tag-regional-radio", bundle: .module, value: "Regional Radio", comment: "station tag name"), Image(systemName: "flag"), tint)
        case "musica regional mexicana": return (tagString, NSLocalizedString("tag-musica-regional-mexicana", bundle: .module, value: "Musica Regional Mexicana", comment: "station tag name"), Image(systemName: "m.circle"), tint)
        case "charts": return (tagString, NSLocalizedString("tag-charts", bundle: .module, value: "Charts", comment: "station tag name"), Image(systemName: "chart.bar"), tint)
        case "regional": return (tagString, NSLocalizedString("tag-regional", bundle: .module, value: "Regional", comment: "station tag name"), Image(systemName: "flag"), tint)
        case "russian": return (tagString, NSLocalizedString("tag-russian", bundle: .module, value: "Russian", comment: "station tag name"), Image(systemName: "globe.asia.australia"), tint)
        case "musica regional": return (tagString, NSLocalizedString("tag-musica-regional", bundle: .module, value: "Musica Regional", comment: "station tag name"), Image(systemName: "flag"), tint)

        case "religion": return (tagString, NSLocalizedString("tag-religion", bundle: .module, value: "Religion", comment: "station tag name"), Image(systemName: "staroflife"), tint)
        case "pop music": return (tagString, NSLocalizedString("tag-pop-music", bundle: .module, value: "Pop Music", comment: "station tag name"), Image(systemName: "person.3"), tint)
        case "easy listening": return (tagString, NSLocalizedString("tag-easy-listening", bundle: .module, value: "Easy Listening", comment: "station tag name"), Image(systemName: "dial.min"), tint)
        case "culture": return (tagString, NSLocalizedString("tag-culture", bundle: .module, value: "Culture", comment: "station tag name"), Image(systemName: "metronome"), tint)
        case "mainstream": return (tagString, NSLocalizedString("tag-mainstream", bundle: .module, value: "Mainstream", comment: "station tag name"), Image(systemName: "gauge"), tint)
        case "news talk": return (tagString, NSLocalizedString("tag-news-talk", bundle: .module, value: "News Talk", comment: "station tag name"), Image(systemName: "captions.bubble"), tint)
        case "commercial": return (tagString, NSLocalizedString("tag-commercial", bundle: .module, value: "Commercial", comment: "station tag name"), Image(systemName: "coloncurrencysign.circle"), tint)
        case "folk": return (tagString, NSLocalizedString("tag-folk", bundle: .module, value: "Folk", comment: "station tag name"), Image(systemName: "tuningfork"), tint)

        case "sport": return (tagString, NSLocalizedString("tag-sport", bundle: .module, value: "Sport", comment: "station tag name"), Image(systemName: "figure.walk.diamond"), tint)
        case "jazz": return (tagString, NSLocalizedString("tag-jazz", bundle: .module, value: "Jazz", comment: "station tag name"), Image(systemName: "ear"), tint)
        case "country": return (tagString, NSLocalizedString("tag-country", bundle: .module, value: "Country", comment: "station tag name"), Image(systemName: "photo"), tint)
        case "house": return (tagString, NSLocalizedString("tag-house", bundle: .module, value: "House", comment: "station tag name"), Image(systemName: "house"), tint)
        case "soul": return (tagString, NSLocalizedString("tag-soul", bundle: .module, value: "Soul", comment: "station tag name"), Image(systemName: "suit.heart"), tint)
        case "reggae": return (tagString, NSLocalizedString("tag-reggae", bundle: .module, value: "Reggae", comment: "station tag name"), Image(systemName: "smoke"), tint)

            // default (letter) icons
        case "classic hits": return (tagString, NSLocalizedString("tag-classic-hits", bundle: .module, value: "Classic Hits", comment: "station tag name"), Image(systemName: "c.circle"), tint)
        case "electronic": return (tagString, NSLocalizedString("tag-electronic", bundle: .module, value: "Electronic", comment: "station tag name"), Image(systemName: "e.circle"), tint)
        case "funk": return (tagString, NSLocalizedString("tag-funk", bundle: .module, value: "Funk", comment: "station tag name"), Image(systemName: "f.circle"), tint)
        case "blues": return (tagString, NSLocalizedString("tag-blues", bundle: .module, value: "Blues", comment: "station tag name"), Image(systemName: "b.circle"), tint)

        case "english": return (tagString, NSLocalizedString("tag-english", bundle: .module, value: "English", comment: "station tag name"), Image(systemName: "e.circle"), tint)
        case "español": return (tagString, NSLocalizedString("tag-español", bundle: .module, value: "Español", comment: "station tag name"), Image(systemName: "e.circle"), tint)
        case "estación": return (tagString, NSLocalizedString("tag-estación", bundle: .module, value: "Estación", comment: "station tag name"), Image(systemName: "e.circle"), tint)
        case "mex": return (tagString, NSLocalizedString("tag-mex", bundle: .module, value: "Mex", comment: "station tag name"), Image(systemName: "m.circle"), tint)
        case "mx": return (tagString, NSLocalizedString("tag-mx", bundle: .module, value: "Mx", comment: "station tag name"), Image(systemName: "m.circle"), tint)
        case "adult contemporary": return (tagString, NSLocalizedString("tag-adult-contemporary", bundle: .module, value: "Adult Contemporary", comment: "station tag name"), Image(systemName: "a.circle"), tint)
        case "alternative": return (tagString, NSLocalizedString("tag-alternative", bundle: .module, value: "Alternative", comment: "station tag name"), Image(systemName: "a.circle"), tint)
        case "música": return (tagString, NSLocalizedString("tag-música", bundle: .module, value: "Música", comment: "station tag name"), Image(systemName: "m.circle"), tint)
        case "hiphop": return (tagString, NSLocalizedString("tag-hiphop", bundle: .module, value: "Hiphop", comment: "station tag name"), Image(systemName: "h.circle"), tint)
        case "musica": return (tagString, NSLocalizedString("tag-musica", bundle: .module, value: "Musica", comment: "station tag name"), Image(systemName: "m.circle"), tint)
        case "s": return (tagString, NSLocalizedString("tag-s", bundle: .module, value: "S", comment: "station tag name"), Image(systemName: "s.circle"), tint)
        case "indie": return (tagString, NSLocalizedString("tag-indie", bundle: .module, value: "Indie", comment: "station tag name"), Image(systemName: "i.circle"), tint)
        case "information": return (tagString, NSLocalizedString("tag-information", bundle: .module, value: "Information", comment: "station tag name"), Image(systemName: "i.circle"), tint)
        case "techno": return (tagString, NSLocalizedString("tag-techno", bundle: .module, value: "Techno", comment: "station tag name"), Image(systemName: "t.circle"), tint)
        case "noticias": return (tagString, NSLocalizedString("tag-noticias", bundle: .module, value: "Noticias", comment: "station tag name"), Image(systemName: "n.circle"), tint)
        case "música pop": return (tagString, NSLocalizedString("tag-música-pop", bundle: .module, value: "Música Pop", comment: "station tag name"), Image(systemName: "m.circle"), tint)
        case "lounge": return (tagString, NSLocalizedString("tag-lounge", bundle: .module, value: "Lounge", comment: "station tag name"), Image(systemName: "l.circle"), tint)
        case "alternative rock": return (tagString, NSLocalizedString("tag-alternative-rock", bundle: .module, value: "Alternative Rock", comment: "station tag name"), Image(systemName: "a.circle"), tint)
        case "on": return (tagString, NSLocalizedString("tag-on", bundle: .module, value: "On", comment: "station tag name"), Image(systemName: "o.circle"), tint)
        case "aac": return (tagString, NSLocalizedString("tag-aac", bundle: .module, value: "AAC", comment: "station tag name"), Image(systemName: "a.circle"), tint)
        case "rnb": return (tagString, NSLocalizedString("tag-rnb", bundle: .module, value: "RNB", comment: "station tag name"), Image(systemName: "r.circle"), tint)
        case "juvenil": return (tagString, NSLocalizedString("tag-juvenil", bundle: .module, value: "Juvenil", comment: "station tag name"), Image(systemName: "j.circle"), tint)
        case "grupera": return (tagString, NSLocalizedString("tag-grupera", bundle: .module, value: "Grupera", comment: "station tag name"), Image(systemName: "g.circle"), tint)
        case "trance": return (tagString, NSLocalizedString("tag-trance", bundle: .module, value: "Trance", comment: "station tag name"), Image(systemName: "t.circle"), tint)
        case "rap": return (tagString, NSLocalizedString("tag-rap", bundle: .module, value: "Rap", comment: "station tag name"), Image(systemName: "r.circle"), tint)
        case "latin music": return (tagString, NSLocalizedString("tag-latin-music", bundle: .module, value: "Latin Music", comment: "station tag name"), Image(systemName: "l.circle"), tint)
        case "edm": return (tagString, NSLocalizedString("tag-edm", bundle: .module, value: "EDM", comment: "station tag name"), Image(systemName: "e.circle"), tint)
        case "entertainment": return (tagString, NSLocalizedString("tag-entertainment", bundle: .module, value: "Entertainment", comment: "station tag name"), Image(systemName: "e.circle"), tint)
        case "variety": return (tagString, NSLocalizedString("tag-variety", bundle: .module, value: "Variety", comment: "station tag name"), Image(systemName: "v.circle"), tint)
        case "entretenimiento": return (tagString, NSLocalizedString("tag-entretenimiento", bundle: .module, value: "Entretenimiento", comment: "station tag name"), Image(systemName: "e.circle"), tint)
        case "xp_5": return (tagString, NSLocalizedString("tag-xp_5", bundle: .module, value: "XP_5", comment: "station tag name"), Image(systemName: "u.circle"), tint)
        case "g_7": return (tagString, NSLocalizedString("tag-g_7", bundle: .module, value: "G_7", comment: "station tag name"), Image(systemName: "g.circle"), tint)

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
