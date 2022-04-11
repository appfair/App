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
import UniformTypeIdentifiers
import WebKit

@available(macOS 12.0, iOS 15.0, *)
public struct EPUBView: View {
    @ObservedObject var document: Document
    @ObservedObject var webViewState: WebViewState
    @EnvironmentObject var store: Store
    @Namespace var mainNamespace
    @State var animationTime: TimeInterval = 0
    @State var searchString = ""
    @SceneStorage("pageScale") var pageScale: Double = 1.0
    //@SceneStorage("pageScaleSet") var pageScaleSet: Bool = false

    public var body: some View {
        webViewBody()
            .onChange(of: webViewState.webView?.pageZoom) { zoom in
                dbg("change page zoom:", zoom)
                if let zoom = zoom, self.pageScale != zoom {
                    // FIXME: not getting persisted for some reason
                    self.pageScale = zoom
                }
            }
            .onAppear {
                dbg("init self.pageScale:", self.pageScale)
                webViewState.webView?.pageZoom = self.pageScale
            }
            .toolbar(id: "EPUBToolbar") {
                ToolbarItem(id: "ZoomOutCommand", placement: .automatic, showsByDefault: true) {
                    webViewState.zoomAction(amount: 0.8)
                }
                ToolbarItem(id: "ZoomInCommand", placement: .automatic, showsByDefault: true) {
                    webViewState.zoomAction(amount: 1.2)
                }
            }
    }

    public func webViewBody() -> some View {
        WebView(state: webViewState)
    }
}

/// The shared app environment
@MainActor public final class Store: SceneManager {
    @AppStorage("someToggle") public var someToggle = false
    @AppStorage("defaultPageScale") public var defaultPageScale = 2.0
}

public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        EBookScene()
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store: Store) -> some SwiftUI.View {
        AppSettingsView().environmentObject(store)
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct EBookScene : Scene {

    var body: some Scene {
        DocumentGroup(viewing: Document.self, viewer: documentHostView)
            .commands { EBookCommands() }
    }

    func documentHostView(file: ReferenceFileDocumentConfiguration<Document>) -> some View {
        let doc: Document = file.document
        let epub = doc.epub

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = false
        prefs.preferredContentMode = .mobile

        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = prefs
        config.suppressesIncrementalRendering = true
        config.limitsNavigationsToAppBoundDomains = true

        config.setURLSchemeHandler(EPUBSchemeHandler(epub: epub), forURLScheme: "epub")

        let controller = WKUserContentController()

        config.userContentController = controller

        let webViewState = WebViewState(initialRequest: nil, configuration: config)

        return EPubContainerView(document: doc, webViewState: webViewState)
            .focusedSceneValue(\.document, file.document)
            .focusedSceneValue(\.webViewState, webViewState)
    }
}

struct EPubContainerView : View {
    @ObservedObject var document: Document
    @ObservedObject var webViewState: WebViewState

    @SceneStorage("selectedChapter") var selection: String = ""

    /// Conversion from SceneStorage (which cannot take an optional) to the double-optional required by the list selection
    private var selectionBinding: Binding<String??> {
        Binding {
            selection == "" ? nil : selection // blank converts to nil selection
        } set: { newValue in
            self.selection = (newValue ?? "") ?? ""
        }
    }

//    func epubContainer(document doc: Document, webViewState: WebViewState) -> some View {

    var body: some View {
        containerView
    }

    var containerView: some View {
        BookTOCView(document: document, webViewState: webViewState, selection: selectionBinding)
    }
}

#if os(macOS)
struct BookTOCView : View {
    @ObservedObject var document: Document
    @ObservedObject var webViewState: WebViewState
    @Binding var selection: String??

    var body: some View {
        HSplitView {
            TOCListView(document: document, selection: $selection)
                .frame(maxWidth: 300)
                .onChange(of: selection) { selection in
                    if let selection = selection,
                       let selection = selection,
                       let content = document.epub.ncx?.findContent(selection) {
                        dbg("loading content:", content)
                        if let url = URL(string: "epub:///" + content) {
                            webViewState.load(url)
                        }
                    }
                }

            EPUBView(document: document, webViewState: webViewState)
        }
    }
}

/// A selectable list of the table of contents of the book, as defined in the (deprecated) `.ncx` file.
struct TOCListView : View {
    @ObservedObject var document: Document
    /// The selected navPoint ID
    @Binding var selection: String??

    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(document.epub.ncx?.toc.array() ?? [], id: \.element.id) { (indices, element) in
                    Text(element.navLabel ?? "?")
                        .padding(.leading, .init(indices.count) * 5) // indent
                }
            } header: {
                Text(document.epub.ncx?.title ?? "")
            }
        }
        .listStyle(.sidebar)
    }
}

#elseif os(iOS)

/// A navigation view for the table of contents, used on iOS to select the chapter
struct BookTOCView : View {
    @ObservedObject var document: Document
    @ObservedObject var webViewState: WebViewState
    @Binding var selection: String??

    var body: some View {
        List {
            Section {
                ForEach(document.epub.ncx?.toc.array() ?? [], id: \.element.id) { (indices, element) in
                    NavigationLink(tag: element.id, selection: $selection) {
                        EPUBView(document: document, webViewState: webViewState)
                            .onAppear {
                                if let selection = selection,
                                   let selection = selection,
                                   let content = document.epub.ncx?.findContent(selection) {
                                    dbg("loading content:", content)
                                    if let url = URL(string: "epub:///" + content) {
                                        webViewState.load(url)
                                    }
                                }
                            }
                    } label: {
                        Text(element.navLabel ?? "?")
                            .padding(.leading, .init(indices.count) * 5) // indent
                    }
                }
            } header: {
                Text(document.epub.ncx?.title ?? "")
            }
        }
        .listStyle(.sidebar)
    }
}
#endif


/// A scheme handler for loading elements directly from the underlying zip archive.
/// Entries are resolved relative to the location of the OPF file, and the mime type is
/// resolved by a lookup against the manifest.
///
/// https://www.w3.org/publishing/epub32/epub-ocf.html#sec-container-zip
final class EPUBSchemeHandler : NSObject, WKURLSchemeHandler {
    let epub: EPUB

    init(epub: EPUB) {
        self.epub = epub
    }

    public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        dbg("start urlSchemeTask:", urlSchemeTask.request.url)

        guard let url = urlSchemeTask.request.url else {
            return urlSchemeTask.didFailWithError(AppError("No path for request"))
        }

        // the path of the epub:///filename always starts with "/", which we need to trim
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        let entryPath = epub.resolveRelative(path: path)

        dbg("loading path:", entryPath, "relative to", epub.opfPath)

        guard let entry = epub.archive[entryPath] else {
            dbg("could not find entry:", entryPath, "in archive:", epub.archive.map(\.path).sorted())
            return urlSchemeTask.didFailWithError(AppError("Could not find entry: “\(entryPath)”"))
        }

        do {
            let mimeType = epub.manifest.values.first {
                $0.href == path
            }?.type

            dbg("loading:", path, "mimeType:", mimeType)
            let data = try epub.archive.extractData(from: entry)

            urlSchemeTask.didReceive(URLResponse(url: url, mimeType: mimeType, expectedContentLength: data.count, textEncodingName: "utf-8"))
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
        } catch {
            return urlSchemeTask.didFailWithError(error)
        }
    }

    public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        dbg("stop urlSchemeTask:", urlSchemeTask.request.url)
    }
}

struct EBookCommands : Commands {
    @FocusedValue(\.document) var document
    @FocusedValue(\.webViewState) var state
    
    var body: some Commands {
        SidebarCommands()
        ToolbarCommands()

        CommandGroup(after: .sidebar) {
            state?.observing { state in
                state.zoomAction(amount: nil).keyboardShortcut("0")
                state.zoomAction(amount: 1.2).keyboardShortcut("+")
                state.zoomAction(amount: 0.8).keyboardShortcut("-")
            }

            Divider()
        }
    }
}

extension FocusedValues {
    /// The store for the given scene
    var document: Document? {
        get { self[DocumentKey.self] }
        set { self[DocumentKey.self] = newValue }
    }

    private struct DocumentKey: FocusedValueKey {
        typealias Value = Document
    }
}

extension FocusedValues {
    /// The store for the given scene
    var webViewState: WebViewState? {
        get { self[WebViewStateKey.self] }
        set { self[WebViewStateKey.self] = newValue }
    }

    private struct WebViewStateKey: FocusedValueKey {
        typealias Value = WebViewState
    }
}

extension UTType {
    static var epub = UTType(importedAs: "app.Stanza-Redux.epub")
}

final class Document: ReferenceFileDocument {
    static let bundle = Bundle.module
    
    static var readableContentTypes: [UTType] {
        [
            UTType.epub,
            UTType.zip, // can also open epub zip files
        ]
    }
    static var writableContentTypes: [UTType] { [] }

    let epub: EPUB

    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        self.epub = try EPUB(data: data)
    }

    /// The extract pages from the spine
    func spinePages() -> [URL] {
        epub.spine.compactMap {
            epub.manifest[$0.idref].flatMap {
                //URL(fileURLWithPath: $0.href, relativeTo: extractFolder)
                URL(string: "epub:///" + $0.href)
            }
        }
    }

    func fileWrapper(snapshot: Void, configuration: WriteConfiguration) throws -> FileWrapper {
        throw AppError("Writing not yet supported")
    }

    func snapshot(contentType: UTType) throws -> Void {
        dbg("snapshot:", contentType)
    }
}


public struct AppSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Toggle(isOn: $store.someToggle) {
            Text("Toggle")
        }
        .padding()
    }
}
