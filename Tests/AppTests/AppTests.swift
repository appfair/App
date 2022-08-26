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
        guard let ebookURL = EPUBDocument.bundle.url(forResource: "Alice_in_Wonderland", withExtension: "epub", subdirectory: "Bundle") else {
            return XCTFail()
        }

        let epub = try EPUB(url: ebookURL)
        XCTAssertEqual(8, epub.opf.metadata.count)
        XCTAssertEqual(58, epub.opf.manifest.count)
        XCTAssertEqual(13, epub.opf.spine.count)

        XCTAssertEqual(["Lewis Carroll"], epub.opf.metadata["creator"])

        // example of the metadata's title and the NCX's title being (slightly) different

        XCTAssertEqual("Alice's Adventures in Wonderland", epub.opf.title)
        XCTAssertEqual("\n\t\t\tAlice In Wonderland\n\t\t", epub.ncx?.title)

        XCTAssertEqual(12, epub.ncx?.allPoints.array().count)
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
            XCTAssertNotNil(epub.opf.title)
            XCTAssertGreaterThan(epub.opf.spine.count, 0)
            XCTAssertNotEqual("", epub.ncx?.title) // might be zero entries for empty TOC, but the title should always exist
        }
    }

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    open func testNaigationOPDS() throws {
        let opds = try OPDS(data: Bundle.module.loadBundleResource(named: "navigation-opds.xml"))

        XCTAssertEqual("urn:uuid:2853dacf-ed79-42f5-8e8a-a7bb3d1ae6a2", opds.id)
        XCTAssertEqual("OPDS Catalog Root Example", opds.title)

        XCTAssertEqual(2, opds.links.count)
        XCTAssertEqual("self", opds.links.first?.rel)
        XCTAssertEqual("/opds-catalogs/root.xml", opds.links.first?.href)
        XCTAssertEqual("application/atom+xml;profile=opds-catalog;kind=navigation", opds.links.first?.type)

        XCTAssertEqual(1, opds.authors.count)
        XCTAssertEqual("Spec Writer", opds.authors.first?.name)
        XCTAssertEqual("http://opds-spec.org", opds.authors.first?.uri)

        XCTAssertEqual(3, opds.entries.count)
        XCTAssertEqual("urn:uuid:d49e8018-a0e0-499e-9423-7c175fa0c56e", opds.entries.first?.id)
        XCTAssertEqual("Popular Publications", opds.entries.first?.title)
        XCTAssertEqual(nil, opds.entries.first?.language)
    }

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    open func testAcquisitonOPDS() throws {
        let opds = try OPDS(data: Bundle.module.loadBundleResource(named: "acquisition-opds.xml"))
        XCTAssertEqual("urn:uuid:433a5d6a-0b8c-4933-af65-4ca4f02763eb", opds.id)
        XCTAssertEqual("Unpopular Publications", opds.title)

        XCTAssertEqual(4, opds.links.count)
        XCTAssertEqual("related", opds.links.first?.rel)
        XCTAssertEqual("/opds-catalogs/vampire.farming.xml", opds.links.first?.href)
        XCTAssertEqual("application/atom+xml;profile=opds-catalog;kind=acquisition", opds.links.first?.type)

        XCTAssertEqual(1, opds.authors.count)
        XCTAssertEqual("Spec Writer", opds.authors.first?.name)
        XCTAssertEqual("http://opds-spec.org", opds.authors.first?.uri)

        XCTAssertEqual(2, opds.entries.count)
        XCTAssertEqual("urn:uuid:6409a00b-7bf2-405e-826c-3fdff0fd0734", opds.entries.first?.id)
        XCTAssertEqual("Bob, Son of Bob", opds.entries.first?.title)
        XCTAssertEqual("en", opds.entries.first?.language)
    }
}
