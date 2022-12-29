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
import MiniApp

open class AppTests: XCTestCase {
    @MainActor open func testAppManager() throws {
        let store = AppContainer.AppManager()
        XCTAssertEqual(store.togglePreference, false)
        XCTAssertEqual(store.numberPreference, 0.0)

//        let cfg = AppContainer.AppManager.config
//        XCTAssertEqual("appfair/fairapp-theme", cfg["remote_theme"])
    }

    /// Creates screenshots for this app by iterating through all the facets, locales, and supported devices.
    /// When run in test cases with the default parameters, the generated screenshots will be included
    /// as metadata for the app submission.
    @MainActor open func testScreenshots() throws {
        _ = try Store().captureFacetScreens()
    }

    func testMiniAppHost() throws {
        let config = """
        {
          "dir": "ltr",
          "lang": "en",
          "app_id": "org.example.miniapp",
          "name": "MiniApp test",
          "pages": [
              "pages/home/home"
            ],
            "version": {
            "name": "1.0.0",
            "code": 1
          },
          "icons": [
            {
              "label": "Red lightning",
              "src": "common/icon48x48.png",
              "sizes": "48x48"
            }
          ],
          "platform_version":{
            "min_code": 1,
            "release_type": "Beta",
            "target_code": 1
          }
        }
        """

        let manifest = try MiniAppManifest.decode(from: config.utf8Data)
        XCTAssertEqual("MiniApp test", manifest.name)
    }
}
