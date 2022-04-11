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
    open func testParseSampleBook() throws {
        guard let ebookURL = Document.bundle.url(forResource: "Alice_in_Wonderland", withExtension: "epub", subdirectory: "Bundle") else {
            return XCTFail()
        }

        let epub = try EPUB(url: ebookURL)
        XCTAssertEqual(10, epub.metadata.count)
        XCTAssertEqual(56, epub.manifest.count)
        XCTAssertEqual(14, epub.spine.count)

        XCTAssertEqual(["Lewis Carroll"], epub.metadata["creator"])

        // example of the metadata's title and the NCX's title being (slightly) different

        XCTAssertEqual("Alice's Adventures in Wonderland / Illustrated by Arthur Rackham. With a Proem by Austin Dobson", epub.title)

        XCTAssertEqual("Alice's Adventures in Wonderland\nIllustrated by Arthur Rackham. With a Proem by Austin Dobson", epub.ncx?.title)

        XCTAssertEqual(6, epub.ncx?.allPoints.array().count)
    }

    func testParseLocalBooks() throws {
        let fm = FileManager.default
        let docsFolder = try fm.url(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: false)
        let booksFolder = URL(fileURLWithPath: "Books/epub/", isDirectory: true, relativeTo: docsFolder)
        if fm.isDirectory(url: booksFolder) != true {
            throw XCTSkip("no documents folder")
        }

        for epubURL in try fm.contentsOfDirectory(at: booksFolder, includingPropertiesForKeys: nil).filter({ $0.pathExtension == "epub" }) {
            dbg("testing:", epubURL.lastPathComponent)
            let epub = try EPUB(url: epubURL)
            XCTAssertNotNil(epub.title)
            XCTAssertGreaterThan(epub.spine.count, 0)
            XCTAssertNotEqual("", epub.ncx?.title) // might be zero entries for empty TOC, but the title should always exist
        }
    }
}

