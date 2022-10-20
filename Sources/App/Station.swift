import Foundation
import FairApp
import Combine
import SQLEnclave

public struct Station : Hashable {
    public typealias URLString = String
    public typealias UUIDString = String

    public typealias DateString = String

    public var changeuuid: UUIDString?
    public var stationuuid: UUIDString?
    public var name: String?
    public var url: URLString?
    public var url_resolved: URLString?
    public var homepage: URLString?
    public var favicon: URLString?
    public var tags: String?
    public var country: String?
    public var countrycode: String?
    public var iso_3166_2: String?
    public var state: String?
    public var language: String?
    public var languagecodes: String?
    public var votes: Int?
    public var lastchangetime: DateString?
    public var lastchangetime_iso8601: DateString?
    public var codec: String? // e.g., "MP3" or "AAC,H.264"
    public var bitrate: Double?
    public var hls: String?
    public var lastcheckok: Int?
    //var lastchecktime: OldDateString?
    public var lastchecktime_iso8601: DateString?
    //var lastcheckoktime: OldDateString?
    public var lastcheckoktime_iso8601: DateString?
    //var lastlocalchecktime: OldDateString?
    public var lastlocalchecktime_iso8601: DateString?
    //var clicktimestamp: OldDateString?
    public var clicktimestamp_iso8601: DateString?
    public var clickcount: Int?
    public var clicktrend: Int?
    public var ssl_error: String?
    public var geo_lat: Double?
    public var geo_long: Double?
    public var has_extended_info: Bool?
}

extension Station : Identifiable {
    /// The identifier of the station
    public var id: UUID? {
        stationuuid.flatMap(UUID.init(uuidString:))
    }
}

extension Station : Codable, FetchableRecord, MutablePersistableRecord {
    // Define database columns from CodingKeys
    enum Columns {
        static let id = Column(CodingKeys.stationuuid)
        static let name = Column(CodingKeys.name)
        static let countrycode = Column(CodingKeys.countrycode)
        static let language = Column(CodingKeys.language)
        static let homepage = Column(CodingKeys.homepage)
        static let tags = Column(CodingKeys.tags)
        static let clickcount = Column(CodingKeys.clickcount)
        static let clicktrend = Column(CodingKeys.clicktrend)
        static let url = Column(CodingKeys.url)
        static let favicon = Column(CodingKeys.favicon)
        static let languagecodes = Column(CodingKeys.languagecodes)
        static let votes = Column(CodingKeys.votes)
    }
}

/// A @Query request that observes the results.
struct StationsRequest: Queryable {
    static var defaultValue: [Station] { [] }

    var ordering: SearchSort

    func publisher(in appDatabase: AppDatabase) -> AnyPublisher<[Station], Error> {
        ValueObservation
            .tracking(fetchValue(_:))
            .publisher(in: appDatabase.databaseReader, scheduling: .immediate)
            .eraseToAnyPublisher()
    }

    // This method is not required by Queryable, but it makes it easier
    // to test StationRequest.
    func fetchValue(_ db: Database) throws -> [Station] {
        switch ordering {
        case .byClickCount:
            return try Station.all().order(Station.Columns.clickcount.desc).fetchAll(db)
        case .byClickTrend:
            return try Station.all().order(Station.Columns.clicktrend.desc).fetchAll(db)
        case .byName:
            return try Station.all().orderedByName().fetchAll(db)
        }
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

private extension String {
    /// Returns a pseudo-random value from 0.0-1.0 based on the word's SHA hash
    var hueComponent: CGFloat {
        let i: UInt8 = self.utf8Data.sha256().last ?? 0
        return CGFloat(i) / CGFloat(UInt8.max)
    }
}


extension Station {
    var streamingURL: URL? {
        self.url.flatMap(URL.init(string:))
    }

    @ViewBuilder func iconView(download: Bool, size: CGFloat, blurFlag: CGFloat? = 0.0) -> some View {
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
