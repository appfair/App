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

/// A @Query request that observes the place (any place, actually) in the database
struct StationsRequest: Queryable {
    static var defaultValue: [Station] { [] }

    var ordering: Ordering
    enum Ordering {
//        case byPopulation
        case byClickTrend
        case byName
    }

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
//        case .byLongitude:
//            return try Station.all().orderedByLongitude().fetchAll(db)
        case .byClickTrend:
            return try Station.all().order(Station.Columns.clicktrend.desc).fetchAll(db)
        case .byName:
            return try Station.all().orderedByName().fetchAll(db)
        }
    }
}

// MARK: - Give SwiftUI access to the database


// Define a new environment key that grants access to an AppDatabase.
private struct AppDatabaseKey: EnvironmentKey {
    static var defaultValue: AppDatabase { .shared }
}

extension EnvironmentValues {
    var appDatabase: AppDatabase {
        get { self[AppDatabaseKey.self] }
        set { self[AppDatabaseKey.self] = newValue }
    }
}

// Views observe the database with the @Query property wrapper,
// defined in the TiqDB package, which recommends to
// define a dedicated initializer for `appDatabase` access
extension Query where Request.DatabaseContext == AppDatabase {
    /// Convenience initializer for requests that feed from `AppDatabase`.
    init(_ request: Request) {
        self.init(request, in: \.appDatabase)
    }
}


/// AppDatabase lets the application access the database.
///
/// It applies the pratices recommended at
/// <https://github.com/SQLEnclave/SQLEnclave/blob/master/Documentation/GoodPracticesForDesigningRecordTypes.md>
struct AppDatabase {
    /// Creates an `AppDatabase`, and make sure the database schema is ready.
    init(_ dbWriter: any DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }

    /// Provides access to the database.
    ///
    /// Application can use a `DatabasePool`, while SwiftUI previews and tests
    /// can use a fast in-memory `DatabaseQueue`.
    ///
    /// See <https://github.com/SQLEnclave/SQLEnclave/blob/master/README.md#database-connections>
    private let dbWriter: any DatabaseWriter

    /// The DatabaseMigrator that defines the database schema.
    ///
    /// See <https://github.com/SQLEnclave/SQLEnclave/blob/master/Documentation/Migrations.md>
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        #if DEBUG
        // Speed up development by nuking the database when migrations change
        // See https://github.com/SQLEnclave/SQLEnclave/blob/master/Documentation/Migrations.md#the-erasedatabaseonschemachange-option
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

//        migrator.registerMigration("createPlace") { db in
//            // Create a table
//            // See https://github.com/SQLEnclave/SQLEnclave#create-tables
//            try db.create(table: "place") { t in
//                t.autoIncrementedPrimaryKey("id")
//            }
//        }

        // Migrations for future application versions will be inserted here:
        // migrator.registerMigration(...) { db in
        //     ...
        // }

        return migrator
    }
}

// MARK: - Database Access: Writes
extension AppDatabase {
    /// A validation error that prevents some places from being saved into
    /// the database.
    enum ValidationError: LocalizedError {
        case missingName

        var errorDescription: String? {
            switch self {
            case .missingName:
                return "Please provide a name"
            }
        }
    }

//    /// Saves (inserts or updates) a place. When the method returns, the
//    /// place is present in the database, and its id is not nil.
//    func savePlace(_ place: inout Place) async throws {
//        if place.name.isEmpty {
//            throw ValidationError.missingName
//        }
//        place = try await dbWriter.write { [place] db in
//            try place.saved(db)
//        }
//    }
//
//    /// Delete the specified places
//    func deletePlaces(ids: [Int64]) async throws {
//        try await dbWriter.write { db in
//            _ = try Place.deleteAll(db, ids: ids)
//        }
//    }
//
//    /// Delete all places
//    func deleteAllPlaces() async throws {
//        try await dbWriter.write { db in
//            _ = try Place.deleteAll(db)
//        }
//    }
}

// MARK: - Database Access: Reads

// This app does not provide any specific reading method, and instead
// gives an unrestricted read-only access to the rest of the application.
// In your app, you are free to choose another path, and define focused
// reading methods.
extension AppDatabase {
    /// Provides a read-only access to the database
    var databaseReader: DatabaseReader {
        dbWriter
    }
}

// MARK: - Place Database Requests
/// Define some palce requests used by the application.
///
/// See <https://github.com/SQLEnclave/SQLEnclave/blob/master/README.md#requests>
/// See <https://github.com/SQLEnclave/SQLEnclave/blob/master/Documentation/GoodPracticesForDesigningRecordTypes.md>
extension DerivableRequest {
    /// A request of places ordered by name.
    ///
    /// For example:
    ///
    ///     let places: [Place] = try dbWriter.read { db in
    ///         try Place.all().orderedByName().fetchAll(db)
    ///     }
    func orderedByName() -> Self {
        // Sort by name in a localized case insensitive fashion
        // See https://github.com/SQLEnclave/SQLEnclave/master/README.md#string-comparison
        order(Station.Columns.name.collating(.localizedCaseInsensitiveCompare))
    }

    /// A request of places ordered by population.
    ///
    /// For example:
    ///
    ///     let places: [Place] = try dbWriter.read { db in
    ///         try Place.all().orderedByPopulation().fetchAll(db)
    ///     }
    ///     let bestPlace: Place? = try dbWriter.read { db in
    ///         try Place.all().orderedByPopulation().fetchOne(db)
    ///     }
//    func orderedByPopulation() -> Self {
//        order(Station.Columns.population.desc)
//    }
//
//    func orderedByLongitude() -> Self {
//        order(Station.Columns.longitude.asc)
//    }
}

extension AppDatabase {
    /// The database for the application
    static let shared = try! createAppDatabase(url: Bundle.module.url(forResource: "stations", withExtension: "db")!)!

    private static func createAppDatabase(url dbURL: URL) throws -> AppDatabase? {
        Database.logError = { (resultCode, message) in
            dbg("database error \(resultCode): \(message)")
            
        }

        // run scripts/importcities.bash to re-generate Sources/App/Resources/places.db
        var config = Configuration()
        //config.label = "places.db"
        config.readonly = true

        #if DEBUG
        config.prepareDatabase { db in
            db.trace(options: .profile) { event in
                dbg("sql:", event) // all SQL statements with their duration

                // Access to detailed profiling information
                if case let .profile(statement, duration) = event, duration > 0.5 {
                    dbg("slow query: \(statement.sql)")
                }
            }
        }
        #endif

        return try AppDatabase(DatabaseQueue(path: dbURL.path, configuration: config))
    }
}
