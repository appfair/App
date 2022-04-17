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
import FairCore
import Foundation


/// An EPUB file, which is a zip file containing book contents along with various metadata.
///
/// See: https://www.w3.org/publishing/epub3/
public final class EPUB {
    /// The underlying epub archive
    let archive: ZipArchive

    /// The metadata of the book, with keys like: `title`, `date`, `creator`, and `subject`
    public let metadata: [String: [String]]

    /// The manifest from the `content.opf` of item id to the type & href location
    public let manifest: [String: (href: String, type: String)]

    /// “The spine element defines an ordered list of manifest item references that represent the default reading order of the given Rendition.”
    /// https://www.w3.org/publishing/epub3/epub-packages.html#sec-spine-elem
    public let spine: [(idref: String, linear: Bool)]

    /// The path for the opf file
    public let opfPath: String

    /// The checksum of the OPF file, which can be used to uniquely identify a book
    public let opfChecksum: Data

    /// The title of the book, as per the metadata
    public var title: String? { metadata["title"]?.first }

    /// The creators of the book, as per the metadata
    public var creators: [String] { metadata["creators"] ?? [] }

    /// The subjects of the book, as per the metadata
    public var subjects: [String] { metadata["subjects"] ?? [] }

    /// The NXC file, if any
    public var ncx: NCX?

    /// Parses and indexes the epub file at the given URL
    /// - Parameter url: the URL of the epub zip file to load
    convenience init(url: URL) throws {
        guard let archive = ZipArchive(url: url, accessMode: .read, preferredEncoding: .utf8) else {
            throw EPUBError("Could not open epub zip")
        }
        try self.init(zip: archive)
    }

    /// Parses and indexes the epub file at the given URL
    /// - Parameter data: the Zip data to load
    convenience init(data: Data) throws {
        guard let archive = ZipArchive(data: data, accessMode: .read, preferredEncoding: .utf8) else {
            throw EPUBError("Could not open epub zip")
        }
        try self.init(zip: archive)
    }

    init(zip archive: ZipArchive) throws {
        self.archive = archive

        guard let mimetypeEntry = archive["mimetype"] else {
            throw EPUBError("No mimetype in epub zip")
        }

        let mimetypeContent = try archive.extractData(from: mimetypeEntry)
        // “The contents of the mimetype file MUST be the MIME media type [RFC2046] string application/epub+zip encoded in US-ASCII [US-ASCII].”
        // https://www.w3.org/publishing/epub3/epub-ocf.html#sec-zip-container-mime
        if mimetypeContent.utf8String != "application/epub+zip" {
            throw EPUBError("Bad mimetype content")
        }

        guard let containerEntry = archive["META-INF/container.xml"] else {
            throw EPUBError("No container.xml in epub zip")
        }

        let containerContent = try archive.extractData(from: containerEntry)
        let containerXML = try XMLNode.parse(data: containerContent)
        guard let containerNode = containerXML.elementChildren.first,
              containerNode.elementName == "container" else {
            throw EPUBError("Root element of container.xml was not 'container'")
        }

        guard let rootNode = containerNode.elementChildren.first,
              rootNode.elementName == "rootfiles" else {
            throw EPUBError("Root sub-element of container.xml was not 'rootfiles'")
        }

        // use only the first rootfile
        guard let rootFileNode = rootNode.elementChildren.first else {
            // “Although the EPUB Container provides the ability to include more than one rendition of the content, Reading System support for multiple renditions remains largely unrealized, outside specialized environments where the purpose and meaning of the renditions is established by the involved parties.”
            // https://www.w3.org/publishing/epub3/epub-ocf.html#sec-container-metainf-container.xml
            throw EPUBError("Root sub-element of container.xml did not contain a 'rootfile'")
        }

        if rootFileNode.elementName != "rootfile" || rootFileNode[attribute: "media-type"] != "application/oebps-package+xml" {
            throw EPUBError("Bad rootfile element in container.xml")
        }

        guard let fullPath = rootFileNode[attribute: "full-path"] else {
            throw EPUBError("Missing full-path in rootfile element in container.xml")
        }


        guard let packageEntry = archive[fullPath] else {
            throw EPUBError("No “\(fullPath)” entry specified in container.xml in epub zip")
        }

        let packageData = try archive.extractData(from: packageEntry)

        // the book's identifier can be derived from the checksum of the opf file
        self.opfChecksum = packageData.sha256()
        self.opfPath = fullPath

        let packageXML = try XMLNode.parse(data: packageData)
        guard let packageRoot = packageXML.elementChildren.first,
              packageRoot.elementName == "package" else {
            throw EPUBError("Root element of “\(fullPath)” was not 'package'")
        }

        guard let metadataRoot = packageRoot.elementChildren.first(where: { $0.elementName == "metadata" }) else {
            throw EPUBError("Package at “\(fullPath)” had no 'metadata' element")
        }

        // e.g.: `<dc:creator opf:file-as="Carroll, Lewis">Lewis Carroll</dc:creator>`
        // Alice in Wonderland:
        // `["source": ["https://www.gutenberg.org/files/28885/28885-h/28885-h.htm"], "title": ["Alice's Adventures in Wonderland / Illustrated by Arthur Rackham. With a Proem by Austin Dobson"], "identifier": ["http://www.gutenberg.org/28885"], "date": ["2009-05-19", "2022-03-13T11:43:02.739791+00:00"], "contributor": ["Austin Dobson", "Arthur Rackham"], "creator": ["Lewis Carroll"], "subject": ["Fantasy fiction", "Children's stories", "Imaginary places -- Juvenile fiction", "Alice (Fictitious character from Carroll) -- Juvenile fiction"], "language": ["en"], "meta": [], "rights": ["Public domain in the USA."]]`
        var metadataMap: [String: [String]] = [:]
        for metadataElement in metadataRoot.elementChildren {
            metadataMap[metadataElement.elementName, default: []].append(contentsOf: metadataElement.childContent)
        }
        self.metadata = metadataMap

        guard let manifestRoot = packageRoot.elementChildren.first(where: { $0.elementName == "manifest" }) else {
            throw EPUBError("Package at “\(fullPath)” had no 'manifest' element")
        }

        var manifestMap: [String: (href: String, type: String)] = [:]
        for item in manifestRoot.elementChildren.filter({ $0.elementName == "item" }) {
            if let id = item[attribute: "id"],
               let href = item[attribute: "href"],
               let type = item[attribute: "media-type"] {
                manifestMap[id] = (href: href, type: type)
            }
        }

        self.manifest = manifestMap

        // “The spine element defines an ordered list of manifest item references that represent the default reading order of the given Rendition.”
        // https://www.w3.org/publishing/epub3/epub-packages.html#sec-pkg-spine
        guard let spineRoot = packageRoot.elementChildren.first(where: { $0.elementName == "spine" }) else {
            throw EPUBError("Package at “\(fullPath)” had no 'spine' element")
        }

        var spineElements: [(idref: String, linear: Bool)] = []
        for spineElement in spineRoot.elementChildren {
            guard let idref = spineElement[attribute: "idref"] else {
                throw EPUBError("Spine element had no 'idref' attribute")
            }
            let linear = spineElement[attribute: "linear"] == "no" ? false : true
            spineElements.append((idref: idref, linear: linear))
        }
        self.spine = spineElements


        if let tocid = spineRoot[attribute: "toc"],
            let ncx = manifest[tocid],
            ncx.type == "application/x-dtbncx+xml",
            let ncxEntry = archive[resolveRelative(path: ncx.href)] {
            let ncxContent = try archive.extractData(from: ncxEntry)
            self.ncx = try NCX(data: ncxContent)
        }

        // dbg("opened zip with spine:", self.spine)
        
        /// “The guide element [OPF2] is a legacy feature that previously provided machine-processable navigation to key structures in an EPUB Publication. It is replaced in EPUB 3 by landmarks in the EPUB Navigation Document.”
//        guard let guideRoot = packageRoot.elementChildren.first(where: { $0.elementName == "guide" }) else {
//            throw EPUBError("Package at “\(fullPath)” had no 'guide' element")
//        }
    }

    /// Resolves the given path relative to the OPF
    func resolveRelative(path: String) -> String {
        // remove slashes from either end of the given string
        let ts = { (str: String) in str.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }

        // entries are resolved relative to the OPF file
        let opfRoot = ts(URL(fileURLWithPath: "/" + self.opfPath).deletingLastPathComponent().path)

        return !opfRoot.isEmpty ? (opfRoot + "/" + path) : path
    }

    func extractContents(to folder: URL? = nil) throws -> URL {
        guard let cacheFolder = folder ??
                FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("Books") else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let checksum = try (archive.data ?? Data(contentsOf: archive.url, options: .alwaysMapped)).sha256().hex()

        let extractFolder = cacheFolder
            //            .appendingPathComponent(self.title?.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "untitled")
            .appendingPathComponent(checksum)

        try FileManager.default.createDirectory(at: extractFolder, withIntermediateDirectories: true)

        for entry in self.archive {

            let dest = extractFolder
                .appendingPathComponent(entry.path)

            //dbg("path:", entry.path, "size:", entry.uncompressedSize, "dest size:", dest.fileSize())
            // only extract the file if it doesn't exist or is a different size
            if (dest.fileSize() ?? -1) != entry.uncompressedSize {
                dbg("extracting to:", (dest.path as NSString), "from:", (entry.path as NSString))
                let _ = try self.archive.extract(entry, to: dest, overwrite: true, skipCRC32: true)
            }
        }

        return extractFolder
    }
}

public struct NCX {
    let title: String
    let points: [NavPoint]

    public init(data: Data) throws {
        let node = try XMLNode.parse(data: data)

        guard let ncx = node.elementChildren.first(where: { $0.elementName == "ncx" }) else {
            throw EPUBError("No ncx root in node")
        }

        guard let docTitle = ncx.elementChildren.first(where: { $0.elementName == "docTitle" }),
            let docText = docTitle.elementChildren.first(where: { $0.elementName == "text" }) else {
            throw EPUBError("No docTitle in node")
        }

        self.title = docText.childContent.joined()

        guard let navMap = ncx.elementChildren.first(where: { $0.elementName == "navMap" }) else {
            throw EPUBError("No navMap node in ncx")
        }

        var points: [NavPoint] = []
        for childPoint in navMap.elementChildren.filter({ $0.elementName == "navPoint" }) {
            points.append(try NavPoint(node: childPoint))
        }
        self.points = points
    }

    public var allPoints: AnyIterator<NavPoint> {
        points.depthFirstIterator(children: \.points)
    }

    /// Search through the navPoints for the given id
    func findHref(forNavPoint id: String) -> String? {
        guard let navPoint = allPoints.first(where: { $0.id == id }) else {
            return nil
        }
        return navPoint.content
    }

    public struct NavPoint {
        let className: String?
        let id: String?
        let playOrder: Int?
        let navLabel: String?
        let content: String?
        /// Nested nav points
        let points: [NavPoint]

        // TODO: support pageList/pageTarget

        init(node: FairCore.XMLNode) throws {
            self.className = node[attribute: "class"]
            self.id = node[attribute: "id"]
            self.playOrder = node[attribute: "playOrder"].flatMap(Int.init)
            if let navLabel = node.elementChildren.first(where: { $0.elementName == "navLabel" }),
               let navLabelText = navLabel.elementChildren.first(where: { $0.elementName == "text" })
            {
                self.navLabel = navLabelText.childContent.first
            } else {
                self.navLabel = nil
            }

            if let content = node.elementChildren.first(where: { $0.elementName == "content" }) {
                self.content = content[attribute: "src"]
            } else {
                self.content = nil
            }

            var points: [NavPoint] = []
            for childPoint in node.elementChildren.filter({ $0.elementName == "navPoint" }) {
                points.append(try NavPoint(node: childPoint))
            }
            self.points = points
        }
    }
}

extension NCX {
    /// The flattened table of contents, which included an index path for each `navPoint`
    public var toc: AnySequence<(indices: [Int], element: NavPoint)> {
        Tree.enumerated(self.points, traverse: .depthFirst, children: \.points)
    }
}

public struct EPUBError : LocalizedError {
    /// A localized message describing what error occurred.
    public let errorDescription: String?

    /// A localized message describing the reason for the failure.
    public let failureReason: String?

    /// A localized message describing how one might recover from the failure.
    public let recoverySuggestion: String?

    /// A localized message providing "help" text if the user requests help.
    public let helpAnchor: String?

    /// An underlying error
    public let underlyingError: Error?

    public init(_ errorDescription: String, failureReason: String? = nil, recoverySuggestion: String? = nil, helpAnchor: String? = nil, underlyingError: Error? = nil) {
        self.errorDescription = errorDescription
        self.failureReason = failureReason
        self.recoverySuggestion = recoverySuggestion
        self.helpAnchor = helpAnchor
        self.underlyingError = underlyingError
    }

}

