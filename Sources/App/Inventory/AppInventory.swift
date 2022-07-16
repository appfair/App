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
protocol AppInventoryCatalog {
    @MainActor var catalogUpdated: Date? { get }
}

/// The `AppInventory` protocol handles installing and managing apps.
protocol AppInventory : AppInventoryCatalog {
    /// The inventory item associated with this inventory list
    associatedtype InventoryItem

    associatedtype SourceInfo

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

    //@MainActor var imageCache: Cache<URL, Image> { get }
}

extension AppInventory {
    static var defaultRecentInterval: TimeInterval { (60 * 60 * 24 * 30) }

    /// Returns true if the item was recently updated
    func isRecentlyUpdated(item: AppCatalogItem, interval: TimeInterval = Self.defaultRecentInterval) -> Bool {
        (item.versionDate ?? .distantPast) > (Date() - interval)
    }

    /// Cache the given image parameter for later re-use
    @MainActor private func caching(image: Image, for url: URL?) -> Image {
//        if let url = url {
//            imageCache[url] = image
//            dbg("cached image:", url.absoluteString)
//        }
        return image
    }

    @MainActor func iconImage(item: AppCatalogItem) -> some View {
        @MainActor func imageContent(phase: AsyncImagePhase) -> some View {
            Group {
                switch phase {
                case .success(let image):
                    //let _ = iconCache.setObject(ImageInfo(image: image), forKey: iconURL as NSURL)
                    //let _ = dbg("success image for:", self.name, image)
                    let img = image
                        .resizable()
                    caching(image: img, for: item.iconURL)
                case .failure(let error):
                    let _ = dbg("error image for:", item.name, error)
                    if !error.isURLCancelledError { // happens when items are scrolled off the screen
                        let _ = dbg("error fetching icon from:", item.iconURL?.absoluteString, "error:", error.isURLCancelledError ? "Cancelled" : error.localizedDescription)
                    }
                    fallbackIcon(grayscale: 0.9)
                        .help(error.localizedDescription)
                case .empty:
                    fallbackIcon(grayscale: 0.5)

                @unknown default:
                    fallbackIcon(grayscale: 0.8)
                }
            }
        }

        @ViewBuilder func fallbackIcon(grayscale: Double) -> some View {
            let baseColor = item.itemTintColor()
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(baseColor)
                .opacity(0.5)
                .grayscale(grayscale)
        }

        return Group {
            if let url = item.iconURL {
//                if let cachedImage = self.imageCache[url] {
//                    cachedImage
//                } else {
                    AsyncImage(url: url, scale: 1.0, transaction: Transaction(animation: .easeIn)) {
                        imageContent(phase: $0)
                    }
//                }
            } else {
                fallbackIcon(grayscale: 1.0)
            }
        }
        .aspectRatio(contentMode: .fit)
    }
}

