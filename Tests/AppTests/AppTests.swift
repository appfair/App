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
import FairApp
import XCTest
@testable import App

open class AppTests: XCTestCase {
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    open func testParseBook() throws {
        guard let ebookURL = Document.bundle.url(forResource: "Alice_in_Wonderland", withExtension: "epub", subdirectory: "Bundle") else {
            return XCTFail()
        }

        guard let archive = ZipArchive(url: ebookURL, accessMode: .read, preferredEncoding: .utf8) else {
            throw AppError("Could not open epub zip")
        }

        guard let mimetypeEntry = archive["mimetype"] else {
            throw AppError("No mimetype in epub zip")
        }

        let mimetypeContent = try archive.extractData(from: mimetypeEntry)
        if mimetypeContent.utf8String != "application/epub+zip" {
            throw AppError("Bad mimetype content")
        }

        guard let containerEntry = archive["META-INF/container.xml"] else {
            throw AppError("No container.xml in epub zip")
        }
        let containerContent = try archive.extractData(from: containerEntry)
        let containerXML = try XMLNode.parse(data: containerContent)

        guard let contentEntry = archive["OEBPS/content.opf"] else {
            throw AppError("No content.opf in epub zip")
        }

        for entry in archive {
            dbg("### entry:", entry.path)
        }
    }
}

