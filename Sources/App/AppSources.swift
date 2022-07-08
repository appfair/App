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

/// User-facing information about a source of apps.
protocol AppSourceInfo {
    /// The label that summarizes this source, which will appear in the sidebar of the app
    func tintedLabel(monochrome: Bool) -> TintedLabel

    /// Subtitle text for this source
    var fullTitle: Text { get }

    /// A textual description of this source
    var overviewText: Text? { get }

    /// Footer text for this source
    var footerText: Text? { get }

    /// A list of the features of this source, which will be laid in order
    var featureInfo: [(FairSymbol, Text)] { get }
}

extension SidebarSelection {

    var sourceInfo: AppSourceInfo {
        switch self.source {
        case .fairapps:
            switch self.item {
            case .top:
                return FairappsSourceInfo.TopAppInfo()
            case .recent:
                return FairappsSourceInfo.RecentAppInfo()
            case .installed:
                return FairappsSourceInfo.InstalledAppInfo()
            case .updated:
                return FairappsSourceInfo.UpdatedAppInfo()
            case .category(let category):
                return CategoryAppInfo(category: category)
            }
        case .homebrew:
            switch self.item {
            case .top:
                return HomebrewSourceInfo.TopAppInfo()
            case .recent:
                return HomebrewSourceInfo.RecentAppInfo()
            case .installed:
                return HomebrewSourceInfo.InstalledAppInfo()
            case .updated:
                return HomebrewSourceInfo.UpdatedAppInfo()
            case .category(let category):
                return CategoryAppInfo(category: category)
            }
        }
    }

    private enum HomebrewSourceInfo {
        struct TopAppInfo : AppSourceInfo {
            func tintedLabel(monochrome: Bool) -> TintedLabel {
                TintedLabel(title: Text("Apps", bundle: .module, comment: "homebrew sidebar category title"), symbol: AppSource.homebrew.symbol, tint: monochrome ? nil : Color.yellow, mode: monochrome ? .monochrome : .hierarchical)
            }

            /// Subtitle text for this source
            var fullTitle: Text {
                Text("Homebrew Casks", bundle: .module, comment: "homebrew top apps info: full title")
            }

            /// A textual description of this source
            var overviewText: Text? {
                Text("""
                The Homebrew project is a community-maintained index of thousands of macOS apps, both free and commercial. *App Fair.app* manages the installation and updating of these apps directly from the creator's site using the `brew` package management tool.

                Apps installed from the Homebrew catalog are not subject to any sort of review process, so you should only install apps from known and trusted sources. Homebrew apps may or may not be sandboxed, meaning they could have unmediated access to files and the device & network resources of the host machine.
                """, bundle: .module, comment: "homebrew top apps info: overview text")
            }

            var footerText: Text? {
                Text("Learn more about the Homebrew community at [https://brew.sh](https://brew.sh)", bundle: .module, comment: "homebrew top apps info: footer link text")
            }

            /// A list of the features of this source, which will be laid in order
            var featureInfo: [(FairSymbol, Text)] {
                []
            }
        }

        struct RecentAppInfo : AppSourceInfo {
            func tintedLabel(monochrome: Bool) -> TintedLabel {
                TintedLabel(title: Text("Recent", bundle: .module, comment: "homebrew sidebar category title"), symbol: .clock, tint: monochrome ? nil : Color.green, mode: monochrome ? .monochrome : .hierarchical)
            }

            /// Subtitle text for this source
            var fullTitle: Text {
                Text("Homebrew Apps: Recent", bundle: .module, comment: "homebrew recent apps info: full title")
            }

            /// A textual description of this source
            var overviewText: Text? {
                nil
                // Text(wip("XXX"), bundle: .module, comment: "homebrew recent apps info: overview text")
            }

            var footerText: Text? {
                nil
                // Text(wip("XXX"), bundle: .module, comment: "homebrew recent apps info: overview text")
            }

            /// A list of the features of this source, which will be laid in order
            var featureInfo: [(FairSymbol, Text)] {
                []
            }
        }

        struct InstalledAppInfo : AppSourceInfo {
            func tintedLabel(monochrome: Bool) -> TintedLabel {
                TintedLabel(title: Text("Installed", bundle: .module, comment: "homebrew sidebar category title"), symbol: .internaldrive, tint: monochrome ? nil : Color.orange, mode: monochrome ? .monochrome : .hierarchical)
            }

            /// Subtitle text for this source
            var fullTitle: Text {
                Text("Homebrew Apps: Installed", bundle: .module, comment: "homebrew installed apps info: full title")
            }

            /// A textual description of this source
            var overviewText: Text? {
                nil
                // Text(wip("XXX"), bundle: .module, comment: "homebrew installed apps info: overview text")
            }

            var footerText: Text? {
                nil
                // Text(wip("XXX"), bundle: .module, comment: "homebrew recent apps info: overview text")
            }

            /// A list of the features of this source, which will be laid in order
            var featureInfo: [(FairSymbol, Text)] {
                []
            }
        }

        struct UpdatedAppInfo : AppSourceInfo {
            func tintedLabel(monochrome: Bool) -> TintedLabel {
                TintedLabel(title: Text("Updated", bundle: .module, comment: "homebrew sidebar category title"), symbol: .arrow_down_app, tint: monochrome ? nil : Color.green, mode: monochrome ? .monochrome : .hierarchical)
            }

            /// Subtitle text for this source
            var fullTitle: Text {
                Text("Homebrew Apps: Updated", bundle: .module, comment: "homebrew updated apps info: full title")
            }

            /// A textual description of this source
            var overviewText: Text? {
                nil
                // Text(wip("XXX"), bundle: .module, comment: "homebrew updated apps info: overview text")
            }

            var footerText: Text? {
                nil
                // Text(wip("XXX"), bundle: .module, comment: "homebrew recent apps info: overview text")
            }

            /// A list of the features of this source, which will be laid in order
            var featureInfo: [(FairSymbol, Text)] {
                []
            }
        }
    }

    private enum FairappsSourceInfo {
        struct TopAppInfo : AppSourceInfo {
            func tintedLabel(monochrome: Bool) -> TintedLabel {
                TintedLabel(title: Text("Apps", bundle: .module, comment: "fairapps sidebar category title"), symbol: AppSource.fairapps.symbol, tint: monochrome ? nil : Color.accentColor, mode: monochrome ? .monochrome : .multicolor)
            }

            /// Subtitle text for this source
            var fullTitle: Text {
                Text("Fairground Apps", bundle: .module, comment: "fairapps top apps info: full title")
            }

            /// A textual description of this source
            var overviewText: Text? {
                Text("""
                Fairground apps are created through the appfair.net process. They are 100% open-source and disclose all their permissions in their App Fair catalog entry.

                Apps installed from the Fairground catalog are guaranteed to run in a sandbox, meaning that access to resources like the filesystem, network, and devices are mediated through a security layer that mandates that their permissions be documented, disclosed, and approved by the user. Fairground apps publish a “risk level” summarizing the number of permission categories the app requests.
                """, bundle: .module, comment: "fairapps top apps info: overview text")
            }

            var footerText: Text? {
                Text("Learn more about the fairground process at [https://appfair.net](https://appfair.net)", bundle: .module, comment: "fairground top apps info: footer link text")
            }

            /// A list of the features of this source, which will be laid in order
            var featureInfo: [(FairSymbol, Text)] {
                []
            }
        }

        struct RecentAppInfo : AppSourceInfo {
            func tintedLabel(monochrome: Bool) -> TintedLabel {
                TintedLabel(title: Text("Recent", bundle: .module, comment: "fairapps sidebar category title"), symbol: .clock_fill, tint: monochrome ? nil : Color.yellow, mode: monochrome ? .monochrome : .multicolor)
            }

            /// Subtitle text for this source
            var fullTitle: Text {
                Text("Fairground Apps: Recent", bundle: .module, comment: "fairapps recent apps info: full title")
            }

            /// A textual description of this source
            var overviewText: Text? {
                nil
                // Text(wip("XXX"), bundle: .module, comment: "fairapps recent apps info: overview text")
            }

            var footerText: Text? {
                nil
                // Text(wip("XXX"), bundle: .module, comment: "homebrew recent apps info: overview text")
            }

            /// A list of the features of this source, which will be laid in order
            var featureInfo: [(FairSymbol, Text)] {
                []
            }
        }

        struct InstalledAppInfo : AppSourceInfo {
            func tintedLabel(monochrome: Bool) -> TintedLabel {
                TintedLabel(title: Text("Installed", bundle: .module, comment: "fairapps sidebar category title"), symbol: .externaldrive_fill, tint: monochrome ? nil : Color.orange, mode: monochrome ? .monochrome : .multicolor)
            }

            /// Subtitle text for this source
            var fullTitle: Text {
                Text("Fairground Apps: Installed", bundle: .module, comment: "fairapps installed apps info: full title")
            }

            /// A textual description of this source
            var overviewText: Text? {
                nil
                // Text(wip("XXX"), bundle: .module, comment: "fairapps installed apps info: overview text")
            }

            var footerText: Text? {
                nil
                // Text(wip("XXX"), bundle: .module, comment: "homebrew recent apps info: overview text")
            }

            /// A list of the features of this source, which will be laid in order
            var featureInfo: [(FairSymbol, Text)] {
                []
            }
        }

        struct UpdatedAppInfo : AppSourceInfo {
            func tintedLabel(monochrome: Bool) -> TintedLabel {
                TintedLabel(title: Text("Updated", bundle: .module, comment: "fairapps sidebar category title"), symbol: .arrow_down_app_fill, tint: monochrome ? nil : Color.green, mode: monochrome ? .monochrome : .multicolor)
            }

            /// Subtitle text for this source
            var fullTitle: Text {
                Text("Fairground Apps: Updated", bundle: .module, comment: "fairapps updated apps info: full title")
            }

            /// A textual description of this source
            var overviewText: Text? {
                nil
                // Text(wip("XXX"), bundle: .module, comment: "fairapps updated apps info: overview text")
            }

            var footerText: Text? {
                nil
                // Text(wip("XXX"), bundle: .module, comment: "homebrew recent apps info: overview text")
            }

            /// A list of the features of this source, which will be laid in order
            var featureInfo: [(FairSymbol, Text)] {
                []
            }
        }
    }

    struct CategoryAppInfo : AppSourceInfo {
        let category: AppCategory

        func tintedLabel(monochrome: Bool) -> TintedLabel {
            category.tintedLabel(monochrome: monochrome)
        }

        /// Subtitle text for this source
        var fullTitle: Text {
            Text("Category: \(category.text)", bundle: .module, comment: "app category info: title pattern")
        }

        /// A textual description of this source
        var overviewText: Text? {
            nil
            // Text(wip("XXX"), bundle: .module, comment: "app category info: overview text")
        }

        var footerText: Text? {
            nil
            // Text(wip("XXX"), bundle: .module, comment: "homebrew recent apps info: overview text")
        }

        /// A list of the features of this source, which will be laid in order
        var featureInfo: [(FairSymbol, Text)] {
            []
        }
    }

}

public extension AppCategory {
    /// The description of an app category.
    /// TODO: add in an extended description tuple
    @available(macOS 12.0, iOS 15.0, *)
    var text: Text {
        switch self {
        case .business:
            return Text("Business", bundle: .module, comment: "app category label for appfair.business")
        case .developertools:
            return Text("Developer Tools", bundle: .module, comment: "app category label for appfair.developer-tools")
        case .education:
            return Text("Education", bundle: .module, comment: "app category label for appfair.education")
        case .entertainment:
            return Text("Entertainment", bundle: .module, comment: "app category label for appfair.entertainment")
        case .finance:
            return Text("Finance", bundle: .module, comment: "app category label for appfair.finance")
        case .graphicsdesign:
            return Text("Graphics Design", bundle: .module, comment: "app category label for appfair.graphics-design")
        case .healthcarefitness:
            return Text("Healthcare & Fitness", bundle: .module, comment: "app category label for appfair.healthcare-fitness")
        case .lifestyle:
            return Text("Lifestyle", bundle: .module, comment: "app category label for appfair.lifestyle")
        case .medical:
            return Text("Medical", bundle: .module, comment: "app category label for appfair.medical")
        case .music:
            return Text("Music", bundle: .module, comment: "app category label for appfair.music")
        case .news:
            return Text("News", bundle: .module, comment: "app category label for appfair.news")
        case .photography:
            return Text("Photography", bundle: .module, comment: "app category label for appfair.photography")
        case .productivity:
            return Text("Productivity", bundle: .module, comment: "app category label for appfair.productivity")
        case .reference:
            return Text("Reference", bundle: .module, comment: "app category label for appfair.reference")
        case .socialnetworking:
            return Text("Social Networking", bundle: .module, comment: "app category label for appfair.social-networking")
        case .sports:
            return Text("Sports", bundle: .module, comment: "app category label for appfair.sports")
        case .travel:
            return Text("Travel", bundle: .module, comment: "app category label for appfair.travel")
        case .utilities:
            return Text("Utilities", bundle: .module, comment: "app category label for appfair.utilities")
        case .video:
            return Text("Video", bundle: .module, comment: "app category label for appfair.video")
        case .weather:
            return Text("Weather", bundle: .module, comment: "app category label for appfair.weather")

        case .games:
            return Text("Games", bundle: .module, comment: "app category label for appfair.games")
        case .actiongames:
            return Text("Action Games", bundle: .module, comment: "app category label for appfair.action-games")
        case .adventuregames:
            return Text("Adventure Games", bundle: .module, comment: "app category label for appfair.adventure-games")
        case .arcadegames:
            return Text("Arcade Games", bundle: .module, comment: "app category label for appfair.arcade-games")
        case .boardgames:
            return Text("Board Games", bundle: .module, comment: "app category label for appfair.board-games")
        case .cardgames:
            return Text("Card Games", bundle: .module, comment: "app category label for appfair.card-games")
        case .casinogames:
            return Text("Casino Games", bundle: .module, comment: "app category label for appfair.casino-games")
        case .dicegames:
            return Text("Dice Games", bundle: .module, comment: "app category label for appfair.dice-games")
        case .educationalgames:
            return Text("Educational Games", bundle: .module, comment: "app category label for appfair.educational-games")
        case .familygames:
            return Text("Family Games", bundle: .module, comment: "app category label for appfair.family-games")
        case .kidsgames:
            return Text("Kids Games", bundle: .module, comment: "app category label for appfair.kids-games")
        case .musicgames:
            return Text("Music Games", bundle: .module, comment: "app category label for appfair.music-games")
        case .puzzlegames:
            return Text("Puzzle Games", bundle: .module, comment: "app category label for appfair.puzzle-games")
        case .racinggames:
            return Text("Racing Games", bundle: .module, comment: "app category label for appfair.racing-games")
        case .roleplayinggames:
            return Text("Role Playing Games", bundle: .module, comment: "app category label for appfair.role-playing-games")
        case .simulationgames:
            return Text("Simulation Games", bundle: .module, comment: "app category label for appfair.simulation-games")
        case .sportsgames:
            return Text("Sports Games", bundle: .module, comment: "app category label for appfair.sports-games")
        case .strategygames:
            return Text("Strategy Games", bundle: .module, comment: "app category label for appfair.strategy-games")
        case .triviagames:
            return Text("Trivia Games", bundle: .module, comment: "app category label for appfair.trivia-games")
        case .wordgames:
            return Text("Word Games", bundle: .module, comment: "app category label for appfair.word-games")
        }
    }

    @available(macOS 12.0, iOS 15.0, *)
    var symbol: FairSymbol {
        switch self {
        case .business:
            return .building_2
        case .developertools:
            return .keyboard
        case .education:
            return .graduationcap
        case .entertainment:
            return .tv
        case .finance:
            return .diamond
        case .graphicsdesign:
            return .paintpalette
        case .healthcarefitness:
            return .figure_walk
        case .lifestyle:
            return .suitcase
        case .medical:
            return .cross_case
        case .music:
            return .radio
        case .news:
            return .newspaper
        case .photography:
            return .camera
        case .productivity:
            return .puzzlepiece
        case .reference:
            return .books_vertical
        case .socialnetworking:
            return .person_3
        case .sports:
            return .rosette
        case .travel:
            return .suitcase
        case .utilities:
            return .crown
        case .video:
            return .film
        case .weather:
            return .cloud

        case .games:
            return .gamecontroller

        case .actiongames:
            return .gamecontroller
        case .adventuregames:
            return .gamecontroller
        case .arcadegames:
            return .gamecontroller
        case .boardgames:
            return .gamecontroller
        case .cardgames:
            return .gamecontroller
        case .casinogames:
            return .gamecontroller
        case .dicegames:
            return .gamecontroller
        case .educationalgames:
            return .gamecontroller
        case .familygames:
            return .gamecontroller
        case .kidsgames:
            return .gamecontroller
        case .musicgames:
            return .gamecontroller
        case .puzzlegames:
            return .gamecontroller
        case .racinggames:
            return .gamecontroller
        case .roleplayinggames:
            return .gamecontroller
        case .simulationgames:
            return .gamecontroller
        case .sportsgames:
            return .gamecontroller
        case .strategygames:
            return .gamecontroller
        case .triviagames:
            return .gamecontroller
        case .wordgames:
            return .gamecontroller
        }
    }

    var tint: Color {
        switch self {
        case .business:
            return Color.green
        case .developertools:
            return Color.orange
        case .education:
            return Color.blue
        case .entertainment:
            return Color.purple
        case .finance:
            return Color.green
        case .graphicsdesign:
            return Color.teal
        case .healthcarefitness:
            return Color.mint
        case .lifestyle:
            return Color.orange
        case .medical:
            return Color.white
        case .music:
            return Color.yellow
        case .news:
            return Color.brown
        case .photography:
            return Color.pink
        case .productivity:
            return Color.cyan
        case .reference:
            return Color.gray
        case .socialnetworking:
            return Color.yellow
        case .sports:
            return Color.teal
        case .travel:
            return Color.indigo
        case .utilities:
            return Color.purple
        case .video:
            return Color.yellow
        case .weather:
            return Color.blue
        case .games:
            return Color.red
        case .actiongames:
            return Color.red
        case .adventuregames:
            return Color.red
        case .arcadegames:
            return Color.red
        case .boardgames:
            return Color.red
        case .cardgames:
            return Color.red
        case .casinogames:
            return Color.red
        case .dicegames:
            return Color.red
        case .educationalgames:
            return Color.red
        case .familygames:
            return Color.red
        case .kidsgames:
            return Color.red
        case .musicgames:
            return Color.red
        case .puzzlegames:
            return Color.red
        case .racinggames:
            return Color.red
        case .roleplayinggames:
            return Color.red
        case .simulationgames:
            return Color.red
        case .sportsgames:
            return Color.red
        case .strategygames:
            return Color.red
        case .triviagames:
            return Color.red
        case .wordgames:
            return Color.red
        }
    }

    /// Returns the parent category of this category, or nil
    /// if it is a root category.
    ///
    /// E.g., the parent category of ``boardgames`` is ``games``.
    var parentCategory: AppCategory? {
        switch self {
        case .business: return nil
        case .developertools: return nil
        case .education: return nil
        case .entertainment: return nil
        case .finance: return nil
        case .graphicsdesign: return nil
        case .healthcarefitness: return nil
        case .lifestyle: return nil
        case .medical: return nil
        case .music: return nil
        case .news: return nil
        case .photography: return nil
        case .productivity: return nil
        case .reference: return nil
        case .socialnetworking: return nil
        case .sports: return nil
        case .travel: return nil
        case .utilities: return nil
        case .video: return nil
        case .weather: return nil

        case .games: return nil

        case .actiongames: return .games
        case .adventuregames: return .games
        case .arcadegames: return .games
        case .boardgames: return .games
        case .cardgames: return .games
        case .casinogames: return .games
        case .dicegames: return .games
        case .educationalgames: return .games
        case .familygames: return .games
        case .kidsgames: return .games
        case .musicgames: return .games
        case .puzzlegames: return .games
        case .racinggames: return .games
        case .roleplayinggames: return .games
        case .simulationgames: return .games
        case .sportsgames: return .games
        case .strategygames: return .games
        case .triviagames: return .games
        case .wordgames: return .games
        }
    }

    func tintedLabel(monochrome: Bool) -> TintedLabel {
        TintedLabel(title: text, symbol: symbol, tint: monochrome ? nil : tint, mode: monochrome ? .monochrome : nil)
    }
}
