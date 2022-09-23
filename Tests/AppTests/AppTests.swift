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

/** Cannot run on macOS11

#if canImport(TabularData)
import TabularData
import FairApp

@testable import App

open class AppTests: XCTestCase {
    open func testAppScene() throws {
        // awaiting Swift 5.5 final
        //let _ = AppContainer.rootScene
        //let _ = AppContainer.settingsView
    @MainActor open func testAppStore() throws {
        let store = AppContainer.AppStore()
        XCTAssertEqual(store.someToggle, false)
        let cfg = AppContainer.AppStore.config
        XCTAssertEqual("appfair/fairapp-theme", cfg["remote_theme"])
    }

    // cannot run on CI until macOS12
    #if swift(>=5.5)
    #if canImport(TabularData)
    #if false // need to block it out because of link errors on macOS11
    func testNewCatalog() throws {
        // headers: changeuuid,stationuuid,name,url,url_resolved,homepage,favicon,tags,country,countrycode,iso_3166_2,state,language,languagecodes,votes,lastchangetime,lastchangetime_iso8601,codec,bitrate,hls,lastcheckok,lastchecktime,lastchecktime_iso8601,lastcheckoktime,lastcheckoktime_iso8601,lastlocalchecktime,lastlocalchecktime_iso8601,clicktimestamp,clicktimestamp_iso8601,clickcount,clicktrend,ssl_error,geo_lat,geo_long,has_extended_info

        // sample row: 9ab6e93e-0e30-468e-9da4-17ccce79ed14,bf91ff05-3fd0-4b9f-a31a-8e881bbee7bd, FM 94.3 Radio Municipal de Toay,http://servidor.ilive.com.ar:9678/;,http://servidor.ilive.com.ar:9678/;,https://toay.gob.ar/,https://toay.gob.ar/images/logo.png,"municipal,toay,la pampa,argentina",Argentina,AR,,La Pampa - Toay,,,17,2021-07-14 08:51:10,2021-07-14T08:51:10Z,MP3,40,0,1,2021-10-05 15:21:24,2021-10-05T15:21:24Z,2021-10-05 15:21:24,2021-10-05T15:21:24Z,2021-10-04 19:20:11,2021-10-04T19:20:11Z,2021-10-05 14:51:32,2021-10-05T14:51:32Z,10,0,0,-36.67310369339906,-64.37880992889406,false

        //let url = try XCTUnwrap(URL(string: "https://fr1.api.radio-browser.info/csv/stations/search?limit=10&hidebroken=true"))


        func fetchURL(location: String = "nl1", format: String = "csv") -> URL! {
            URL(string: "https://\(location).api.radio-browser.info/\(format)/stations/search?limit=10&hidebroken=true")
        }

        let csvURL = try XCTUnwrap(fetchURL())
        let csvFrame = try DataFrame(contentsOfCSVFile: csvURL)

        let jsonURL = try XCTUnwrap(fetchURL(location: "fr1", format: "json"))
        let jsonFrame = try DataFrame(contentsOfJSONFile: jsonURL)

        XCTAssertEqual(csvFrame.rows.count, jsonFrame.rows.count)
    }

    func testCatalogData() throws {
        // caught error: "Wrong number of columns at row 1. Expected 25 but found 31."
        let catalog = try StationCatalog.stations.get()
        dbg("catalog size:", catalog.count.localizedNumber())
        XCTAssertGreaterThanOrEqual(catalog.count, 25_000)
        let countryCounts = catalog.frame.grouped(by: Station.countrycodeColumn).counts(order: .descending)

        dbg("countryCounts", countryCounts)

        let cc = try StationCatalog.countryCounts.get()
        dbg(cc)

        let countries = countryCounts.rows
            .compactMap({ $0[Station.countrycodeColumn] })
            .filter({ !$0.isEmpty })
        XCTAssertEqual(countries[0...4], [
            "US",
            "DE",
            "CN",
            "FR",
            "GR",
        ])
        dbg(countries)
    }
    #endif
    #endif
    #endif
}
#endif // canImport(TabularData)
*/
