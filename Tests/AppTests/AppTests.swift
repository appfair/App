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

@available(macOS 12.0, iOS 15.0, *)
@MainActor final class AppTests: XCTestCase {
    func testAppScene() throws {
        // let store = AppContainer.AppStore()
        // let scene = AppContainer.rootScene(store: store)
        // let settings = AppContainer.settingsView(store: store)
        // let (_, _) = (scene, settings)
    }

    func testCaskList() async throws {
        let homeBrewInv = HomebrewInventory()
        XCTAssertEqual(homeBrewInv.casks.count, 0)
        let (casks, response) = try await homeBrewInv.fetchCasks()
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertGreaterThan(casks.count, 1000)
    }

    func testInstalledApps() throws {
//        let homeBrewInv = CaskManager()
//        XCTAssertEqual(0, homeBrewInv.installed.count)
//        try homeBrewInv.refreshInstalledApps()
//        XCTAssertNotEqual(0, homeBrewInv.installed.count, "assuming homebrew is installed, there should have been more than one installation")
    }
}

