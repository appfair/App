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

    var ordering: SearchScope

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

