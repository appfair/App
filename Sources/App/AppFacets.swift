import FairApp

/// FacetView: outline on macOS, tabs on iOS
///
/// macOS: OutlineView w/ top-level Settings
///   iOS: TabView: Welcome, Settings
public struct FacetHostingView<AF: AppFacets> : View {
    @AppStorage("selectedFacet") public var selectedFacet = AF.allCases.first!

    public var body: some View {
        #if os(iOS)
        TabView(selection: $selectedFacet) {
            ForEach(AF.allCases, id: \.self) { facet in
                facet
                    .tabItem {
                        facet.title.label(image: facet.symbol)
                    }
            }
        }
        //.tabViewStyle(.page)
        #elseif os(macOS)
        AF.allCases[(AF.allCases.count) / 2] // default view is the center selection
        #endif
    }
}

/// On iOS, the facets are represented by tabs.
/// On macOS, facets are represented by top-level OutlineView sections.
/// By convention, the initial element of the `CaseIterable` list will be a welcome screen that will be shown on macOS when there is no selection, and is represented by the initial tab.
/// The final tab will be the settings tab, which is shown as a tab on iOS and is included in
public protocol Facet : CaseIterable, Hashable, RawRepresentable where RawValue == String, AllCases : RandomAccessCollection, AllCases.Index == Int {
    var title: Text { get }
    var symbol: FairSymbol { get }
}

public protocol AppFacets : Facet, View {
}

public protocol SettingsFacets : Facet, View {
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

