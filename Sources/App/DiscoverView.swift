import FairApp
import SQLEnclave

@MainActor class SearchModel : ObservableObject {
    /// Updated when the search field changes
    @Published var filteredStations: [Station]?

    @Published var allStations: [Station] = [] {
        didSet {
            dbg("### updating tag cache")
        }
    }
}

extension Station {
    /// The split names from the "language" field
    var languageNames: [String] {
        language?.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }) ?? []
    }
}

struct DiscoverView : View {
    @State var scope: SearchScope = .name
    @Query(StationsRequest(ordering: .byClickCount)) private var stationsByClicks: [Station]
    @StateObject private var searchModel = SearchModel()

    var stations: [Station] {
        searchModel.filteredStations ?? stationsByClicks
    }

    @EnvironmentObject var store: Store

//    @Environment(\.searchSuggestionsPlacement) private var placement

    @State var nowPlayingTitle: String? = nil

    @State var searchText = ""
    @State var tokens: [SearchToken] = []

    @State var suggestedTokens: [SearchToken] = [
    ]

    var allLanguageTokens: [SearchToken] {
        stations
            .flatMap(\.languageNames)
            .countedSet()
            .map { keyValue in
                SearchToken(tokenType: .language, tag: keyValue.key, count: keyValue.value)
            }
            .sorting(by: \.count, ascending: false)
    }

    var allCountryTokens: [SearchToken] {
        stations
            .map {
                let code = $0.countrycode?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return code.isEmpty ? "UN" : code
            }
            .countedSet()
            .map { keyValue in
                SearchToken(tokenType: .country, tag: keyValue.key, count: keyValue.value)
            }
            .sorting(by: \.count, ascending: false)
    }

    var allTagTokens: [SearchToken] {
        stations
            .flatMap(\.tagElements)
            .countedSet()
            .map { keyValue in
                SearchToken(tokenType: .language, tag: keyValue.key, count: keyValue.value)
            }
            .sorting(by: \.count, ascending: false)
    }


    struct SearchToken : Identifiable {
        let id = UUID()
        let tokenType: SearchScope
        let tag: String
        let count: Int

        var text: Text {
            switch tokenType {
            case .name:
                return Text(tag)
            case .tag:
                return tagText(tag)
            case .language:
                return languageTag(tag)
            case .country:
                return countryTag(tag)
            }
        }

        func tagText(_ tag: String) -> Text {
            wip(Text(tag)) // TODO: extract tag info and localize
        }

        func languageTag(_ tag: String) -> Text {
            wip(Text(tag)) // TODO: extract tag info and localize
        }

        func countryTag(_ tag: String) -> Text {
            wip(Text(tag)) // TODO: extract tag info and localize
        }

        #if os(iOS)
        @available(macOS 13.0, iOS 16.0, *)
        var label: some View {
            @ViewBuilder func textLabel(withCounts: Bool) -> some View {
                Label {
                    if withCounts {
                        Text("\(self.text) (\(Text(self.count, format: .number)))", bundle: .module, comment: "label for station tag with the count appended at the end in parenthesis")
                    } else {
                        self.text
                    }
                } icon: {
                    // TODO: make a summary badge of the tag/language/country
                }
            }

            return ViewThatFits(in: .horizontal) {
                // the first view will be shown in the tag preview list; the second one without the counts will show up in the token field
                textLabel(withCounts: true).labelStyle(.titleAndIcon)
                textLabel(withCounts: false).labelStyle(.titleAndIcon)
            }
        }
        #endif
    }

    var body: some View {
        NavigationView {
            if #available(macOS 13.0, iOS 16.0, *) {
                #if os(iOS)
                stationList
                    .searchable(text: $searchText, tokens: $tokens, suggestedTokens: $suggestedTokens, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("Search", bundle: .module, comment: "station search prompt"), token: { token in
                        token.label
                })
                .searchScopes($scope) {
                    ForEach(SearchScope.allCases, id: \.self) { scope in
                        if scope == .name {
                            // for the defaut scope, just show the current search count
                            Text(stations.count, format: .number)
                                .tag(scope)
                        } else {
                            scope.label
                                .tag(scope)
                        }
                    }
                }
                .onChange(of: scope) { newValue in
                    dbg("changed search scope:", newValue)
                    switch newValue {
                    case .name:
                        self.suggestedTokens = []
                    case .tag:
                        self.suggestedTokens = allTagTokens
                    case .language:
                        self.suggestedTokens = allLanguageTokens
                    case .country:
                        self.suggestedTokens = allCountryTokens
                    }
                }
                #else
                stationList
                    .searchable(text: $searchText, placement: .automatic, prompt: Text("Search", bundle: .module, comment: "station search prompt"))
                #endif
            } else {
                stationList
                    .searchable(text: $searchText, placement: .automatic, prompt: Text("Search", bundle: .module, comment: "station search prompt"))
            }
        }
    }

    var stationList: some View {
        stationListView
//            .task(id: stationsByClicks) {
//                dbg("updated stations: \(stationsByClicks.count)")
//            }
//        .toolbar(id: "toolbar") {
//            ToolbarItem(id: "count", placement: .bottomBar, showsByDefault: true) {
//                Text(stations.count, format: .number)
////                    .button {
////                        dbg("XXX")
////                    }
//            }
//        }
        //.toolbar(Visibility.automatic, for: .bottomBar)
    }

    var stationListView: some View {
        List {
            ForEach(stations, content: stationRowView)
        }
        .listStyle(.inset)
//        .toolbar {
            //Text("C")
            //Text(stations.count, format: .number)
//        }
        .onChange(of: self.searchText, debounce: 0.075, priority: .low) { searchText in
            let searchString = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let stations = self.stationsByClicks
            let matches = stations.filter { station in
                searchString.isEmpty || (station.name ?? "").localizedCaseInsensitiveContains(searchString)
            }
            do {
                try Task.checkCancellation()
                self.searchModel.filteredStations = matches
            } catch {
                dbg("cancelled search")
            }
        }
        //.navigation(title: Text("Discover"), subtitle: Text("Stations"))
    }

    @ViewBuilder func stationRowView(station: Station) -> some View {
        let iconSize: Double = 50
        NavigationLink {
            StationView(station: station, itemTitle: $nowPlayingTitle)
                .environmentObject(RadioTuner.shared)
        } label: {
            //Text(station.name ?? "")
            Label(title: { stationLabelTitle(station) }) {
                station.iconView(download: store.downloadIcons, size: iconSize)
                    .frame(width: iconSize)
                    .mask(RoundedRectangle(cornerSize: store.circularIcons ? .init(width: iconSize/2, height: iconSize/2) : .init(width: 0, height: 0), style: .circular))
            }
            .labelStyle(StationLabelStyle())
        }
    }

//    struct CellView: View {
//        var scope: SearchScope
//        //@Environment(\.isSearching) var isSearching
//        //@Binding var filterPerson: [Person]
//
//        var body: some View {
//            if scope == .name {
//                // the "name" scope shows the current search count as the tab title
//                Text(stations.count, format: .number)
//            } else {
//                scope.label
//            }
//
//            //.onChange(of: isSearching) { newValue in
//            //    if !newValue {
//            //        filterPerson = Person.person
//            //    }
//            //}
//        }
//    }
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

enum SearchScope : Hashable, CaseIterable {
    case name
    case tag
    case language
    case country
}


extension SearchScope {
    @ViewBuilder var label: some View {
        switch self {
        case .name: Text("Name", bundle: .module, comment: "search scope label")
        case .tag: Text("Tag", bundle: .module, comment: "search scope label")
        case .language: Text("Language", bundle: .module, comment: "search scope label")
        case .country: Text("Country", bundle: .module, comment: "search scope label")
        }
    }
}

enum SearchSort : Hashable, CaseIterable {
    case byClickCount
    case byClickTrend
    case byName
}

extension SearchSort {
    @ViewBuilder var label: some View {
        switch self {
        case .byName: Text("Name", bundle: .module, comment: "search scope label")
        case .byClickCount: Text("Listeners", bundle: .module, comment: "search scope label")
        case .byClickTrend: Text("Trend", bundle: .module, comment: "search scope label")
        }
    }
}
