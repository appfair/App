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

    public var body: some View {
        webViewBody()
            .onAppear {
                if let url = document.spinePages()
                    .dropFirst()
                    .dropFirst()
                    .dropFirst()
                    .dropFirst()
                    .dropFirst()
                    .dropFirst()
                    .dropFirst()
                    .dropFirst()
                    .first {
                    webViewState.load(url)
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
        DocumentGroup(viewing: Document.self) { file in
            epubView(file.document)
                .focusedSceneValue(\.document, file.document)
                //.environmentObject(file.document.sceneStore)
        }
        .commands {
            EBookCommands()
        }
    }

    func epubView(_ doc: Document) -> some View {
        EPUBView(document: doc, webViewState: doc.webViewState)
            .toolbar(id: "EPUBToolbar") {
                ToolbarItem(id: "ZoomOutCommand", placement: .automatic, showsByDefault: true) {
                    WebViewState.zoomCommand(doc.webViewState, brief: true, amount: 0.8)
                }
                ToolbarItem(id: "ZoomInCommand", placement: .automatic, showsByDefault: true) {
                    WebViewState.zoomCommand(doc.webViewState, brief: true, amount: 1.2)
                }
            }
    }
}

struct EBookCommands : Commands {
    @FocusedValue(\.document) var document

    var state: WebViewState? {
        document?.webViewState
    }

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

extension UTType {
    static var epub = UTType(importedAs: "app.Stanza-Redux.epub")
}

final class Document: ReferenceFileDocument {
    @ObservedObject var webViewState = WebViewState()

    static let bundle = Bundle.module
    
    static var readableContentTypes: [UTType] {
        [
            UTType.epub,
            UTType.zip, // can also open epub zip files
        ]
    }
    static var writableContentTypes: [UTType] { [] }

    let epub: EPUB
    let extractFolder: URL

    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        self.epub = try EPUB(data: data)
        self.extractFolder = try epub.extractContents()
    }

    /// The extract pages from the spine
    func spinePages() -> [URL] {
        epub.spine.compactMap {
            epub.manifest[$0.idref].flatMap {
                URL(fileURLWithPath: $0.href, relativeTo: extractFolder)
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
