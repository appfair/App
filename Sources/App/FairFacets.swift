/**
 Copyright (c) 2022 Marc Prud'hommeaux

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
import Foundation

import FairApp

#if canImport(SwiftUI)
import SwiftUI
import FairCore

/// On iOS, the facets are represented by tabs.
/// On macOS, facets are represented by top-level OutlineView sections.
/// By convention, the initial element of the `CaseIterable` list will be a welcome screen that will be shown on macOS when there is no selection, and is represented by the initial tab.
///
/// The final tab will be the settings tab, which is shown as a tab on iOS and is included in the standard settings window on macOS.
public protocol Facet : CaseIterable, Hashable, RawRepresentable where RawValue == String, AllCases : RandomAccessCollection, AllCases.Index == Int {

    /// Metadata for the facet
    typealias FacetInfo = (title: Text, symbol: FairSymbol?, tint: Color?)

    /// The title, icon, and tint color for the facet
    var facetInfo: FacetInfo { get }
}


/// FacetHostingView: a top-level browser fo an app's `Facet`s,
/// represented as either an outline on macOS or tabs on iOS.
///
/// macOS: OutlineView w/ top-level Settings
///   iOS: TabView: Welcome, Settings
public struct FacetHostingView<AF: Facet & View> : View {
    @SceneStorage("facetSelection") private var facetSelection: AF.RawValue = .init()

    public var body: some View {
        FacetBrowserView(nested: false, selection: selectionBinding)
            .focusedSceneValue(\.facetSelection, selectionOptionalBinding)
    }


    /// The current selection is stored as the underlying Raw Value string, which enables us to easily store it if need be.
    private var selectionBinding: Binding<AF?> {
        Binding(get: { AF(rawValue: facetSelection) }, set: { newValue in self.facetSelection = newValue?.rawValue ?? .init() })
    }

    /// The current selection is stored as the underlying Raw Value string, which enables us to easily store it if need be.
    private var selectionOptionalBinding: Binding<AF.RawValue?> {
        Binding(get: { facetSelection }, set: { newValue in self.facetSelection = newValue ?? .init() })
    }
}

extension FocusedValues {
    /// The underlying value of the currently-selected facet
    var facetSelection: Binding<String?>? {
        get { self[FacetSelectionKey.self] }
        set { self[FacetSelectionKey.self] = newValue }
    }

    private struct FacetSelectionKey : FocusedValueKey {
        typealias Value = Binding<String?>
    }
}

fileprivate extension KeyEquivalent {
    /// Returns a `KeyEquivalent` for the given number
    static func indexed(_ itemIndex: Int) -> Self? {
        switch itemIndex {
        case 0: return "0"
        case 1: return "1"
        case 2: return "2"
        case 3: return "3"
        case 4: return "4"
        case 5: return "5"
        case 6: return "6"
        case 7: return "7"
        case 8: return "8"
        case 9: return "9"
        default: return nil
        }
    }
}

/// Commands for selecting the facet using menus and keyboard shortcuts
public struct FacetCommands<AF: Facet> : Commands {
    @FocusedBinding(\.facetSelection) private var facetSelection: AF.RawValue??

    public var body: some Commands {
        CommandGroup(before: .toolbar) {
            ForEach(AF.allCases.dropLast().enumerated().array(), id: \.element) { index, facet in
                let menu = facet.facetInfo.title
                    .label(image: facet.facetInfo.symbol)
                    .tint(facet.facetInfo.tint)
                    .button {
                        self.facetSelection = facet.rawValue
                    }

                if let key = KeyEquivalent.indexed(index) {
                    menu.keyboardShortcut(key) // 0-9 have automatic shortcuts assigned
                } else {
                    menu
                }
            }
        }
    }
}

extension Facet {
    /// The tab's tag for the facet, which needs to be `Optional` to match the optional selection
    var facetTag: Self? { self }
}

/// A view that can browse facets in either a tabbed or outline view configuration, depending on a combination of the current platform and the value if the `nested` setting.
public struct FacetBrowserView<F: Facet> : View where F : View {
    /// Whether the browser is at the top level or a lower level. This will affect whether it is rendered as a navigation hierarchy or a tabbed interface.
    public let nested: Bool
    @Binding var selection: F?

    public init(nested: Bool = true, selection: Binding<F?>) {
        self.nested = nested
        self._selection = selection
    }

    private var displayInTabs: Bool {
#if os(macOS)
        nested
#else
        !nested
#endif
    }

    public var body: some View {
        if displayInTabs {
            TabView(selection: $selection) {
                ForEach(F.allCases, id: \.facetTag) { facet in
                    NavigationView {
                        facet
                            .navigationTitle(facet.facetInfo.title)
#if os(iOS)
                            .navigationBarTitleDisplayMode(.inline)
#endif
                    }
                    .tabItem {
                        facet.facetInfo.title.label(image: facet.facetInfo.symbol)
                            .symbolVariant(.fill)
                    }
                    .tint(facet.facetInfo.tint)
                }
            }
        } else {
            NavigationView {
                List {
                    ForEach(F.allCases.dropFirst(nested ? 0 : 1).dropLast(nested ? 0 : 1), id: \.self) { facet in
                        NavigationLink(tag: facet, selection: $selection) {
                            facet
                                .navigationTitle(facet.facetInfo.title)
                        } label: {
                            facet.facetInfo.title.label(image: facet.facetInfo.symbol)
                                .tint(facet.facetInfo.tint)
                        }
                    }
                }
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif

                if !nested {
                    // the default placeholder view is the welcome screen
                    F.allCases.first.unsafelyUnwrapped
                }
            }
        }
    }
}
#endif

