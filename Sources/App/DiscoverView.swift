import FairApp
import SQLEnclave

@MainActor class SearchModel : ObservableObject {
    /// Updated when the search field changes
    @Published var filteredStations: [Station]?

    //@Published var allStations: [Station] = []
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

    //@Environment(\.searchSuggestionsPlacement) private var placement
    @Environment(\.locale) private var locale

    @State var nowPlayingTitle: String? = nil

    @State var searchText = ""
    @State var tokens: [SearchToken] = [
        wip(SearchToken(tokenType: .language, tag: "french", count: 0)),
        wip(SearchToken(tokenType: .tag, tag: "pop", count: 0)),
    ]

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
                SearchToken(tokenType: .tag, tag: keyValue.key, count: keyValue.value)
            }
            .sorting(by: \.count, ascending: false)
    }


    var body: some View {
        NavigationView {
            if #available(macOS 13.0, iOS 16.0, *) {
#if os(iOS)
                stationList
                    .searchable(text: $searchText, tokens: $tokens, suggestedTokens: $suggestedTokens, placement: .navigationBarDrawer(displayMode: .always), prompt: nil, token: { token in
                        SearchTokenView(token: token)
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
            // TODO: the toolbar should show up between the tab view and the ForEach in order to be displayed with all the tabs, but we currently have no way to do that
        #if os(iOS)
            .toolbar(id: "toolbar") {
                ToolbarItem(id: "count", placement: .bottomBar, showsByDefault: true) {
                    Text(stations.count, format: .number)
                }
                ToolbarItem(id: "play", placement: .bottomBar, showsByDefault: true) {
                    Button {
                        dbg("playing")
                        //tuner.player.play()
                    } label: {
                        Text("Play").label(symbol: "play").symbolVariant(.fill)
                    }
                    .keyboardShortcut(.space, modifiers: [])
                    //.disabled(self.rate > 0)
                    .help(Text("Play the current track"))
                }
                ToolbarItem(id: "pause", placement: .bottomBar, showsByDefault: true) {
                    Button {
                        dbg("pausing")
                        //tuner.player.pause()
                    } label: {
                        Text("Pause").label(symbol: "pause").symbolVariant(.fill)
                    }
                    .keyboardShortcut(.space, modifiers: [])
                    //.disabled(self.rate == 0)
                    .help(Text("Pause the current track"))
                }
            }
//                .toolbar(Visibility.visible, for: .bottomBar)
        #endif
    }

    var stationListView: some View {
        List {
            ForEach(stations, content: stationRowView)
        }
        .listStyle(.inset)
        .onChange(of: self.searchText, debounce: 0.075, priority: .low, perform: updateSearch)
        //.navigation(title: Text("Discover"), subtitle: Text("Stations"))
    }

    func updateSearch(searchText: String) async {
        let searchString = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let stations = self.stationsByClicks

        let toktags = { t in tokens.filter({ $0.tokenType == t }).map(\.tag).set() }
        let langs = toktags(.language)
        let tags = toktags(.tag)
        let countries = toktags(.country)

        let matches = stations.filter { station in
            (searchString.isEmpty || (station.name ?? "").localizedCaseInsensitiveContains(searchString))
            && (langs.isEmpty || !langs.isDisjoint(with: station.languageNames))
            && (tags.isEmpty || !tags.isDisjoint(with: station.tagElements))
            && (countries.isEmpty || !countries.isDisjoint(with: station.countrycode.flatMap({ [$0] }) ?? []))
        }


        do {
            try Task.checkCancellation()
            self.searchModel.filteredStations = matches
        } catch {
            dbg("cancelled search")
        }

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

    /// Returns the localized name of the given country string
    func coutryLabel(for station: Station) -> String? {
        guard let country = station.countrycode else {
            return nil
        }
        return locale.countryName(for: country)
    }

    /// Concatenated list of language names
    func languageLabel(for station: Station) -> String {
        //NumberFormatter.localizedString(from: 11111111, number: .decimal)
        ListFormatter.localizedString(byJoining: station.languageNames.map(locale.languageName))
    }


    func stationLabelTitle(_ station: Station) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Group {
                    if let name = station.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
                        Text(name)
                    } else {
                        Text("Unknown Name", bundle: .module, comment: "empty label text title")
                    }
                }
                .font(.title3)
                Spacer(minLength: 0)
                let br = station.bitrate ?? 0
                (Text(station.bitrate == nil ? Double.nan : Double(br), format: .number) + Text("k", bundle: .module, comment: "kilobytes suffix"))
                    .foregroundColor(br >= 256 ? Color.green : br < 128 ? Color.gray : Color.blue)
                    .font(.body.monospaced())
            }


            HStack {
                //                if let lang = station.Language, !lang.isEmpty {
                //                    (Text("Language: ") + Text(lang))
                //                }
                //                if let tags = station.Tags, !tags.isEmpty {
                //                    (Text("Tags: ") + Text(tags))
                //                }

                if let countryName = coutryLabel(for: station) {
                    Text(countryName)
                }
                Text(languageLabel(for: station))
                Spacer()

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
            .lineLimit(1)
            .allowsTightening(true)
            .truncationMode(.middle)
        }
    }
}

private extension Locale {
    /// Returns the localized name of the given language string, which by convention is the lower-case english name of the language.
    func languageName(for languageName: String) -> String {
        localeCodes[languageName].flatMap({
            self.localizedString(forLanguageCode: $0.languageCode ?? languageName)
        }) ?? languageName
    }

    func countryName(for countryName: String) -> String? {
        self.localizedString(forRegionCode: countryName)
            ?? self.localizedString(forIdentifier: countryName)
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

struct SearchToken : Identifiable {
    let id = UUID()
    let tokenType: SearchScope
    let tag: String
    let count: Int
}

@available(macOS 13.0, iOS 16.0, *)
struct SearchTokenView : View {
    @Environment(\.locale) private var locale
    let token: SearchToken

    var body: some View {
        label
    }

    var text: Text? {
        switch token.tokenType {
        case .name:
            return Text(token.tag)
        case .tag:
            return tagText(token.tag)
        case .language:
            return Text(locale.languageName(for: token.tag))
        case .country:
            return locale.countryName(for: token.tag).flatMap(Text.init)
        }
    }

    @ViewBuilder var icon: some View {
        switch token.tokenType {
        case .name:
            EmptyView()
        case .tag:
            Station.tagInfo(tagString: token.tag)?.image ?? Image(.music_note)
        case .language:
            EmptyView()
        case .country:
            Text(emojiFlag(countryCode: token.tag))
        }
    }

    var tintColor: Color? {
        switch token.tokenType {
        case .name:
            return nil
        case .tag:
            return Color(hue: token.tag.hueComponent, saturation: 0.8, brightness: 0.8)
        case .language:
            return nil
        case .country:
            return nil
        }
    }

    func tagText(_ tag: String) -> Text {
        Text(Station.tagInfo(tagString: tag)?.title ?? tag)
    }

    func countryTag(_ tag: String) -> Text {
        wip(Text(tag)) // TODO: extract tag info and localize
    }

    #if os(iOS)
    @available(macOS 13.0, iOS 16.0, *)
    var label: some View {
        @ViewBuilder func textLabel(withCounts: Bool) -> some View {
            HStack {
                Label {
                    self.text
                } icon: {
                    self.icon
                        .foregroundStyle(self.tintColor ?? .accentColor)
                }

                if withCounts {
                    Spacer()
                    Text(token.count, format: .number)
                        .font(.caption.monospacedDigit())
                }
            }
        }

        return ViewThatFits(in: .horizontal) {
            // the first view will be shown in the tag preview list; the second one without the counts will show up in the token field
            textLabel(withCounts: true).labelStyle(.titleAndIcon)
            textLabel(withCounts: false).labelStyle(.titleAndIcon)
        }
        // TODO: add the ability to swipe-to-add favorite tag/language/country
        //            .swipeActions {
        //                Button {
        //                    print("XXX")
        //                } label: {
        //                    ("XXX")
        //                }
        //            }
    }
    #else
    var label: some View {
        self.text
    }
    #endif
}


/// A local mapping of radio-browser's language name to standard language codes (https://api.radio-browser.info)
/// Note that we only use two-letter locales to avoid contradictions with longer forms of the same language.
private let localeCodes = Locale.availableIdentifiers.filter({ $0.count == 2 }).map { code in
    (Locale(identifier: "en_US").localizedString(forLanguageCode: code)?.lowercased(), Locale(identifier: code))
}
    .dictionary(keyedBy: \.0)
    .mapValues(\.1)

