import FairApp

/// A view that can browse facets in either a tab or layout configuration.
public struct NavTabBrowserView<F: Facets> : View where F : View {
    /// Where the browser is at the top level or a lower level. This will affect whether it is rendered as a navigation hierarchy or a tabbed interface.
    public let nested: Bool
    @Binding var selection: F

    public init(nested: Bool = false, selection: Binding<F>) {
        self.nested = nested
        self._selection = selection
    }

    /// The outline needs to be an optional, since it can be de-selected (as opposed to tabs, which cannot be de-selected).
    private var optionalSelection: Binding<F?> {
        Binding(get: {
            selection
        }, set: { newValue in
            // setting the value to nil will fault in the initial element
            selection = newValue ?? F.allCases.first.unsafelyUnwrapped
        })
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
                ForEach(F.allCases, id: \.self) { facet in
                    facet
                        .tabItem {
                            facet.title.label(image: facet.symbol)
                        }
                }
            }
        } else {
            NavigationView {
                List {
                    ForEach(F.allCases.dropFirst(nested ? 0 : 1).dropLast(nested ? 0 : 1), id: \.self) { facet in
                        NavigationLink(tag: facet, selection: optionalSelection) {
                            facet
                        } label: {
                            facet.title.label(image: facet.symbol)
                        }
                    }
                }

                if !nested {
                    F.allCases.first.unsafelyUnwrapped
                }
            }
        }
    }
}

/// FacetView: outline on macOS, tabs on iOS
///
/// macOS: OutlineView w/ top-level Settings
///   iOS: TabView: Welcome, Settings
public struct FacetHostingView<AF: AppFacets> : View {
    @SceneStorage("selectedFacet") public var selectedFacet = AF.allCases.first.unsafelyUnwrapped

    public var body: some View {
        NavTabBrowserView(selection: $selectedFacet)
    }
}

/// On iOS, the facets are represented by tabs.
/// On macOS, facets are represented by top-level OutlineView sections.
/// By convention, the initial element of the `CaseIterable` list will be a welcome screen that will be shown on macOS when there is no selection, and is represented by the initial tab.
/// The final tab will be the settings tab, which is shown as a tab on iOS and is included in
public protocol Facets : CaseIterable, Hashable, RawRepresentable where RawValue == String, AllCases : RandomAccessCollection, AllCases.Index == Int {
    var title: Text { get }
    var symbol: FairSymbol { get }
}

public protocol AppFacets : Facets, View {
}

public protocol SettingsFacets : Facets, View {
}

//struct AboutView : View {
//
//}
//
//struct IconPickerView : View {
//
//}
//
//struct PrefsView : View {
//
//}
//
//struct LanguagesView : View {
//
//}
//
///// A user-interface to add/remove/browse/activate/deactivate/configure/debug JackPods
//struct PodsView : View {
//
//}
//
///// Log browser
//struct SupportView : View {
//
//}
//
//struct CreditsView : View {
//    var body: some View {
//        wip(Text("This app was written by Joan Dough."))
//    }
//}
//
//
//enum CuckooFacets : RootAppFacets {
//    case welcome // tab on iOS, unselected outline view on macOS
//    case game //
//    case settings // tab on iOS, settings window in macOS
//}
//
//enum RadioFacets : RootAppFacets {
//
//}
//
//enum BookFacets : RootAppFacets {
//
//}

