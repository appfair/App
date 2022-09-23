import FairApp
import GRDB
import GRDBQuery
import Combine


struct Place : Identifiable {
    var id: Int64

    var name, asciiname, alternatenames, latitude, longitude, featureclass, featurecode, countrycode, cc2, admincode1, admincode2, admincode3, admincode4, population, elevation, dem, timezone, modificationdate: String
}

public class PlacesManager : ObservableObject {
    /// To rebuild the database from the latest `geonames.org`, run:
    ///
    /// ```
    /// (echo 'id\tname\tasciiname\talternatenames\tlatitude\tlongitude\tfeatureclass\tfeaturecode\tcountrycode\tcc2\tadmincode1\tadmincode2\tadmincode3\tadmincode4\tpopulation\televation\tdem\ttimezone\tmodificationdate'; curl -fL https://download.geonames.org/export/dump/cities15000.zip | bsdtar -xOf -) | sed 's/,/;/g' | tr '\t' ',' | sqlite3 Sources/App/Resources/cities.db ".import --csv /dev/stdin cities"
    /// ```
}


public struct PlacesView : View {
    //@Query(PlacesRequest(ordering: .byPopulation)) var places: [Place]

    /// The `players` property is automatically updated when the database changes
    @Query(PlacesRequest(ordering: .byPopulation)) private var places: [Place]

    public var body: some View {
        VStack {
            List {
                ForEach(places) { place in
                    //TextField("Title", text: $place.title)
                    Text(place.name)
                }
//                .onMove { indexSet, offset in
//                    places.move(fromOffsets: indexSet, toOffset: offset)
//                }
//                .onDelete { indexSet in
//                    places.remove(atOffsets: indexSet)
//                }
            }
        }
        #if os(iOS)
        .toolbar { EditButton() }
        #endif
        .environment(\.appDatabase, .shared)
    }
}

/// A @Query request that observes the place (any place, actually) in the database
struct PlacesRequest: Queryable {
    enum Ordering {
        case byPopulation
        case byName
    }

    var ordering: Ordering

    static var defaultValue: [Place] { [] }

    func publisher(in appDatabase: AppDatabase) -> AnyPublisher<[Place], Error> {
        // Build the publisher from the general-purpose read-only access
        // granted by `appDatabase.databaseReader`.
        // Some apps will prefer to call a dedicated method of `appDatabase`.
        ValueObservation
            .tracking(fetchValue(_:))
            .publisher(
                in: appDatabase.databaseReader,
                // The `.immediate` scheduling feeds the view right on
                // subscription, and avoids an undesired animation when the
                // application starts.
                scheduling: .immediate)
            .eraseToAnyPublisher()
    }

    // This method is not required by Queryable, but it makes it easier
    // to test PlaceRequest.
    func fetchValue(_ db: Database) throws -> [Place] {
        switch ordering {
        case .byPopulation:
            return try Place.all().orderedByPopulation().fetchAll(db)
        case .byName:
            return try Place.all().orderedByName().fetchAll(db)
        }
    }
}

// MARK: - Give SwiftUI access to the database
//
// Define a new environment key that grants access to an AppDatabase.
//
// The technique is documented at
// <https://developer.apple.com/documentation/swiftui/environmentkey>.
private struct AppDatabaseKey: EnvironmentKey {
    static var defaultValue: AppDatabase { .shared }
}

extension EnvironmentValues {
    var appDatabase: AppDatabase {
        get { self[AppDatabaseKey.self] }
        set { self[AppDatabaseKey.self] = newValue }
    }
}

// In this demo app, views observe the database with the @Query property
// wrapper, defined in the GRDBQuery package. Its documentation recommends to
// define a dedicated initializer for `appDatabase` access, so we comply:
extension Query where Request.DatabaseContext == AppDatabase {
    /// Convenience initializer for requests that feed from `AppDatabase`.
    init(_ request: Request) {
        self.init(request, in: \.appDatabase)
    }
}


/// AppDatabase lets the application access the database.
///
/// It applies the pratices recommended at
/// <https://github.com/groue/GRDB.swift/blob/master/Documentation/GoodPracticesForDesigningRecordTypes.md>
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
    /// See <https://github.com/groue/GRDB.swift/blob/master/README.md#database-connections>
    private let dbWriter: any DatabaseWriter

    /// The DatabaseMigrator that defines the database schema.
    ///
    /// See <https://github.com/groue/GRDB.swift/blob/master/Documentation/Migrations.md>
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        #if DEBUG
        // Speed up development by nuking the database when migrations change
        // See https://github.com/groue/GRDB.swift/blob/master/Documentation/Migrations.md#the-erasedatabaseonschemachange-option
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

//        migrator.registerMigration("createPlace") { db in
//            // Create a table
//            // See https://github.com/groue/GRDB.swift#create-tables
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

    /// Saves (inserts or updates) a place. When the method returns, the
    /// place is present in the database, and its id is not nil.
    func savePlace(_ place: inout Place) async throws {
        if place.name.isEmpty {
            throw ValidationError.missingName
        }
        place = try await dbWriter.write { [place] db in
            try place.saved(db)
        }
    }

    /// Delete the specified places
    func deletePlaces(ids: [Int64]) async throws {
        try await dbWriter.write { db in
            _ = try Place.deleteAll(db, ids: ids)
        }
    }

    /// Delete all places
    func deleteAllPlaces() async throws {
        try await dbWriter.write { db in
            _ = try Place.deleteAll(db)
        }
    }

    /// Refresh all places (by performing some random changes, for demo purpose).
//    func refreshPlaces() async throws {
//        try await dbWriter.write { db in
//            if try Place.all().isEmpty(db) {
//                // When database is empty, insert new random places
//                try createRandomPlaces(db)
//            } else {
//                // Insert a place
//                if Bool.random() {
//                    _ = try Place.makeRandom().inserted(db) // insert but ignore inserted id
//                }
//
//                // Delete a random place
//                if Bool.random() {
//                    try Place.order(sql: "RANDOM()").limit(1).deleteAll(db)
//                }
//
//                // Update some places
//                for var place in try Place.fetchAll(db) where Bool.random() {
//                    try place.updateChanges(db) {
//                        $0.population = Place.randomPopulation()
//                    }
//                }
//            }
//        }
//    }

}

// MARK: - Database Access: Reads
// This demo app does not provide any specific reading method, and instead
// gives an unrestricted read-only access to the rest of the application.
// In your app, you are free to choose another path, and define focused
// reading methods.
extension AppDatabase {
    /// Provides a read-only access to the database
    var databaseReader: DatabaseReader {
        dbWriter
    }
}

// MARK: - Persistence
/// Make Place a Codable Record.
///
/// See <https://github.com/groue/GRDB.swift/blob/master/README.md#records>
extension Place: Codable, FetchableRecord, MutablePersistableRecord {
    // Define database columns from CodingKeys
    fileprivate enum Columns {
        static let name = Column(CodingKeys.name)
        static let population = Column(CodingKeys.population)
    }

    /// Updates a palce id after it has been inserted in the database.
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - Place Database Requests
/// Define some palce requests used by the application.
///
/// See <https://github.com/groue/GRDB.swift/blob/master/README.md#requests>
/// See <https://github.com/groue/GRDB.swift/blob/master/Documentation/GoodPracticesForDesigningRecordTypes.md>
extension DerivableRequest<Place> {
    /// A request of places ordered by name.
    ///
    /// For example:
    ///
    ///     let places: [Place] = try dbWriter.read { db in
    ///         try Place.all().orderedByName().fetchAll(db)
    ///     }
    func orderedByName() -> Self {
        // Sort by name in a localized case insensitive fashion
        // See https://github.com/groue/GRDB.swift/blob/master/README.md#string-comparison
        order(Place.Columns.name.collating(.localizedCaseInsensitiveCompare))
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
    func orderedByPopulation() -> Self {
        // Sort by descending population, and then by name, in a
        // localized case insensitive fashion
        // See https://github.com/groue/GRDB.swift/blob/master/README.md#string-comparison
        order(
            Place.Columns.population.desc,
            Place.Columns.name.collating(.localizedCaseInsensitiveCompare))
    }
}


extension AppDatabase {
    /// The database for the application
    static let shared = makeShared()

    private static func makeShared() -> AppDatabase {
        // to re-generate Sources/App/Resources/places.db :
        // rmbk Sources/App/Resources/places.db; (echo 'id,name,asciiname,alternatenames,latitude,longitude,featureclass,featurecode,countrycode,cc2,admincode1,admincode2,admincode3,admincode4,population,elevation,dem,timezone,modificationdate'; (curl -fL https://download.geonames.org/export/dump/cities15000.zip | bsdtar -xOf - | sed 's/,/;/g' | tr '\t' ',')) | sqlite3 Sources/App/Resources/places.db ".import --csv /dev/stdin place"
        let dbURL = Bundle.module.url(forResource: "places", withExtension: "db")!
        let dbPool = try! DatabasePool(path: dbURL.path)
        let appDatabase = try! AppDatabase(dbPool)
        return appDatabase
    }

    /// Creates an empty database for SwiftUI previews
    @available(*, deprecated)
    static func empty() -> AppDatabase {
        fatalError("empty should not be used")
        // Connect to an in-memory database
        // See https://github.com/groue/GRDB.swift/blob/master/README.md#database-connections
        let dbQueue = try! DatabaseQueue()
        return try! AppDatabase(dbQueue)
    }

}
