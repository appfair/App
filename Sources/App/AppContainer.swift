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


public extension AppContainer {
    /// The default size of the window; this will only be set the first time the app is launched; subsequent launches should automatically use whatever size the user left the app at
    static let defaultWindowSize = CGSize(width: 1200, height: 700)

    @SceneBuilder static func rootScene(store fairManager: FairManager) -> some SwiftUI.Scene {
        WindowGroup {
            RootView()
                .environmentObject(fairManager)
                .preferredColorScheme(fairManager.themeStyle.colorScheme)
                #if os(macOS)
                // the initial window sizing is done here; to test default window sizing first run: defaults delete app.App-Fair
                // note that idealWidth/Height does not work to set the default height; we need to use minWidth/Height to
                // .frame(idealWidth: 1200, maxWidth: .infinity, idealHeight: 700, maxHeight: .infinity)

                // on first launch, `firstLaunchV1` will be `true` and we will use the hardcoded default value.
                // subsequently, we should just use whatever the user last left the app at
                .frame(minWidth: fairManager.firstLaunchV1 ? defaultWindowSize.width : nil, minHeight: fairManager.firstLaunchV1 ? defaultWindowSize.height : nil)
                .onAppear {
                    // mark that we've successfully launched; this way, we can set the default
                    if fairManager.firstLaunchV1 == true {
                        fairManager.firstLaunchV1 = false
                    }
                }
                #endif
        }
        .commands {
            AppFairCommands(fairManager: fairManager)
        }
        .commands {
            SidebarCommands()
            SearchBarCommands()
            ToolbarCommands()
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                // only permit a single window
            }
        }
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store fairManager: FairManager) -> some SwiftUI.View {
        AppSettingsView()
            .preferredColorScheme(fairManager.themeStyle.colorScheme)
            .environmentObject(fairManager)
    }
}
