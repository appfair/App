/**
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 The full text of the GNU Affero General Public License can be
 found in the COPYING.txt file or at https://www.gnu.org/licenses/

 Linking this library statically or dynamically with other modules is
 making a combined work based on this library.  Thus, the terms and
 conditions of the GNU Affero General Public License cover the whole
 combination.

 As a special exception, the copyright holders of this library give you
 permission to link this library with independent modules to produce an
 executable, regardless of the license terms of these independent
 modules, and to copy and distribute the resulting executable under
 terms of your choice, provided that you also meet, for each linked
 independent module, the terms and conditions of the license of that
 module.  An independent module is a module which is not derived from
 or based on this library.  If you modify this library, you may extend
 this exception to your version of the library, but you are not
 obligated to do so.  If you do not wish to do so, delete this
 exception statement from your version.
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
