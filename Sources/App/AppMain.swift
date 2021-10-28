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

/// The `FairContainer` for the current app is the entry point 
/// to the app's initial launch, both in CLI and GUI forms.
///
/// - Note: This source in `AppMain.swift` must not be modified; 
///         App customization should be done in `AppContainer.swift`
@available(macOS 12.0, iOS 15.0, *)
@main public enum AppContainer : FairApp.FairContainer {
    public static func main() throws { try launch() }
}
