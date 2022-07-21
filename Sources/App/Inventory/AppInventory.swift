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
import FairKit

import Combine

/// The `AppInventory` protocol handles installing and managing apps.
protocol AppInventory : AnyObject {
    /// The underlying source for this inventory
    var source: AppSource { get }

    /// The title string, which is either contained in the underlying source, or else a fallback value
    @MainActor var title: String { get }

    /// The URL from with the primary catalog resource will be loaded.
    @MainActor var sourceURL: URL { get }

    /// The date when the catalog was last updated
    @MainActor var catalogUpdated: Date? { get }

    /// The badge indicating how many matches are available
    @MainActor func badgeCount(for section: SidebarSection) -> Text?

    /// The app info items to be displayed for the given selection, filter, and sort order
    @MainActor func arrangedItems(sidebarSelection: SourceSelection?, sortOrder: [KeyPathComparator<AppInfo>], searchText: String) -> [AppInfo]

    /// Returns the version string if the given inventory item is currently installed
    @MainActor func appInstalled(_ item: AppInfo) -> String?

    /// Returns true if the given inventory item can be updated
    @MainActor func appUpdated(_ item: AppInfo) -> Bool

    /// Returns the installation path for the given item, possible querying the file system if needed
    @MainActor func installedPath(for item: AppInfo) throws -> URL?

    /// Returns the installation path for the given item, possible querying the file system if needed
    @MainActor func launch(_ item: AppInfo) async throws

    /// Installs the given item
    @MainActor func install(_ item: AppInfo, progress parentProgress: Progress?, update: Bool, verbose: Bool) async throws

    /// Instructs the system to reveal the path of the item using the Finder
    @MainActor func reveal(_ item: AppInfo) async throws

    /// Deletes the given item from the system
    @MainActor func delete(_ item: AppInfo, verbose: Bool) async throws

    @MainActor var updateInProgress: UInt { get }

    @MainActor func label(for source: AppSource) -> Label<Text, Image>

    @MainActor func refreshAll(reloadFromSource: Bool) async throws

    /// The number of available updated for this inventory
    @MainActor func updateCount() -> Int

    /// Instructs the system to reveal the path of the item using the Finder
    @MainActor func icon(for item: AppInfo) -> AppIconView

    /// Information on the metadata for the app source
    @MainActor func sourceInfo(for section: SidebarSection) -> AppSourceInfo?

    /// The sidebar items supported by this inventory
    @MainActor var supportedSidebars: [SidebarSection] { get }

    /// A publisher that is invoked whenever the object will change
    var objectWillChange: ObservableObjectPublisher { get }
}

typealias AppIconView = XOr<AppSourceInventory.IconView>.Or<HomebrewInventory.IconView>

extension AppInventory {
    static var defaultRecentInterval: TimeInterval { (60 * 60 * 24 * 30) }

    /// Returns true if the item was recently updated
    func isRecentlyUpdated(_ item: AppInfo, interval: TimeInterval = Self.defaultRecentInterval) -> Bool {
        (item.app.versionDate ?? .distantPast) > (Date() - interval)
    }
}

