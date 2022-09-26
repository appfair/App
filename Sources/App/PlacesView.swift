import FairApp
import GRDB
import GRDBQuery
import Combine
import WeatherTiq
import LocationTiq
import GeoNamesCities15000

public struct Place : Identifiable {
    public var id: Int64

    // var name, asciiname, alternatenames, latitude, longitude, featureclass, featurecode, countrycode, cc2, admincode1, public admincode2, admincode3, admincode4, population, elevation, dem, timezone, modified: String

    public var name: String
    public var asciiname: String
    //var alternatenames: String // trimmed (reduces size by 40%)
    public var latitude: Double
    public var longitude: Double
    public var featureclass: String
    public var featurecode: String
    public var countrycode: String
    public var cc2: String
    public var admincode1: String
    public var admincode2: String
    public var admincode3: String
    public var admincode4: String
    public var population: Int
    public var elevation: Int
    public var dem: Int
    public var timezone: String
    public var modified: Date
}

extension Place {
    var coords: Coords {
        Coords(latitude: self.latitude, longitude: self.longitude)
    }
}

/// Make Place a Codable Record.
///
/// See <https://github.com/groue/GRDB.swift/blob/master/README.md#records>
extension Place : Codable, FetchableRecord, MutablePersistableRecord {
    // Define database columns from CodingKeys
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
//        static let asciiname = Column(CodingKeys.asciiname)
//        static let alternatenames = Column(CodingKeys.alternatenames) // excluded from database for 40% size savings
        static let latitude = Column(CodingKeys.latitude)
        static let longitude = Column(CodingKeys.longitude)
        static let featureclass = Column(CodingKeys.featureclass)
        static let featurecode = Column(CodingKeys.featurecode)
        static let countrycode = Column(CodingKeys.countrycode)
        static let cc2 = Column(CodingKeys.cc2)
        static let admincode1 = Column(CodingKeys.admincode1)
        static let admincode2 = Column(CodingKeys.admincode2)
        static let admincode3 = Column(CodingKeys.admincode3)
        static let admincode4 = Column(CodingKeys.admincode4)
        static let population = Column(CodingKeys.population)
        static let elevation = Column(CodingKeys.elevation)
        static let dem = Column(CodingKeys.dem)
        static let timezone = Column(CodingKeys.timezone)
        static let modified = Column(CodingKeys.modified)
    }

    /// Updates a palce id after it has been inserted in the database.
    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

public struct PlacesView : View {
    @Query(PlacesRequest(ordering: .byLongitude)) private var places: [Place]

    public var body: some View {
        NavigationView {
            List {
                ForEach(places) { place in
                    PlaceListItemView(place: place)
                }
            }
        }
        #if os(iOS)
        .toolbar { EditButton() }
        #endif
        .environment(\.appDatabase, .shared)
    }
}

struct PlaceListItemView : View {
    let place: Place

    @State private var weatherResult: Result<Weather, Error>? = .none

    var body: some View {
        //TextField("Title", text: $place.title)
        NavigationLink {
            switch weatherResult {
            case .success(let weather):
                WeatherSummaryView(weather: weather.currentWeather)
                    .navigationTitle(Text(place.name))
            case .failure(let error):
                Text("Error loading: \(place.name): \(error.localizedDescription)", bundle: .module, comment: "error message")
            case .none:
                Text("Loading: \(place.name)…", bundle: .module, comment: "loading")
            }
        } label: {
            HStack {
                Group {
                    if let weather = weatherResult?.successValue {
                        Image(systemName: weather.currentWeather.symbolName)
                            //.symbolVariant(.circle)
                            //.symbolRenderingMode(.multicolor) // clouds are white on white
                            //.symbolRenderingMode(.palette)
                            .foregroundStyle(Color.yellow, Color.cyan)
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                            .tint(.yellow) // matches the weather symbol multicolor tint
                    }
                }
                .frame(width: 25)

                VStack(alignment: .leading) {
                    HStack {
//                        Text(place.name) // TODO: localized place databases
                        //Text(place.admincode3)
                        //Text(place.admincode2)
//                        Text(place.admincode1)
//                        Text(place.countrycode)
                        //Text(place.population, format: .number)
                        Text(place.formattedAddress) // ?? Text("Unknown Location", bundle: .module, comment: "placeholder label for no address")
                    }
                    .lineLimit(1)
                    HStack {
                        let fmt = LocationCoordinateFormatter.degreesMinutesSecondsFormatter.string(from: place.coords.coordinate) ?? ""
                        Text(fmt)
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .lineLimit(1)
                }

                Spacer()

                switch weatherResult {
                case .success(let weather):
                    VStack(alignment: .trailing) {
                        Text(weather.currentWeather.temperature, format: .measurement(width: .narrow))
                            .font(.headline.monospacedDigit())
                            .lineLimit(1)
                        Text(weather.currentWeather.condition.localizedDescription)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                case .failure:
                    // TODO: if error is cancellation, don't show
                    EmptyView()
//                    FairSymbol.exclamationmark_octagon
//                        .help(Text("Error: \(error.localizedDescription)", bundle: .module, comment: "error tooltip prefix"))
//                        .symbolRenderingMode(.multicolor)
                case .none:
                    EmptyView()
                }
            }
        }
        .task(id: place.coords, priority: .userInitiated) {
            self.weatherResult = await Result {
                try await SunBowPod.service.weather(for: Location(latitude: place.coords.latitude, longitude: place.coords.longitude, altitude: .nan))
            }
        }
    }
}

/// A @Query request that observes the place (any place, actually) in the database
struct PlacesRequest: Queryable {
    static var defaultValue: [Place] { [] }

    var ordering: Ordering
    enum Ordering {
        case byPopulation
        case byLongitude
        case byName
    }

    func publisher(in appDatabase: AppDatabase) -> AnyPublisher<[Place], Error> {
        ValueObservation
            .tracking(fetchValue(_:))
            .publisher(in: appDatabase.databaseReader, scheduling: .immediate)
            .eraseToAnyPublisher()
    }

    // This method is not required by Queryable, but it makes it easier
    // to test PlaceRequest.
    func fetchValue(_ db: Database) throws -> [Place] {
        switch ordering {
        case .byLongitude:
            return try Place.all().orderedByLongitude().fetchAll(db)
        case .byPopulation:
            return try Place.all().orderedByPopulation().fetchAll(db)
        case .byName:
            return try Place.all().orderedByName().fetchAll(db)
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
// defined in the GRDBQuery package, which recommends to
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
        order(Place.Columns.population.desc)
    }

    func orderedByLongitude() -> Self {
        order(Place.Columns.longitude.asc)
    }
}

extension AppDatabase {
    /// The database for the application
    static let shared = createAppDatabase()

    private static func createAppDatabase() -> AppDatabase {
        Database.logError = { (resultCode, message) in
            dbg("database error \(resultCode): \(message)")
        }

        // run scripts/importcities.bash to re-generate Sources/App/Resources/places.db
        var config = Configuration()
        //config.label = "places.db"
        config.readonly = true

        config.prepareDatabase { db in
            db.trace(options: .profile) { event in
                dbg("sql:", event) // all SQL statements with their duration

                // Access to detailed profiling information
                if case let .profile(statement, duration) = event, duration > 0.5 {
                    dbg("slow query: \(statement.sql)")
                }
            }
        }

        let dbURL = GeoNamesCities15000.resourceURL

        return try! AppDatabase(DatabaseQueue(path: dump(dbURL.path), configuration: config))
        //return try! AppDatabase(DatabasePool(path: dbURL.path, configuration: config))
    }
}

/// Testing laziness
//public struct LazyThingView : View {
//    struct Thing : Identifiable {
//        var index: Int
//        var id: Int { dump(index, name: "id") }
//        var property: UUID { dump(UUID(), name: "property") }
//    }
//
//    struct ThingsCollection : RandomAccessCollection {
//        let startIndex = 0
//        let endIndex = 9_999
//        subscript(index: Int) -> Thing {
//            dump(Thing(index: index), name: "subscript")
//        }
//        func index(after i: Int) -> Int { i + 1 }
//    }
//
//    let things = ThingsCollection()
//
//    public var body: some View {
//        //bodyList
//        bodyLazyVStack
//    }
//
//    public var bodyLazyVStack: some View {
//        ScrollView {
//            LazyVStack {
//                ForEach(things) { thing in
//                    Text("Thing: \(thing.property)")
//                }
//            }
//        }
//    }
//
//    public var bodyList: some View {
//        List {
//            ForEach(things) { thing in
//                Text("Thing: \(thing.property)")
//            }
//        }
//    }
//
//}



import class Contacts.CNPostalAddressFormatter
import class Contacts.CNMutablePostalAddress

extension Place {
    var formattedAddress: String {
        let addr = CNMutablePostalAddress()
        addr.city = self.name
        addr.state = self.admincode1
        addr.subAdministrativeArea = self.admincode2
        addr.isoCountryCode = self.countrycode // doesn't seem to show up in the formatted address
        let str = CNPostalAddressFormatter.string(from: addr, style: .mailingAddress)
        return str.replacingOccurrences(of: "\n", with: ", ")
    }
}
