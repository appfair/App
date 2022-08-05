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
import Swift
import XCTest
@testable import App
import FairCore
import FairExpo

@MainActor final class AppTests: XCTestCase {
    func testAppScene() throws {
        // let store = AppContainer.AppStore()
        // let scene = AppContainer.rootScene(store: store)
        // let settings = AppContainer.settingsView(store: store)
        // let (_, _) = (scene, settings)
    }

    func testCaskList() async throws {
//        let homeBrewInv = HomebrewInventory.default
//        XCTAssertEqual(homeBrewInv.casks.count, 0)
//        let (casks, response) = try await homeBrewInv.fetchCasks()
//        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
//        XCTAssertGreaterThan(casks.count, 1000)
    }

    func testInstalledApps() throws {
//        let homeBrewInv = CaskManager()
//        XCTAssertEqual(0, homeBrewInv.installed.count)
//        try homeBrewInv.refreshInstalledApps()
//        XCTAssertNotEqual(0, homeBrewInv.installed.count, "assuming homebrew is installed, there should have been more than one installation")
    }

//    func testAppcastParsing() async throws {
//        let inv = HomebrewInventory.default
//
//        @Sendable func checkAppcast(package: String) async throws -> AppcastFeed {
//            dbg("checking appcast package:", package)
//            guard let (strategy, url) = try await inv.fetchLivecheck(for: package) else {
//                // throw XCTestError("could not fetch livecheck on: \(package)")
//                throw URLError(.badURL)
//            }
//
//            dbg("testing package:", package, url.absoluteString)
//
//            XCTAssertTrue(strategy.hasPrefix(":sparkle")) // e.g., can also be: ":sparkle, &:short_version"
//            let (contents, _) = try await URLSession.shared.fetch(request: URLRequest(url: url))
//            let webFeed = try AppcastFeed(xmlData: contents)
//            return webFeed
//        }
//
//        async let feeds = try (
//            proxyman: checkAppcast(package: "proxyman"),
//            keka: checkAppcast(package: "keka")
//        )
//
//        let keka = try await feeds.keka.channels.first
//        XCTAssertEqual(keka?.title, "Keka")
//
//        let proxyman = try await feeds.proxyman.channels.first
//        XCTAssertEqual(proxyman?.title, "Proxyman")
//        if let proxyman = proxyman {
//            guard let enc = proxyman.items.first?.enclosures.first else {
//                return XCTFail("no enclosure")
//            }
//            XCTAssertEqual("application/octet-stream", enc.type)
//
//            // version-specific checks
//            //XCTAssertEqual("33436697", enc.length)
//            //XCTAssertEqual("MC0CFClWh6mZMHIyWtezyyNkAUMF27JTAhUAp0duxxXgtGm0XFGqSQnRipCCgB8=", enc.dsaSignature)
//            //XCTAssertEqual("30400", enc.version)
//            //XCTAssertEqual("3.4.0", enc.shortVersionString)
//        }
//    }
}


/// An ``AppManagement`` example that does nothing.
private actor StubAppManagement : AppManagement {
    func installedPath(for item: AppInfo) async throws -> URL? {
        nil
    }

    func install(_ item: AppInfo, progress parentProgress: Progress?, downloadOnly: Bool, update: Bool, verbose: Bool) async throws {
        
    }
    
    /// Installs the given item
    func install(_ item: AppInfo, progress parentProgress: Progress?, update: Bool, verbose: Bool) async throws {
        throw CocoaError(.featureUnsupported)
    }

    /// Instructs the system to reveal the path of the item using the Finder
    func reveal(_ item: AppInfo) async throws {
        throw CocoaError(.featureUnsupported)
    }

    /// Instructs the system to launch the item
    func launch(_ item: AppInfo) async throws {
        throw CocoaError(.featureUnsupported)
    }

    /// Deletes the given item from the system
    func delete(_ item: AppInfo, verbose: Bool) async throws {
        throw CocoaError(.featureUnsupported)
    }
}
