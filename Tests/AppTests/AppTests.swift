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
import App
import FairApp
import SwiftUI
import MiniApp

open class AppTests: XCTestCase {
    @MainActor open func testAppManager() throws {
        let store = AppContainer.AppManager()
        XCTAssertEqual(store.togglePreference, false)
        XCTAssertEqual(store.numberPreference, 0.0)

//        let cfg = AppContainer.AppManager.config
//        XCTAssertEqual("appfair/fairapp-theme", cfg["remote_theme"])
    }

    /// Creates screenshots for this app by iterating through all the facets, locales, and supported devices.
    /// When run in test cases with the default parameters, the generated screenshots will be included
    /// as metadata for the app submission.
    @MainActor open func testScreenshots() throws {
        _ = try Store().captureFacetScreens()
    }

    func testXMiniAppHost() async throws {
        let config = """
        {
          "dir": "ltr",
          "lang": "en",
          "app_id": "org.example.miniapp",
          "name": "MiniApp test",
          "pages": [
              "pages/home/home"
            ],
            "version": {
            "name": "1.0.0",
            "code": 1
          },
          "icons": [
            {
              "label": "Red lightning",
              "src": "common/icon48x48.png",
              "sizes": "48x48"
            }
          ],
          "platform_version":{
            "min_code": 1,
            "release_type": "Beta",
            "target_code": 1
          }
        }
        """

        let manifest = try MiniAppManifest.decode(from: config.utf8Data)
        XCTAssertEqual("MiniApp test", manifest.name)

        try await testMiniApp(at: "https://github.com/World-Fair/miniapp-sample/archive/refs/heads/main.zip")
    }

    func testFindMiniApps() async throws {
        // https://api.github.com/search/repositories?q=topic:world-fair-miniapp
        let json = """
        {
          "total_count": 1,
          "incomplete_results": false,
          "items": [
            {
              "id": 583537126,
              "node_id": "R_kgDOIsgR5g",
              "name": "miniapp-sample",
              "full_name": "World-Fair/miniapp-sample",
              "private": false,
              "owner": {
                "login": "World-Fair",
                "id": 115024390,
                "node_id": "O_kgDOBtsiBg",
                "avatar_url": "https://avatars.githubusercontent.com/u/115024390?v=4",
                "gravatar_id": "",
                "url": "https://api.github.com/users/World-Fair",
                "html_url": "https://github.com/World-Fair",
                "followers_url": "https://api.github.com/users/World-Fair/followers",
                "following_url": "https://api.github.com/users/World-Fair/following{/other_user}",
                "gists_url": "https://api.github.com/users/World-Fair/gists{/gist_id}",
                "starred_url": "https://api.github.com/users/World-Fair/starred{/owner}{/repo}",
                "subscriptions_url": "https://api.github.com/users/World-Fair/subscriptions",
                "organizations_url": "https://api.github.com/users/World-Fair/orgs",
                "repos_url": "https://api.github.com/users/World-Fair/repos",
                "events_url": "https://api.github.com/users/World-Fair/events{/privacy}",
                "received_events_url": "https://api.github.com/users/World-Fair/received_events",
                "type": "Organization",
                "site_admin": false
              },
              "html_url": "https://github.com/World-Fair/miniapp-sample",
              "description": "A sample mini-app for World Fair",
              "fork": false,
              "url": "https://api.github.com/repos/World-Fair/miniapp-sample",
              "forks_url": "https://api.github.com/repos/World-Fair/miniapp-sample/forks",
              "created_at": "2022-12-30T04:28:21Z",
              "updated_at": "2022-12-30T04:29:45Z",
              "pushed_at": "2022-12-30T04:29:43Z",
              "git_url": "git://github.com/World-Fair/miniapp-sample.git",
              "ssh_url": "git@github.com:World-Fair/miniapp-sample.git",
              "clone_url": "https://github.com/World-Fair/miniapp-sample.git",
              "svn_url": "https://github.com/World-Fair/miniapp-sample",
              "homepage": "",
              "size": 0,
              "stargazers_count": 1,
              "watchers_count": 1,
              "language": "JavaScript",
              "has_issues": true,
              "has_projects": true,
              "has_downloads": true,
              "has_wiki": true,
              "has_pages": false,
              "has_discussions": false,
              "forks_count": 0,
              "mirror_url": null,
              "archived": false,
              "disabled": false,
              "open_issues_count": 0,
              "license": null,
              "allow_forking": true,
              "is_template": false,
              "topics": [
                "world-fair-miniapp"
              ],
              "visibility": "public",
              "forks": 0,
              "open_issues": 0,
              "watchers": 1,
              "default_branch": "main",
              "score": 1.0
            }
          ]
        }
        """

        struct TopicQueryResult : Decodable {
            let total_count: Int
            let incomplete_results: Bool
            let items: [Item]

            struct Item : Decodable {
                let id: UInt64 // 583537126,
                let node_id: String // "R_kgDOIsgR5g",
                let name: String // "miniapp-sample",
                let full_name: String // "World-Fair/miniapp-sample",
                let `private`: Bool // false,
                let html_url: String // "https://github.com/World-Fair/miniapp-sample",
                let description: String // "A sample mini-app for World Fair",
                let fork: Bool // false,
                let url: String // "https://api.github.com/repos/World-Fair/miniapp-sample",
                let forks_url: String // "https://api.github.com/repos/World-Fair/miniapp-sample/forks",
                let created_at: Date // "2022-12-30T04:28:21Z",
                let updated_at: Date // "2022-12-30T04:29:45Z",
                let pushed_at: Date // "2022-12-30T04:29:43Z",
                let git_url: String // "git://github.com/World-Fair/miniapp-sample.git",
                let homepage: String? // "",
                let size: Int // 0,
                let stargazers_count: Int // 1,
                let watchers_count: Int // 1,
                let language: String? // "JavaScript",
                let has_issues: Bool // true,
                let has_projects: Bool // true,
                let has_downloads: Bool // true,
                let has_wiki: Bool // true,
                let has_pages: Bool // false,
                let has_discussions: Bool // false,
                let forks_count: Int // 0,
                let mirror_url: String? // null,
                let archived: Bool // false,
                let disabled: Bool // false,
                let open_issues_count: Int // 0,
                let license: String? // null,
                let allow_forking: Bool // true,
                let is_template: Bool // false,
                let topics: [String]
                let visibility: String // "public",
                let forks: Int // 0,
                let open_issues: Int // 0,
                let watchers: Int // 1,
                let default_branch: String // "main",
                let score: Double // 1.0

                let owner: Owner

                struct Owner : Codable {
                    var login: String // "World-Fair",
                    var id: UInt64 // 115024390,
                    var node_id: String // "O_kgDOBtsiBg",
                    var avatar_url: String // "https://avatars.githubusercontent.com/u/115024390?v=4",
                    var gravatar_id: String // "",
                    var url: String // "https://api.github.com/users/World-Fair",
                    var html_url: String // "https://github.com/World-Fair",
                    var type: String // "Organization",
                    var site_admin: Bool // false
                }
            }
        }

        let topics = try TopicQueryResult(json: json.utf8Data, dateDecodingStrategy: .iso8601)
    }

    func testMiniApp(at url: String) async throws {
        let url = try XCTUnwrap(URL(string: "https://github.com/World-Fair/miniapp-sample/archive/refs/heads/main.zip"))
        let (localURL, _) = try await URLSession.shared.downloadFile(for: URLRequest(url: url))
        let expandedURL = localURL.appendingPathExtension("expanded")

        try FileManager.default.unzipItem(at: localURL, to: expandedURL)
        let fsWrapper = try FileSystemDataWrapper(root: expandedURL)

        try await checkApp(fsWrapper)

        let zip = try ZipArchive(url: localURL, accessMode: .read)
        let zipWrapper = ZipArchiveDataWrapper(archive: zip)
        try await checkApp(zipWrapper)
    }

    func checkApp<DW: DataWrapper>(_ wrapper: DW) async throws {

    }
}
