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
import FairExpo
#if canImport(Combine)
import Combine
#endif

/// A structure representing an ``FairApp.AppCatalogItem`` with optional ``CaskItem`` metadata.
public struct AppInfo : Equatable {
    /// The underlying source for this info
    public var source: AppSource

    /// The catalog item metadata
    public var app: AppCatalogItem

    /// The associated homebrew cask
    public var cask: CaskItem?
}

/// API for managing a list of ``AppInfo`` instances from an ``AppSource`` catalog,
/// as well as installing, revealing, launching, and deleting an ``AppInfo``.
///
/// The location of installed apps will vary based on the ``AppManaement`` implementation,
///
/// This type is typically paired with an ``AppInventory`` implementation
/// to provide a complete app management engine.
public protocol AppManagement {
    /// Returns the installation path for the given item, possible querying the file system if needed
    func installedPath(for item: AppInfo) async throws -> URL?

    /// Installs the given item
    func install(_ item: AppInfo, progress parentProgress: Progress?, update: Bool, verbose: Bool) async throws

    /// Instructs the system to reveal the path of the item using the Finder
    func reveal(_ item: AppInfo) async throws

    /// Instructs the system to launch the item
    func launch(_ item: AppInfo) async throws

    /// Deletes the given item from the system
    func delete(_ item: AppInfo, verbose: Bool) async throws
}

/// The `AppInventory` protocol handles installing and managing apps.
///
/// This type is typically paired with an ``AppManagement`` implementation
/// to provide a complete app management engine.
public protocol AppInventory {
    /// The underlying source for this inventory
    var source: AppSource { get }

    /// The URL from with the primary catalog resource will be loaded.
    var sourceURL: URL { get }

    /// The title string, which is either contained in the underlying source, or else a fallback value
    var title: String { get }

    /// The date when the catalog was last updated
    var catalogUpdated: Date? { get }

    /// The badge indicating how many matches are available
    @MainActor func badgeCount(for section: SidebarSection) -> Text?

    /// Returns an unfiltered, unsorted list of all the apps in this catalog.
    func appList() async -> [AppInfo]?

    /// Refreshes the catalog(s) associated with this inventory.
    /// - Parameter reloadFromSource: whether to attempt to bypass any caching and reload directly from the source
    func refreshAll(reloadFromSource: Bool) async throws

    /// The app info items to be displayed for the given selection, filter, and sort order
    @MainActor func arrangedItems(sourceSelection: SourceSelection?, sortOrder: [KeyPathComparator<AppInfo>], searchText: String) -> [AppInfo]

    /// Returns the version string if the given inventory item is currently installed
    func appInstalled(_ item: AppInfo) -> String?

    /// Returns true if the given inventory item can be updated
    func appUpdated(_ item: AppInfo) -> Bool

    var updateInProgress: UInt { get }

    /// The number of available updated for this inventory
    func updateCount() -> Int

    /// Instructs the system to reveal the path of the item using the Finder
    func icon(for item: AppInfo) -> AppIconView

    /// Information on the metadata for the app source
    func sourceInfo(for section: SidebarSection) -> AppSourceInfo?

    /// The sidebar items supported by this inventory
    var supportedSidebars: [SidebarSection] { get }

    #if canImport(SwiftUI)
    func label(for source: AppSource) -> Label<Text, Image>
    #endif

    #if canImport(Combine)
    /// A publisher that is invoked whenever the object will change
    var objectWillChange: ObservableObjectPublisher { get }
    #endif
}

/// The external-facing icon view for this inventory.
public struct AppIconView : View {
    /// Wraps the internal views
    typealias ViewType = XOr<AppSourceInventory.IconView>.Or<HomebrewInventory.IconView>
    let content: ViewType

    public var body: some View {
        content
    }
}

extension AppInventory {
    static var defaultRecentInterval: TimeInterval { (60 * 60 * 24 * 30) }

    /// Returns true if the item was recently updated
    func isRecentlyUpdated(_ item: AppInfo, interval: TimeInterval = Self.defaultRecentInterval) -> Bool {
        (item.app.versionDate ?? .distantPast) > (Date() - interval)
    }
}

/// A type that is both an ``AppInventory`` and an ``AppManagement``
typealias AppInventoryManagement = AppInventory & AppManagement

/// A controller that handles multiple app inventory instances
protocol AppInventoryController : AppManagement {
    /// The list of available inventories
    @MainActor var inventories: [(AppInventoryManagement, AnyCancellable)] { get }

    /// Finds the inventory for the given identifier in this controller's list of sources
    @MainActor func inventory(from source: AppSource) -> AppInventoryManagement?
}

extension AppInventoryController {
    @MainActor var appInventories: [AppInventoryManagement] {
        inventories.map(\.0)
    }

    @MainActor var appSources: [AppSource] {
        appInventories.map(\.source)
    }

    @MainActor func inventory(from source: AppSource) -> AppInventoryManagement? {
        appInventories.first(where: { $0.source == source })
    }

    @MainActor func inventory(for appInfo: AppInfo) -> AppInventoryManagement? {
        inventory(from: appInfo.source)
        //appInfo.isCask ? homeBrewInv : fairAppInv
    }

    /// Returns the metadata for the given catalog
    @MainActor func sourceInfo(for selection: SourceSelection) -> AppSourceInfo? {
        inventory(for: selection.source)?.sourceInfo(for: selection.section)
    }

    @MainActor func inventory(for source: AppSource) -> AppInventory? {
        inventory(from: source)
    }

    /// The caskManager, which should be extracted as a separate `EnvironmentObject`
    ///
    /// -TODO: @available(*, deprecated, renamed: "inventory(from:)")
    @MainActor var homeBrewInv: HomebrewInventory? {
        inventory(from: .homebrew) as? HomebrewInventory
    }

    /// Returns a list of all the inventories that extend from `AppSourceInventory`
    @MainActor var appSourceInventories: [AppSourceInventory] {
        appInventories.compactMap({ $0 as? AppSourceInventory })
    }
}
