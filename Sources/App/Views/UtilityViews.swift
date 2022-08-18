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


/// A label that tints its image
public struct TintedLabel : View, Equatable {
    //@Environment(\.colorScheme) var colorScheme
    public var title: Text
    public let symbol: FairSymbol
    public var tint: Color? = nil
    public var mode: RenderingMode?

    public var body: some View {
        Label(title: { title }) {
            if let tint = tint {
                if let mode = mode {
                    symbol.image
                        .symbolRenderingMode(mode.symbolRenderingMode)
                        .foregroundStyle(tint)
                } else {
                    symbol.image
                        .fairTint(simple: true, color: tint)
                }
            } else {
                symbol.image
            }
        }
    }

    /// An equatable form of the struct based SymbolRenderingMode instances
    public enum RenderingMode : Equatable {
        case monochrome
        case hierarchical
        case multicolor
        case palette

        /// The instance of `SymbolRenderingMode` that matches this renderig mode.
        var symbolRenderingMode: SymbolRenderingMode {
            switch self {
            case .monochrome: return SymbolRenderingMode.monochrome
            case .hierarchical: return SymbolRenderingMode.hierarchical
            case .multicolor: return SymbolRenderingMode.multicolor
            case .palette: return SymbolRenderingMode.palette
            }
        }
    }
}


/// A label that describes an error condition
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