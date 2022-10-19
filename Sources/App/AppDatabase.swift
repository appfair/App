import FairApp
import SQLEnclave

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
