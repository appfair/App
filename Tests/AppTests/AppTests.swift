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
}

