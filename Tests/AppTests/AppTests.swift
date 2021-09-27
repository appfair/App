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
import TabularData
import FairApp
@testable import App

@available(macOS 12.0, iOS 15.0, *)
open class AppTests: XCTestCase {
    open func testAppScene() throws {
        // awaiting Swift 5.5 final
        //let _ = AppContainer.rootScene
        //let _ = AppContainer.settingsView
    }

    // cannot run on CI until macOS12
#if false // WTF
#if swift(>=5.5)
#if canImport(TabularData)
    func testCatalogData() throws {
        // caught error: "Wrong number of columns at row 1. Expected 25 but found 31."
        let catalog = try StationCatalog.stations.get()
        dbg("catalog size:", catalog.count.localizedNumber())
        XCTAssertGreaterThanOrEqual(catalog.count, 25_000)
        let countryCounts = catalog.frame.grouped(by: "Country").counts(order: .descending)

        dbg("countryCounts", countryCounts)

        let cc = try StationCatalog.countryCounts.get()
        dbg(cc)
//        catalog.frame.grouped(by: "Country").counts(order: .descending).map({
//            $0["Country"] as? String
//        })

        let countries = countryCounts.rows
            .compactMap({ $0["Country"] as? String })
            .filter({ !$0.isEmpty })
        XCTAssertEqual(countries[0...4], [
            "The United States Of America",
            "Germany",
            "China",
            "France",
            "Greece",
        ])
        dbg(countries)
    }
#endif
#endif
#endif
}
