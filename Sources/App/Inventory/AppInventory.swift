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

/// The `AppCatalog` defined non-generic metadata for a catalog
protocol AppCatalog {
    @MainActor var catalogUpdated: Date? { get }
}

/// The `AppInventory` protocol handles installing and managing apps.
protocol AppInventory : AppCatalog {
    /// The inventory item associated with this inventory list
    associatedtype InventoryItem : Equatable

    /// Returns the version string if the given inventory item is currently installed
    @MainActor func appInstalled(item: InventoryItem) -> String?

    /// Returns true if the given inventory item can be updated
    @MainActor func appUpdated(item: InventoryItem) -> Bool

    /// Returns the installation path for the given item, possible querying the file system if needed
    @MainActor func installedPath(for item: InventoryItem) throws -> URL?

    /// Returns the installation path for the given item, possible querying the file system if needed
    @MainActor func launch(item: InventoryItem) async throws

    /// Installs the given item
    //@MainActor func install(item: InventoryItem, progress parentProgress: Progress?, update: Bool, verbose: Bool) async throws

    /// Instructs the system to reveal the path of the item using the Finder
    @MainActor func reveal(item: InventoryItem) async throws

    /// Deletes the given item from the system
    @MainActor func delete(item: InventoryItem, verbose: Bool) async throws

}

