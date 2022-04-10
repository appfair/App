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
    @EnvironmentObject var state: WebViewState
    @EnvironmentObject var store: Store
    @Namespace var mainNamespace
    @State var animationTime: TimeInterval = 0
    @State var searchString = ""

    public var body: some View {
        webViewBody()
            .toolbar(id: "EPUBToolbar") {
                ToolbarItem(id: "ZoomOutCommand", placement: .automatic, showsByDefault: true) {
                    WebViewState.zoomCommand(self.state, brief: true, amount: 0.8)
                }
                ToolbarItem(id: "ZoomInCommand", placement: .automatic, showsByDefault: true) {
                    WebViewState.zoomCommand(self.state, brief: true, amount: 1.2)
                }
            }
            .onAppear {
                if let url = wip(document.spinePages())
                    .dropFirst()
                    .dropFirst()
                    .dropFirst()
                    .dropFirst()
                    .dropFirst()
                    .dropFirst()
                    .dropFirst()
                    .dropFirst()
                    .dropFirst()
                    .dropFirst()
                    .dropFirst()
                    .first {
                    self.state.load(url)
                }
            }
    }

    public func webViewBody() -> some View {
        WebView(state: state)
    }
}

/// The shared app environment
@MainActor public final class Store: SceneManager {
    @AppStorage("someToggle") public var someToggle = false
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
        DocumentGroup(viewing: Document.self, viewer: epubView)
            .commands { EBookCommands() }
    }

    func epubView(file: ReferenceFileDocumentConfiguration<Document>) -> some View {
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

        return EPUBView(document: doc)
            .focusedSceneValue(\.document, file.document)
            .focusedSceneValue(\.webViewState, webViewState)
            .environmentObject(webViewState)
    }
}

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

        // remove slashes from either end of the given string
        let ts = { (str: String) in str.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }

        // entries are resolved relative to the OPF file
        let opfRoot = ts(URL(fileURLWithPath: "/" + epub.opfPath).deletingLastPathComponent().path)

        let relativePath = ts(url.path)

        let entryPath = !opfRoot.isEmpty ? (opfRoot + "/" + relativePath) : relativePath

        dbg("loading path:", entryPath, "relative to", epub.opfPath)

        guard let entry = epub.archive[entryPath] else {
            dbg("could not find entry:", entryPath, "in archive:", epub.archive.map(\.path).sorted())
            return urlSchemeTask.didFailWithError(AppError("Could not find entry: “\(entryPath)”"))
        }

        do {
            let mimeType = epub.manifest.values.first {
                $0.href == relativePath
            }?.type

            dbg("loading:", relativePath, "mimeType:", mimeType)
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
        CommandGroup(after: .sidebar) {
            WebViewState.zoomCommand(state, brief: false, amount: nil)
                .keyboardShortcut("0", modifiers: [.command])
            WebViewState.zoomCommand(state, brief: false, amount: 1.2)
                .keyboardShortcut("+", modifiers: [.command])
            WebViewState.zoomCommand(state, brief: false, amount: 0.8)
                .keyboardShortcut("-", modifiers: [.command])

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
