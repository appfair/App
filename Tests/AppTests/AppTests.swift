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
import Swift
import XCTest
@testable import App
import FairCore

@available(macOS 12.0, iOS 15.0, *)
@MainActor final class AppTests: XCTestCase {
    func testAppScene() throws {
        // let store = AppContainer.AppStore()
        // let scene = AppContainer.rootScene(store: store)
        // let settings = AppContainer.settingsView(store: store)
        // let (_, _) = (scene, settings)
    }

    func testCaskList() async throws {
        let homeBrewInv = HomebrewInventory.default
        XCTAssertEqual(homeBrewInv.casks.count, 0)
        let (casks, response) = try await homeBrewInv.fetchCasks()
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertGreaterThan(casks.count, 1000)
    }

    func testInstalledApps() throws {
//        let homeBrewInv = CaskManager()
//        XCTAssertEqual(0, homeBrewInv.installed.count)
//        try homeBrewInv.refreshInstalledApps()
//        XCTAssertNotEqual(0, homeBrewInv.installed.count, "assuming homebrew is installed, there should have been more than one installation")
    }

    func testAppcastParsing() async throws {
        let inv = HomebrewInventory.default

        @Sendable func checkAppcast(package: String) async throws -> AppcastFeed {
            dbg("checking appcast package:", package)
            guard let (strategy, url) = try await inv.fetchLivecheck(for: package) else {
                // throw XCTestError("could not fetch livecheck on: \(package)")
                throw URLError(.badURL)
            }

            dbg("testing package:", package, url.absoluteString)

            XCTAssertTrue(strategy.hasPrefix(":sparkle")) // e.g., can also be: ":sparkle, &:short_version"
            let (contents, _) = try await URLSession.shared.fetch(request: URLRequest(url: url))
            let webFeed = try AppcastFeed(xmlData: contents)
            return webFeed
        }

        async let feeds = try (
            proxyman: checkAppcast(package: "proxyman"),
            keka: checkAppcast(package: "keka")
        )

        let keka = try await feeds.keka.channels.first
        XCTAssertEqual(keka?.title, "Keka")
        let proxyman = try await feeds.proxyman.channels.first
        XCTAssertEqual(proxyman?.title, "Proxyman")
    }

    func testRSSParsing() async throws {
        let webFeed = try AppcastFeed(xmlData: sampleRSS.utf8Data)
        guard let channel = webFeed.channels.first else {
            return XCTFail("no channels")
        }
        XCTAssertEqual("RSS Title", channel.title)
        XCTAssertEqual(nil, channel.language)
        XCTAssertEqual("http://www.example.com/main.html", channel.link)
        XCTAssertEqual("This is an example of an RSS feed", channel.description)

        guard let item = channel.items.first else {
            return XCTFail("no channel items")
        }
        XCTAssertEqual("Example entry", item.title)
        XCTAssertEqual("http://www.example.com/blog/post/1", item.link)
        XCTAssertEqual("Sun, 06 Sep 2009 16:20:00 +0000", item.pubDate)
        XCTAssertEqual("Here is some text containing an interesting description.", item.description?.trimmed()) // note indentation might be significant

        XCTAssertEqual(0, item.enclosures.count)
    }

    func testWebFeedParsing() async throws {
        let webFeed = try AppcastFeed(xmlData: sampleAppcast.utf8Data)
        guard let channel = webFeed.channels.first else {
            return XCTFail("no channels")
        }
        XCTAssertEqual("Sparkle Test App Changelog", channel.title)
        XCTAssertEqual("en", channel.language)
        XCTAssertEqual("http://sparkle-project.org/files/sparkletestcast.xml", channel.link)
        XCTAssertEqual("Most recent changes with links to updates.", channel.description)

        guard let item = channel.items.first else {
            return XCTFail("no channel items")
        }
        XCTAssertEqual("Version 2.0", item.title)
        XCTAssertEqual("2.0", item.additions?.sparkleVersion)
        XCTAssertEqual("https://sparkle-project.org", item.link)
        XCTAssertEqual("Sat, 26 Jul 2014 15:20:11 +0000", item.pubDate)
        XCTAssertEqual("""
                    <ul>
                      <li>Lorem ipsum dolor sit amet, consectetur adipiscing elit.</li>
                      <li>Suspendisse sed felis ac ante ultrices rhoncus. Etiam quis elit vel nibh placerat facilisis in id leo.</li>
                      <li>Vestibulum nec tortor odio, nec malesuada libero. Cras vel convallis nunc.</li>
                      <li>Suspendisse tristique massa eget velit consequat tincidunt. Praesent sodales hendrerit pretium.</li>
                    </ul>
        """.trimmed(), item.description?.trimmed()) // note indentation might be significant

        guard let enclosure = item.enclosures.first else {
            return XCTFail("missing enclosures")
        }

        XCTAssertEqual("https://sparkle-project.org/files/Sparkle%20Test%20App.zip", enclosure.url)
        XCTAssertEqual("107758", enclosure.length)
        XCTAssertEqual("application/octet-stream", enclosure.type)
        XCTAssertEqual("7cLALFUHSwvEJWSkV8aMreoBe4fhRa4FncC5NoThKxwThL6FDR7hTiPJh1fo2uagnPogisnQsgFgq6mGkt2RBw==", enclosure.additions?.sparkleEdSignature)
    }
}


/// https://sparkle-project.org/files/sparkletestcast.xml
let sampleAppcast = """
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"  xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>Sparkle Test App Changelog</title>
    <link>http://sparkle-project.org/files/sparkletestcast.xml</link>
    <description>Most recent changes with links to updates.</description>
    <language>en</language>
      <item>
        <title>Version 2.0</title>
        <link>https://sparkle-project.org</link>
        <sparkle:version>2.0</sparkle:version>
        <description>
          <![CDATA[
            <ul>
              <li>Lorem ipsum dolor sit amet, consectetur adipiscing elit.</li>
              <li>Suspendisse sed felis ac ante ultrices rhoncus. Etiam quis elit vel nibh placerat facilisis in id leo.</li>
              <li>Vestibulum nec tortor odio, nec malesuada libero. Cras vel convallis nunc.</li>
              <li>Suspendisse tristique massa eget velit consequat tincidunt. Praesent sodales hendrerit pretium.</li>
            </ul>
          ]]>
        </description>
        <pubDate>Sat, 26 Jul 2014 15:20:11 +0000</pubDate>
        <enclosure url="https://sparkle-project.org/files/Sparkle%20Test%20App.zip" length="107758" type="application/octet-stream" sparkle:edSignature="7cLALFUHSwvEJWSkV8aMreoBe4fhRa4FncC5NoThKxwThL6FDR7hTiPJh1fo2uagnPogisnQsgFgq6mGkt2RBw==" />
      </item>
  </channel>
</rss>
"""

/// https://en.wikipedia.org/wiki/RSS#Example
let sampleRSS = """
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
<channel>
 <title>RSS Title</title>
 <description>This is an example of an RSS feed</description>
 <link>http://www.example.com/main.html</link>
 <copyright>2020 Example.com All rights reserved</copyright>
 <lastBuildDate>Mon, 06 Sep 2010 00:01:00 +0000</lastBuildDate>
 <pubDate>Sun, 06 Sep 2009 16:20:00 +0000</pubDate>
 <ttl>1800</ttl>

 <item>
  <title>Example entry</title>
  <description>Here is some text containing an interesting description.</description>
  <link>http://www.example.com/blog/post/1</link>
  <guid isPermaLink="false">7bd204c6-1655-4c27-aeee-53f933c5395f</guid>
  <pubDate>Sun, 06 Sep 2009 16:20:00 +0000</pubDate>
 </item>

</channel>
</rss>
"""
