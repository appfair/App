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

open class AppTests: XCTestCase {
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    open func testAppScene() throws {
        // awaiting Swift 5.5 final
        //let _ = AppContainer.rootScene
        //let _ = AppContainer.settingsView
    }

    func testTideTables() async throws {
        // TODO: use API at https://api.tidesandcurrents.noaa.gov/mdapi/prod/
        // fetch all the tide predictions, aggregate them and save them to a resource

        // FIXME: this is not the complete list of stations
        let url = URL(string: "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations.json")!
        let (data, response) = try await URLSession.shared.data(from: url)
        XCTAssert((200..<300).contains((response as? HTTPURLResponse)?.statusCode ?? 0))
        XCTAssert(data.count > 1024)

        struct StationList : Decodable {
            let count: Int
            // let units: String?
            let stations: [Station]
        }

        /**
        ```
         {
               "tidal": true,
               "greatlakes": false,
               "shefcode": "ATGM1",
               "details": {
                 "self": "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations/8413320/details.json"
               },
               "sensors": {
                 "self": "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations/8413320/sensors.json"
               },
               "floodlevels": {
                 "self": "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations/8413320/floodlevels.json"
               },
               "datums": {
                 "self": "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations/8413320/datums.json"
               },
               "supersededdatums": {
                 "self": "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations/8413320/supersededdatums.json"
               },
               "harmonicConstituents": {
                 "self": "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations/8413320/harcon.json"
               },
               "benchmarks": {
                 "self": "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations/8413320/benchmarks.json"
               },
               "tidePredOffsets": {
                 "self": "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations/8413320/tidepredoffsets.json"
               },
               "state": "ME",
               "timezone": "EST",
               "timezonecorr": -5,
               "observedst": true,
               "stormsurge": false,
               "nearby": {
                 "self": "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations/8413320/nearby.json"
               },
               "forecast": true,
               "nonNavigational": false,
               "id": "8413320",
               "name": "Bar Harbor",
               "lat": 44.392194,
               "lng": -68.204278,
               "affiliations": "NWLON",
               "portscode": null,
               "products": {
                 "self": "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations/8413320/products.json"
               },
               "disclaimers": {
                 "self": "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations/8413320/disclaimers.json"
               },
               "notices": {
                 "self": "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations/8413320/notices.json"
               },
               "self": "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations/8413320.json",
               "expand": "details,sensors,floodlevels,datums,harcon,tidepredoffsets,products,disclaimers,notices",
               "tideType": "Mixed"
             }         ```
         */
        struct Station : Decodable {
            let id: String // "8413320",

            let name: String // "Bar Harbor",
            let state: String // "ME",

            let lat: Double // 44.392194,
            let lng: Double // -68.204278,

            let affiliations: String // "NWLON",
            let expand: String // "details,sensors,floodlevels,datums,harcon,tidepredoffsets,products,disclaimers,notices",
            let tideType: String // "Mixed"

            let portscode: String? // null,

            let shefcode: String
            let timezone: String // "EST",
            let timezonecorr: Int // -5,

            let tidal: Bool
            let greatlakes: Bool
            let observedst: Bool // true,
            let stormsurge: Bool // false,
            let forecast: Bool // true,
            let nonNavigational: Bool // false,

            let `self`: URL

            let details: SelfLink
            let sensors: SelfLink
            let floodlevels: SelfLink
            let datums: SelfLink
            let supersededdatums: SelfLink
            let harmonicConstituents: SelfLink
            let benchmarks: SelfLink
            let tidePredOffsets: SelfLink
            let nearby: SelfLink
            let products: SelfLink
            let disclaimers: SelfLink
            let notices: SelfLink
        }

        struct SelfLink : Decodable {
            let `self`: URL
        }

        let list = try StationList(json: data)
        XCTAssertEqual(298, list.count)
        XCTAssertEqual(6, list.stations.filter({ $0.state == "ME" }).count)
    }
}

