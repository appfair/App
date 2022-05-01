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
import FairKit

/// A label that describes an error condition
@available(macOS 12.0, iOS 15.0, *)
public struct ErrorLabel<E: Error> : View {
    public let error: E

    public init(_ error: E) {
        self.error = error
    }

    public var body: some View {
        Label(error.localizedDescription, systemImage: "xmark.octagon.fill")
            .symbolRenderingMode(.multicolor)
            .textSelection(.enabled)
    }
}
