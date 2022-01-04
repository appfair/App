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
        let caskManager = CaskManager()
        XCTAssertEqual(caskManager.casks.count, 0)
        try await caskManager.fetchCasks()
        let casks = caskManager.casks
        XCTAssertGreaterThan(casks.count, 1000)
    }

    func testCaskStats() async throws {
        let caskManager = CaskManager()
        XCTAssertNil(caskManager.stats)
        try await caskManager.fetchStats()
        let stats = try XCTUnwrap(caskManager.stats)
        XCTAssertGreaterThan(stats.total_count, 1000) // e.g.: 894812
        XCTAssertGreaterThan(stats.formulae.values.joined().count, 1000) // e.g.: 6190
    }
}

