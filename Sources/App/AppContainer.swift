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
import FairApp
import WebKit

/// The global app environment containing configuration metadata and shared defaults.
///
/// The shared instance of Store is available throughout the app with:
/// ``@EnvironmentObject var store: Store``
open class Store: SceneManager {
    public var bundle: Bundle = .module

    public typealias AppFacets = EmptyFacetView<Store>
    public typealias ConfigFacets = EmptyFacetView<Store>

    /// The configuration metadata for the app from the `App.yml` file.
    public static let config: JSum = try! configuration(name: "App.yml", for: .module)

    @AppStorage("smoothScrolling") public var smoothScrolling = true
    @AppStorage("leadingTapAdvances") public var leadingTapAdvances = false

    public required init() {
    }
}

public struct EmptyFacetView<FM: FacetManager> : FacetView {
    public typealias FacetStore = FM
    public typealias FacetViewType = Never

    public var facetInfo: FacetInfo {
        fatalError()
    }

    public func facetView(for store: FM) -> Never {
        fatalError()
    }

    public static func facets<Manager>(for manager: Manager) -> [EmptyFacetView<FM>] where Manager : FairApp.FacetManager {
        []
    }
}

public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        EBookScene(store: store)
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store: Store) -> some SwiftUI.View {
        AppSettingsView()
            .environmentObject(store)
            .frame(width: 400, height: 300)
    }
}

