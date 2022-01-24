import FairApp

/// An image that tried to load the favicon for a given page
public struct FaviconImage : View {
    public let baseURL: URL
    @State var faviconImages: [URL] = []

    public var body: some View {
        baseImage
//            .task { // crashes
//                do {
//                    try await loadPage()
//                } catch {
//                    dbg("error loading favicon from:", baseURL.absoluteURL, error)
//                }
//            }
    }

    var baseImage: some View {
        // let _ = dbg("### baseURL:", baseURL)

        // without parsing the homepage for something like `<link href="/static/img/favicon.png" rel="shortcut icon" type="image/x-icon">`, we can't know that the real favicon is, so go old-school and get the "/favicon.ico" resource (which seems to be successful for about 2/3rds of the casks)
        if let favicon = faviconImages.first {
            return URLImage(url: favicon, resizable: .fit, showProgress: false)
        } else {
            let iconURL = URL(string: "/favicon.ico", relativeTo: baseURL)
            return URLImage(url: iconURL ?? baseURL, resizable: .fit, showProgress: false)
        }
    }

    private func loadPage() async throws {
        let (pageContents, _) = try await URLSession.shared.fetch(request: URLRequest(url: baseURL, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 10.0))
        dbg("scanning for favicons in page:", baseURL.absoluteURL, pageContents.count)

        let xml = try XMLNode.parse(data: pageContents, options: .tidyHTML)
        //dbg("CHildren:", xml.elementChildren)
        guard let head = xml.elementChildren.compactMap({ $0.elementChildren.first(where: { $0.elementName.lowercased() == "head" }) }).first else {
            return dbg("no HEAD found in page")
        }

        // <link rel="apple-touch-icon" sizes="180x180" href="/resources/favicons/apple-icon-180x180.png">
        // <link rel="icon" type="image/png" sizes="96x96" href="/resources/favicons/favicon-96x96.png">

        let links = head.elementChildren.filter { node in
            node.elementName.lowercased() == "link"
                && ["icon", "apple-touch-icon"].contains(node.attributes["rel"])
        }


        dbg("links:", links.count)
        let urls = links
            .compactMap { $0.attributes["href"] }
            .compactMap { URL(string: $0, relativeTo: baseURL) }
        self.faviconImages = urls
    }
}
