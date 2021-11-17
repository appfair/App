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

@available(macOS 12.0, iOS 15.0, *)
public extension AppContainer {
    /// The root scene for this application
    static func rootScene(store appManager: AppManager) -> some Scene {
        WindowGroup {
            NavigationRootView()
                // .edgesIgnoringSafeArea(.all) // doesn't affect iPhone landscape catalog info header 
                .environmentObject(appManager)
                .preferredColorScheme(appManager.themeStyle.colorScheme)
                .task({ await appManager.scanInstalledApps() })
        }
        .commands {
            SidebarCommands()
            SearchCommands()
            AppFairCommands(appManager: appManager)
            ToolbarCommands()
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                // only permit a single window
            }
        }
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store appManager: AppManager) -> some SwiftUI.View {
        AppSettingsView()
            .environmentObject(appManager)
            .preferredColorScheme(appManager.themeStyle.colorScheme)
    }
}
