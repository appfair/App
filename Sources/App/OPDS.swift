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
import Foundation
import FairCore
import struct FairCore.XMLNode

/**
 Sample of an OPDS file from https://specs.opds.io/opds-1.2#22-navigation-feeds

 ```
 <?xml version="1.0" encoding="UTF-8"?>
 <feed xmlns="http://www.w3.org/2005/Atom">
   <id>urn:uuid:2853dacf-ed79-42f5-8e8a-a7bb3d1ae6a2</id>
   <link rel="self"
         href="/opds-catalogs/root.xml"
         type="application/atom+xml;profile=opds-catalog;kind=navigation"/>
   <link rel="start"
         href="/opds-catalogs/root.xml"
         type="application/atom+xml;profile=opds-catalog;kind=navigation"/>
   <title>OPDS Catalog Root Example</title>
   <updated>2010-01-10T10:03:10Z</updated>
   <author>
     <name>Spec Writer</name>
     <uri>http://opds-spec.org</uri>
   </author>

   <entry>
     <title>Popular Publications</title>
     <link rel="http://opds-spec.org/sort/popular"
           href="/opds-catalogs/popular.xml"
           type="application/atom+xml;profile=opds-catalog;kind=acquisition"/>
     <updated>2010-01-10T10:01:01Z</updated>
     <id>urn:uuid:d49e8018-a0e0-499e-9423-7c175fa0c56e</id>
     <content type="text">Popular publications from this catalog based on downloads.</content>
   </entry>
   <entry>
     <title>New Publications</title>
     <link rel="http://opds-spec.org/sort/new"
           href="/opds-catalogs/new.xml"
           type="application/atom+xml;profile=opds-catalog;kind=acquisition"/>
     <updated>2010-01-10T10:02:00Z</updated>
     <id>urn:uuid:d49e8018-a0e0-499e-9423-7c175fa0c56c</id>
     <content type="text">Recent publications from this catalog.</content>
   </entry>
   <entry>
     <title>Unpopular Publications</title>
     <link rel="subsection"
           href="/opds-catalogs/unpopular.xml"
           type="application/atom+xml;profile=opds-catalog;kind=acquisition"/>
     <updated>2010-01-10T10:01:00Z</updated>
     <id>urn:uuid:d49e8018-a0e0-499e-9423-7c175fa0c56d</id>
     <content type="text">Publications that could use some love.</content>
   </entry>
 </feed>
 ```
 */
public struct OPDS {
    public var id: String
    public var title: String
    public var updated: Date?
    public var authors: [Author]
    public var entries: [Entry]
    public var links: [Link]

    public struct Link {
        public var rel: String
        public var href: String
        public var type: String
        public var title: String?
        /// https://specs.opds.io/opds-1.2#the-opdsfacetgroup-attribute
        public var facetGroup: String?
        /// https://specs.opds.io/opds-1.2#the-opdsactivefacet-attribute
        public var activeFacet: String?
        /// https://specs.opds.io/opds-1.2#the-thrcount-attribute
        public var expectedCount: Int?

        // var prices: [Price]
        // var indirectAcquisitions: [IndirectAcquisition]

        public struct Price {
            public var content: String
            public var currencycode: String
        }

        /// https://specs.opds.io/opds-1.2#the-opdsindirectacquisition-element
        public struct IndirectAcquisition {
            public var type: String
            public var indirectAcquisitions: [IndirectAcquisition]
        }
    }

    public struct Author {
        public var name: String
        public var uri: String
    }

    public struct Entry {
        public var id: String
        public var title: String
        public var updated: Date?
        public var authors: [Author]
        public var content: String?
        public var language: String?
        public var issued: String?
        public var categories: [Category]
        public var summaries: [Summary]
        public var links: [Link]
    }

    /**
     ```
     <category scheme="http://www.bisg.org/standards/bisac_subject/index.html"
               term="FIC020000"
               label="FICTION / Men's Adventure"/>
     ```
     */
    public struct Category {
        public var scheme: String
        public var term: String
        public var label: String
    }

    public struct Summary {
        public var content: String
        /// E.g., "text"
        public var type: String?
    }
}

extension XMLNode {
    func children(named name: String) -> [XMLNode] {
        elementChildren.filter({ $0.elementName == name })
    }
}

private let dateParser = ISO8601DateFormatter()

extension OPDS {
    /// Parses the given OPDS data.
    init(data: Data) throws {
        let node = try XMLNode.parse(data: data)

        guard let feed = node.children(named: "feed").first else {
            throw EPUBError("No feed root in OPDS document")
        }

        guard let id = feed.children(named: "id").first else {
            throw EPUBError("No id in OPDS document")
        }
        self.id = id.childContentTrimmed

        guard let title = feed.children(named: "title").first else {
            throw EPUBError("No title in OPDS document")
        }
        self.title = title.childContentTrimmed

        guard let updated = feed.children(named: "updated").first else {
            throw EPUBError("No updated in OPDS document")
        }
        self.updated = dateParser.date(from: updated.childContentTrimmed)

        let authors = feed.children(named: "author")
        self.authors = try authors.map(Author.init(node:))

        let links = feed.children(named: "link")
        self.links = try links.map(Link.init(node:))

        let entries = feed.children(named: "entry")
        self.entries = try entries.map(Entry.init(node:))
    }

    /// Link to the opensearch resource for this catalog.
    ///
    /// https://specs.opds.io/opds-1.2#3-search
    var searchLink: Link? {
        links.first { link in
            link.type == "application/opensearchdescription+xml"
        }
    }
}

extension OPDS.Author {
    init(node: XMLNode) throws {
        guard let name = node.children(named: "name").first else {
            throw EPUBError("No name in OPDS author element")
        }
        self.name = name.childContentTrimmed

        guard let uri = node.children(named: "uri").first else {
            throw EPUBError("No uri in OPDS author element")
        }
        self.uri = uri.childContentTrimmed
    }
}

extension OPDS.Entry {
    init(node: XMLNode) throws {

        guard let id = node.children(named: "id").first else {
            throw EPUBError("No id in OPDS entry element")
        }
        self.id = id.childContentTrimmed

        guard let title = node.children(named: "title").first else {
            throw EPUBError("No title in OPDS entry element")
        }
        self.title = title.childContentTrimmed

        guard let updated = node.children(named: "updated").first else {
            throw EPUBError("No updated in OPDS entry element")
        }
        self.updated = dateParser.date(from: updated.childContentTrimmed)

        self.content = node.children(named: "content").first?.childContentTrimmed

        self.language = node.children(named: "language").first?.childContentTrimmed
        self.issued = node.children(named: "issued").first?.childContentTrimmed

        self.authors = try node.children(named: "author").map(OPDS.Author.init(node:))
        self.links = try node.children(named: "link").map(OPDS.Link.init(node:))
        self.categories = try node.children(named: "category").map(OPDS.Category.init(node:))
        self.summaries = try node.children(named: "summary").map(OPDS.Summary.init(node:))
    }
}

extension OPDS.Link {
    init(node: XMLNode) throws {
        self.rel = try node.require(attribute: "rel")
        self.href = try node.require(attribute: "href")
        self.type = try node.require(attribute: "type")
        self.title = try? node.require(childNamed: "title")

        self.facetGroup = node.children(named: "facetGroup").first?.childContentTrimmed
        self.activeFacet = node.children(named: "activeFacet").first?.childContentTrimmed
        self.expectedCount = node.children(named: "expectedCount").first.map(\.childContentTrimmed).flatMap({ Int($0) })
    }
}

extension XMLNode {
    func require(attribute: String) throws -> String {
        guard let result = self[attribute: attribute] else {
            throw EPUBError("Missing attribute “\(attribute)”")
        }
        return result
    }

    func require(childNamed name: String) throws -> String {
        guard let result = children(named: name).first else {
            throw EPUBError("Missing node named “\(name)”")
        }
        return result.childContentTrimmed
    }

}

extension OPDS.Category {
    init(node: XMLNode) throws {
        self.scheme = try node.require(attribute: "scheme")
        self.term = try node.require(attribute: "term")
        self.label = try node.require(attribute: "label")
    }
}

extension OPDS.Summary {
    init(node: XMLNode) throws {
        self.type = node[attribute: "type"]
        self.content = node.childContentTrimmed
    }
}

