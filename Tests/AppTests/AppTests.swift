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
import App
import FairApp
import SwiftUI

open class AppTests: XCTestCase {
    @MainActor open func testAppStore() throws {
        let store = AppContainer.AppStore()
        XCTAssertEqual(store.togglePreference, false)
        XCTAssertEqual(store.numberPreference, 0.0)

        let cfg = AppContainer.AppStore.config
        XCTAssertEqual("appfair/fairapp-theme", cfg["remote_theme"])

        let fnd: JSum = AppContainer.AppStore.configuration(name: "FUNDING", for: Store().bundle)
        XCTAssertNotNil(fnd["custom"], "blank funding custom template should exist")
        XCTAssertNil(fnd["EMPTY_KEY"])

    }

    /// Creates screenshots for this app by iterating through all the facets, locales, and supported devices.
    /// When run in test cases with the default parameters, the generated screenshots will be included
    /// as metadata for the app submission.
    @MainActor open func testScreenshots() throws {
        _ = try Store().captureFacetScreens()
    }
}
