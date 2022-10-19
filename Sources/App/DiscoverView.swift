import FairApp
import SQLEnclave

struct DiscoverView : View {
    @State var scope: SearchScope = SearchScope.byClickCount

    var stations: [Station] {
        switch self.scope {
        case .byClickCount: return stationsByClicks // stationsByClicks
        case .byClickTrend: return stationsByClicks // stationsByClickTrend
        case .byName: return stationsByClicks
        }

    }

    @EnvironmentObject var store: Store

//    @Environment(\.searchSuggestionsPlacement) private var placement

    @State var nowPlayingTitle: String? = nil

    @State var searchText = ""
    @State var tokens: [SearchToken] = []

    @State var suggestedTokens: [SearchToken] = [
        SearchToken(tokenType: .byClickTrend, text: Text("Token A")),
        SearchToken(tokenType: .byName, text: Text("Token B")),
    ]

//    @Query(StationsRequest(ordering: .byName)) private var stationsByName: [Station]

    @Query(StationsRequest(ordering: .byClickCount)) private var stationsByClicks: [Station]
//    @Query(StationsRequest(ordering: .byClickTrend)) private var stationsByClickTrend: [Station]

//    enum SearchScope : Hashable, CaseIterable {
//        case name
//        case language
//        case country
//
//        @ViewBuilder var label: some View {
//            switch self {
//            case .name: Text("Name", bundle: .module, comment: "search scope label")
//            case .language: Text("Language", bundle: .module, comment: "search scope label")
//            case .country: Text("Country", bundle: .module, comment: "search scope label")
//            }
//        }
//    }

    struct SearchToken : Identifiable {
        let id = UUID()
        let tokenType: SearchScope
        let text: Text


        @available(macOS 13.0, iOS 16.0, *)
        var label: some View {
            ViewThatFits(in: .horizontal) {
                Label {
                    self.text
                } icon: {
                    Image(.infinity)
                }

                Label {
                    wip(self.text) // TODO: abbreviated text options for shorted display
                } icon: {
                }
            }
        }
    }

    var body: some View {
        NavigationView {
            if #available(macOS 13.0, iOS 16.0, *) {
                stationList
                    .searchable(text: $searchText, tokens: $tokens, suggestedTokens: $suggestedTokens, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("Search", bundle: .module, comment: "station search prompt"), token: { token in
                        token.label
                })
                .searchScopes($scope) {
                    ForEach(SearchScope.allCases, id: \.self) { scope in
                        scope.label
                    }
                }
                .onChange(of: scope) { newValue in
                    print("changed search scope:", newValue)
//                    filterPerson = Person.person.filter {
//                        $0.type == newValue
//                    }
                }
            } else {
                stationList
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("Search", bundle: .module, comment: "station search prompt"))
            }
        }
    }

    var stationList: some View {
        List {
            ForEach(stations, content: stationRowView)
        }
        //.navigation(title: Text("Discover"), subtitle: Text("Stations"))
    }

    func stationRowView(station: Station) -> some View {
        NavigationLink {
            StationView(station: station, itemTitle: $nowPlayingTitle)
                .environmentObject(RadioTuner.shared)
        } label: {
            //Text(station.name ?? "")
            Label(title: { stationLabelTitle(station) }) {
                station.iconView(size: 50)
                    .frame(width: 50)
            }
            .labelStyle(StationLabelStyle())

        }
    }

    struct CellView: View {
        var scope: SearchScope
        //    @Environment(\.isSearching) var isSearching
        //    @Binding var filterPerson: [Person]

        var body: some View {
            scope.label
            //            .onChange(of: isSearching) { newValue in
            //                if !newValue {
            //                    filterPerson = Person.person
            //                }
            //            }
        }
    }
}

enum SearchScope : Hashable, CaseIterable {
    case byClickCount
    case byClickTrend
    case byName
}


extension View {
    func stationLabelTitle(_ station: Station) -> some View {
        VStack(alignment: .leading) {
            (station.name.map(Text.init) ?? Text("Unknown Name", bundle: .module, comment: "empty label text title"))
                .font(.title3)
            .lineLimit(1)
            .allowsTightening(true)
            .truncationMode(.middle)


            HStack {
//                if let lang = station.Language, !lang.isEmpty {
//                    (Text("Language: ") + Text(lang))
//                }
//                if let tags = station.Tags, !tags.isEmpty {
//                    (Text("Tags: ") + Text(tags))
//                }


                let br = station.bitrate ?? 0
                (Text(station.bitrate == nil ? Double.nan : Double(br), format: .number) + Text("k", bundle: .module, comment: "kilobytes suffix"))
                    .foregroundColor(br >= 256 ? Color.green : br < 128 ? Color.gray : Color.blue)
                    .font(.body.monospaced())

                HStack(spacing: 2) {
                    let tags = station.tagElements
                        .compactMap(Station.tagInfo(tagString:))
                        .prefix(10) // maximum of 10 tags we display
                    ForEach(enumerated: tags) { offset, titleImage in
                        titleImage.image
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(titleImage.tint)
                            .help(titleImage.title)
                    }
                }
                .symbolRenderingMode(.monochrome)
                .symbolVariant(.circle)

            }
            .lineLimit(1)
//            .allowsTightening(true)
//            .truncationMode(.middle)
//            .foregroundColor(Color.secondary)
        }
    }
}
extension SearchScope {
    @ViewBuilder var label: some View {
        switch self {
        case .byName: Text("Name", bundle: .module, comment: "search scope label")
        case .byClickCount: Text("Listeners", bundle: .module, comment: "search scope label")
        case .byClickTrend: Text("Trend", bundle: .module, comment: "search scope label")
        }
    }
}
