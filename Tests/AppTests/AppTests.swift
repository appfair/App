/**
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 The full text of the GNU Affero General Public License can be
 found in the COPYING.txt file or at https://www.gnu.org/licenses/

 Linking this library statically or dynamically with other modules is
 making a combined work based on this library.  Thus, the terms and
 conditions of the GNU Affero General Public License cover the whole
 combination.

 As a special exception, the copyright holders of this library give you
 permission to link this library with independent modules to produce an
 executable, regardless of the license terms of these independent
 modules, and to copy and distribute the resulting executable under
 terms of your choice, provided that you also meet, for each linked
 independent module, the terms and conditions of the license of that
 module.  An independent module is a module which is not derived from
 or based on this library.  If you modify this library, you may extend
 this exception to your version of the library, but you are not
 obligated to do so.  If you do not wish to do so, delete this
 exception statement from your version.
 */
import Swift
import XCTest
import App
import FairCore
import FairExpo

open class AppTests: XCTestCase {
//    @MainActor open func testAppStore() throws {
//        let store = AppContainer.AppManager()
//        XCTAssertEqual(store.hubOrg, "appfair")
//        let cfg = AppContainer.AppManager.config
//        XCTAssertEqual("appfair/fairapp-theme", cfg["remote_theme"])
//    }

    #if os(macOS) // HomebrewInventory not available on iOS
    func testCaskList() async throws {
        let homeBrewInv = HomebrewInventory(source: .homebrew, sourceURL: appfairCaskAppsURL)
        XCTAssertEqual(homeBrewInv.casks.count, 0)
        let (casks, response) = try await homeBrewInv.homebrewAPI.fetchCasks()
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertGreaterThan(casks.count, 1000)
    }
    #endif

    @MainActor open func testAppManager() throws {
        let store = AppContainer.AppManager()
//        XCTAssertEqual(store.togglePreference, false)
//        XCTAssertEqual(store.numberPreference, 0.0)

//        let cfg = AppContainer.AppManager.config
//        XCTAssertEqual("appfair/fairapp-theme", cfg["remote_theme"])
    }

    /// Creates screenshots for this app by iterating through all the facets, locales, and supported devices.
    /// When run in test cases with the default parameters, the generated screenshots will be included
    /// as metadata for the app submission.
    @MainActor open func testScreenshots() throws {
        throw XCTSkip("TODO")
//        _ = try Store().captureFacetScreens()
    }

//    func testInstalledApps() throws {
//        let homeBrewInv = CaskManager()
//        XCTAssertEqual(0, homeBrewInv.installed.count)
//        try homeBrewInv.refreshInstalledApps()
//        XCTAssertNotEqual(0, homeBrewInv.installed.count, "assuming homebrew is installed, there should have been more than one installation")
//    }

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
