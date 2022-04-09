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

class EPubFile {
    let archive: ZipArchive

    /// Parses and indexes the epub file at the given URL
    /// - Parameter url: the URL of the epub zip file to load
    init(url: URL) throws {
        guard let archive = ZipArchive(url: url, accessMode: .read, preferredEncoding: .utf8) else {
            throw AppError("Could not open epub zip")
        }

        self.archive = archive
        
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
        guard let containerNode = containerXML.elementChildren.first,
              containerNode.elementName == "container" else {
            throw AppError("Root element of container.xml was not 'container'")
        }

        guard let rootNode = containerNode.elementChildren.first,
              rootNode.elementName == "rootfiles" else {
            throw AppError("Root sub-element of container.xml was not 'rootfiles'")
        }

        for rootFileNode in rootNode.elementChildren {
            if rootFileNode.elementName != "rootfile" || rootFileNode[attribute: "media-type"] != "application/oebps-package+xml" {
                throw AppError("Bad rootfile element in container.xml")
            }

            guard let fullPath = rootFileNode[attribute: "full-path"] else {
                throw AppError("Midding full-path in rootfile element in container.xml")
            }

            guard let packageEntry = archive[fullPath] else {
                throw AppError("No “\(fullPath)” entry specified in container.xml in epub zip")
            }

            let packageXML = try XMLNode.parse(data: archive.extractData(from: packageEntry))
            guard let packageRoot = packageXML.elementChildren.first,
                  packageRoot.elementName == "package" else {
                throw AppError("Root element of “\(fullPath)” was not 'package'")
            }

            guard let metadataRoot = packageRoot.elementChildren.first(where: { $0.elementName == "metadata" }) else {
                throw AppError("Package at “\(fullPath)” had no 'metadata' element")
            }

            guard let manifestRoot = packageRoot.elementChildren.first(where: { $0.elementName == "manifest" }) else {
                throw AppError("Package at “\(fullPath)” had no 'manifest' element")
            }

            var itemMap: [String: (href: String, type: String)] = [:]
            for itemElement in manifestRoot.elementChildren.filter({ $0.elementName == "item" }) {
                if let id = itemElement[attribute: "id"],
                   let href = itemElement[attribute: "href"],
                   let type = itemElement[attribute: "media-type"] {
                    itemMap[id] = (href: href, type: type)
                }
            }

            dbg("### itemMap:", itemMap)
            
            guard let spineRoot = packageRoot.elementChildren.first(where: { $0.elementName == "spine" }) else {
                throw AppError("Package at “\(fullPath)” had no 'spine' element")
            }

            guard let guideRoot = packageRoot.elementChildren.first(where: { $0.elementName == "guide" }) else {
                throw AppError("Package at “\(fullPath)” had no 'guide' element")
            }

            for entry in archive {
                dbg("### entry:", entry.path)
            }

        }


    }
}


open class AppTests: XCTestCase {
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    open func testParseBook() throws {
        guard let ebookURL = Document.bundle.url(forResource: "Alice_in_Wonderland", withExtension: "epub", subdirectory: "Bundle") else {
            return XCTFail()
        }

        let epub = try EPubFile(url: ebookURL)

    }
}

