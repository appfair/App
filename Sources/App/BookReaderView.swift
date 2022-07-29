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
import FairKit
import UniformTypeIdentifiers

struct BookReaderView : View {
    @ObservedObject var document: EPUBDocument
    @ObservedObject var bookReaderState: BookReaderState
    /// The current book selection
    @Binding var section: String??
    /// The current position in the section
    @State var position: Double = 0.0
    /// Whether the settings view is displayed or not
    @State var showSettings = false

    @AppStorage("swipeAdjustsBrightness") var swipeAdjustsBrightness: Bool = true

    /// Whether the overlay controls are currently shown or not
    @State var showControls = true

    var body: some View {
        #if os(macOS)
        NavigationView {
            TOCListView(document: document, section: $section)
            bookView
                .navigationTitle(document.epub.opf.title ?? "No Title")
        }
        #elseif os(iOS)
        NavigationView {
            if bookReaderState.showTOCSidebar {
                TOCListView(document: document, section: $section, action: { section in
                    dbg("selected:", section ?? nil)
                    withAnimation {
                        //bookReaderState.targetPosition = 0.0 // always jump to beginnings of sections
                        self.section = section
                        bookReaderState.showTOCSidebar = false
                    }
                })
                .listStyle(.sidebar) // seems to not be the default on iOS
                .transition(.slide)
            }

            bookView
                .navigation(title: document.epub.opf.title.flatMap(Text.init) ?? Text("No Title", bundle: .module, comment: "navigation title for books with no title"), subtitle: navigationSubtitle)
                .ignoresSafeArea(.container, edges: .all)
                .edgesIgnoringSafeArea(.all)
                .navigationViewStyle(.stack)
                .navigationBarTitleDisplayMode(.large)
                .navigationBarHidden(!showControls)
                .statusBar(hidden: !showControls)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("Settings", bundle: .module, comment: "title for settings button")
                    .label(image: FairSymbol.gearshape)
                    .labelStyle(IconOnlyLabelStyle())
                    .button {
                        showSettings = true
                    }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                if showControls {
                    bookReaderState.textScaleAction(amount: 0.8)
                    Spacer()
                    Text("TOC", bundle: .module, comment: "brief button title for displaying the table of contents")
                        .label(image: FairSymbol.list_bullet)
                        .button {
                            dbg("toggling TOC")
                            withAnimation {
                                bookReaderState.showTOCSidebar.toggle()
                            }
                        }
                    Spacer()
                    bookReaderState.textScaleAction(amount: 1.2)
                }
            }
        }
        .fullScreenCover(isPresented: $showSettings) {
            NavigationView {
                AppSettingsView()
                    .navigationTitle(Text("Settings", bundle: .module, comment: "title for the app settings screen"))
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Text("Done", bundle: .module, comment: "title of button close the settings sheet")
                                .button {
                                    self.showSettings = false
                                }
                        }
                    }
            }
        }
        #endif
    }

    var navigationSubtitle: Text? {
        guard let section = self.section,
           let section = section,
           let ncx = document.epub.ncx,
              let navLabel = ncx.findNavpoint(id: section)?.navLabel else {
            return nil
        }

        return Text(navLabel)
    }

    var bookView: some View {
        EPUBView(document: document, bookReaderState: bookReaderState, selection: $section, showControls: $showControls)
            .onChange(of: section) { section in
                dbg("section changed:", section ?? "")
                bookReaderState.loadSelection($section, position: 0.0, in: document)
            }
            .onChange(of: bookReaderState.progress) { progress in
                // remember the current progress in the section
                document.sectionProgress = progress
            }
            .onAppear {
                dbg("appear:", document.epub.opf.title)
                if let section = self.section, let section = section {
                    dbg("restoring selection:", section)
                    bookReaderState.loadSelection($section, position: document.sectionProgress, in: document)
                } else {
                    let initialNCXID = self.document.epub.ncx?.points.first
                    dbg("loading initial section:", initialNCXID)
                    DispatchQueue.main.async {
                        self.section = initialNCXID?.id
                    }
                }
            }
    }
}

final class BookSidecarFile : NSObject, NSFilePresenter {
    var fileURL: URL
    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    #if !os(iOS) // unavailable in iOS
    var primaryPresentedItemURL: URL? {
        fileURL
    }
    #endif

    var presentedItemURL: URL? {
        fileURL.deletingPathExtension().appendingPathExtension("stanza")
    }

    var presentedItemOperationQueue: OperationQueue {
        .main
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct EBookScene : Scene {
    let store: Store

    var body: some Scene {
        #if false // only works on iPadOS
        WindowGroup {
            Button("Create a Scene") {
              let userActivity = NSUserActivity(
                activityType: "app.Stanza-Redux.documents"
              )
              userActivity.targetContentIdentifier =
                "app.Stanza-Redux.documents"

              UIApplication.shared.requestSceneSessionActivation(
                nil,
                userActivity: userActivity,
                options: nil,
                errorHandler: nil
              )
            }
        }
        .handlesExternalEvents(matching: ["app.Stanza-Redux.scene2"])
        #endif

        DocumentGroup(viewing: EPUBDocument.self, viewer: documentHostView)
            .commands { EBookCommands() }
            .handlesExternalEvents(matching: ["app.Stanza-Redux.documents"])
    }

    func documentHostView(file: ReferenceFileDocumentConfiguration<EPUBDocument>) -> some View {
        let doc: EPUBDocument = file.document
        doc.fileURL = file.fileURL

        // sidecard support attempt

//        if let fileURL = doc.fileURL {
//
//            let sidecar = BookSidecarFile(fileURL: fileURL)
//            let coord = NSFileCoordinator(filePresenter: sidecar)
//            NSFileCoordinator.addFilePresenter(sidecar)
//            defer {
//                NSFileCoordinator.removeFilePresenter(sidecar)
//            }
//            var err: NSError?
//            if let sidecarURL = sidecar.presentedItemURL {
////                coord.coordinate(readingItemAt: fileURL, error: &err) { url in
////                    dbg("### coordinate(readingItemAt:", url.path, sidecarURL.path)
////                    do {
////                        let data = try Data(contentsOf: sidecarURL)
////                        dbg("read from sidecar file:", sidecarURL.path)
////                    } catch {
////                        dbg("error reading sidecar file:", error)
////
////                    }
////                }
//
//                coord.coordinate(writingItemAt: fileURL, error: &err) { url in
//                    dbg("### coordinate(writingItemAt:", url.path, sidecarURL.path)
//                    do {
//                        //try FileManager.default.copyItem(at: fileURL, to: sidecarURL)
//                        try String(wip("TEST")).write(to: sidecarURL, atomically: true, encoding: .utf8)
//                        dbg("wrote to sidecar file:", sidecarURL.path)
//                    } catch {
//                        dbg("error writing sidecar file:", error)
//
//                    }
//                }
//            }
//        }
        return BookContainerView(document: doc)
            .environmentObject(store)
            .focusedSceneValue(\.document, file.document)
    }
}

struct BookContainerView : View {
    @ObservedObject var document: EPUBDocument
    @StateObject var bookReaderState: BookReaderState

    init(document: EPUBDocument) {
        self.document = document
        self._bookReaderState = .init(wrappedValue: document.createBookReaderState())
    }

    private var sectionBinding: Binding<String??> {
        Binding {
            document.currentSection
        } set: { newValue in
            if newValue != document.currentSection {
                document.currentSection = newValue ?? .none
            }
        }
    }

    var body: some View {
        containerView
            .focusedSceneValue(\.bookReaderState, bookReaderState)
            .alertingError($bookReaderState.errors)
    }

    var containerView: some View {
        BookReaderView(document: document, bookReaderState: bookReaderState, section: sectionBinding)
    }
}

@available(macOS 12.0, iOS 15.0, *)
public struct EPUBView: View {
    @ObservedObject var document: EPUBDocument
    @ObservedObject var bookReaderState: BookReaderState
    @EnvironmentObject var store: Store
    @Namespace var mainNamespace
    /// The currently selected section
    @Binding var selection: String??
    @Binding var showControls: Bool

    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                bookBody
                progressView
            }
            controlOverlay
        }
    }

    var pageIndices: [Int]? {
        if let webView = bookReaderState.webView {
            let visibleWidth = webView.bounds.width
            let totalWidth = bookReaderState.sectionWidth
            if totalWidth > visibleWidth {
                let count = Int(totalWidth / visibleWidth)
                if count > 0 {
                    return Array(-1..<count)
                }
            }

//#if os(iOS) // scrollView only available on iOS
//            let visibleWidth = webView.scrollView.visibleSize.width
//            let totalWidth = webView.scrollView.contentSize.width
//            if totalWidth > visibleWidth {
//                let count = Int(totalWidth / visibleWidth)
//                if count > 0 {
//                    return Array(-1..<count)
//                }
//            }
//#endif
        }
        return nil
    }

    @ViewBuilder var progressView: some View {
        Group {
            if let indices = pageIndices {
                GeometryReader { proxy in
                    SectionProgressBars(indices: indices, progress: bookReaderState.progress, width: proxy.size.width)
                        .equatable()
                }
            } else {
                Rectangle()
                    .fill(LinearGradient(stops: [
                        Gradient.Stop(color: Color.accentColor, location: 0.0),
                        Gradient.Stop(color: Color.accentColor, location: max(0.0, bookReaderState.progress)),
                        Gradient.Stop(color: Color.white, location: min(1.0, bookReaderState.progress)),
                        Gradient.Stop(color: Color.white, location: 1.0),
                    ], startPoint: .leading, endPoint: .trailing))
            }
        }
        .frame(height: 5)
    }

    var controlOverlay: some View {
        VStack {
            Button {
                Task { try? await bookReaderState.position(0.0) }
            } label: {
                Text("Beginning of Section", bundle: .module, comment: "button text for jumping to the beginning of the section")
                    .label(image: FairSymbol.chevron_left_circle_fill)
            }
            .contentShape(Rectangle().inset(by: -200))
            .keyboardShortcut(.home, modifiers: [])

            HStack {
                Button {
                    changePage(by: -1)
                } label: {
                    Text("Previous", bundle: .module, comment: "button text for previous page")
                        .label(image: FairSymbol.chevron_left_circle_fill)
                }
                .contentShape(Rectangle().inset(by: -200))
                .keyboardShortcut(.leftArrow, modifiers: [])

                Spacer()

                let nextButton = Button {
                    changePage(by: +1)
                } label: {
                    Text("Next", bundle: .module, comment: "button text for next page")
                        .label(image: FairSymbol.chevron_right_circle_fill)
                }
                .contentShape(Rectangle().inset(by: -200))

                ZStack {
                    // since a single button cannot receive multiple keyboard shortcuts, use a stack of the same button
                    nextButton
                        .keyboardShortcut(.rightArrow, modifiers: [])
                    nextButton
                        .keyboardShortcut(.space, modifiers: [])
                }
            }

            Button {
                Task { try? await bookReaderState.position(1.0) }
            } label: {
                Text("End of Section", bundle: .module, comment: "button text for jumping to the end of the section")
                    .label(image: FairSymbol.chevron_left_circle_fill)
            }
            .contentShape(Rectangle().inset(by: -200))
            .keyboardShortcut(.end, modifiers: [])

        }
        .labelStyle(.iconOnly)
        .foregroundStyle(Color.accentColor)
        .opacity(0.01)
        .font(Font.largeTitle.bold())
        .buttonStyle(.borderless)
    }

    func changePage(by amount: Int) {
        dbg("change page by:", amount)

        Task {
            do {
                guard let result = try await bookReaderState.movePage(by: amount) else {
                    dbg("unable to change page by:", amount)
                    return
                }
                dbg("changed page to:", percent(result))
                if result >= 1.0 {
                    try changeSection(next: true)
                } else if result < 0.0 {
                    try changeSection(next: false)
                }

                if amount != 0 {
                    self.showControls = false
                }

            } catch {
                bookReaderState.reportError(error)
            }
        }
    }

    func changeSection(next: Bool) throws {
        dbg("moving to", next ? "next" : "previous", "section")
        bookReaderState.loadSelection($selection, adjacent: next ? +1 : -1, in: document)
    }

    @ViewBuilder var bookBody: some View {
        webViewBody()
            .onChange(of: bookReaderState.touchRegion) { region in
                if let region = region {
                    dbg("touch region:", region)
                    // reset the touch region
                    bookReaderState.touchRegion = nil

                    if bookReaderState.showTOCSidebar {
                        // if the TOC is showing, hide it
                        bookReaderState.showTOCSidebar = false
                    } else if region < (1.0 / 3.0) {
                        changePage(by: bookReaderState.leadingTapAdvances ? +1 : -1)
                    } else if region > (2.0 / 3.0) {
                        changePage(by: +1)
                    } else {
                        self.showControls.toggle()
                    }
                }
            }
            #if os(macOS) // customizable toolbar on macOS
            .toolbar(id: "EPUBToolbar") {
                ToolbarItem(id: "ZoomOutCommand", placement: .automatic, showsByDefault: true) {
                    bookReaderState.textScaleAction(amount: 0.8)
                }
                ToolbarItem(id: "ZoomInCommand", placement: .automatic, showsByDefault: true) {
                    bookReaderState.textScaleAction(amount: 1.2)
                }
            }
            #endif
    }

    public func webViewBody() -> some View {
        WebView(state: bookReaderState)
    }
}

/// Evenly spaced bars representing individual pages in a section.
struct SectionProgressBars : View, Equatable {
    let indices: [Int]
    let progress: Double
    let width: Double

    var body: some View {
        HStack(spacing: indices.count > Int(width) / 4 ? 0.0 : 0.5) {
            ForEach(indices, id: \.self) { page in
                Rectangle()
                    .fill(Double(page) / Double(indices.count - 1) < progress ? Color.accentColor : Color.secondary)
            }
        }
        .drawingGroup()
    }
}

/// A selectable list of the table of contents of the book, as defined in the  `.ncx` file.
struct TOCListView : View {
    @ObservedObject var document: EPUBDocument
    /// The selected navPoint ID
    @Binding var section: String??
    /// The action to perform when an item is selected; this is for platforms (i.e., iOS) where List selection only works with "editable" lists
    var action: ((String??) -> ())? = nil

    var body: some View {
        ScrollViewReader { scrollView in
            List(selection: $section) {
                Section {
                    ForEach(document.epub.ncx?.toc.array() ?? [], id: \.element.id) { (indices, element) in
                        let text = Text(element.navLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "?")
                        if let action = action {
                            text
                                .fontWeight(section == element.id ? .bold : .regular)
                                .button {
                                    action(element.id)
                                }
                                .padding(.leading, .init(indices.count) * 5) // indent
                        } else {
                            // with no action, just display the text
                            text
                                .padding(.leading, .init(indices.count) * 5) // indent
                        }
                    }
                } header: {
                    Text(document.epub.ncx?.title ?? "")
                }
            }
            .onAppear {
                if let section = section {
                    scrollView.scrollTo(section, anchor: .center)
                }
            }
        }
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

        // the path of the epub:///filename always starts with "/", which we need to trim
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        let entryPath = epub.resolveRelative(path: path)

        dbg("loading path:", entryPath, "relative to:", epub.packageRoot)

        guard let entry = epub.archive[entryPath] else {
            dbg("could not find entry:", entryPath, "in archive:", epub.archive.map(\.path).sorted())
            return urlSchemeTask.didFailWithError(AppError("Could not find entry: “\(entryPath)”"))
        }

        do {
            let mimeType = epub.opf.manifest.values.first {
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
    @FocusedValue(\.bookReaderState) var state

    var body: some Commands {
        SidebarCommands()
        ToolbarCommands()

        CommandGroup(after: .sidebar) {
//            state?.observing { state in
//                state.textScaleAction(amount: nil).keyboardShortcut("0")
//                state.textScaleAction(amount: 1.2).keyboardShortcut("+")
//                state.textScaleAction(amount: 0.8).keyboardShortcut("-")
//            }

            Divider()
        }
    }
}

extension FocusedValues {
    /// The store for the given scene
    var document: EPUBDocument? {
        get { self[DocumentKey.self] }
        set { self[DocumentKey.self] = newValue }
    }

    private struct DocumentKey: FocusedValueKey {
        typealias Value = EPUBDocument
    }
}

extension FocusedValues {
    /// The store for the given scene
    var bookReaderState: BookReaderState? {
        get { self[BookReaderStateKey.self] }
        set { self[BookReaderStateKey.self] = newValue }
    }

    private struct BookReaderStateKey: FocusedValueKey {
        typealias Value = BookReaderState
    }
}

final class EPUBDocument: ReferenceFileDocument {
    static let bundle = Bundle.module

    /// This document can read epub (`org.idpf.epub-container`) files
    static var readableContentTypes: [UTType] = [UTType.epub]

    /// Empty `writableContentTypes` because the content is not editable
    static var writableContentTypes: [UTType] = []

    let epub: EPUB

    /// The underlying URL for the file
    var fileURL: URL?

    /// The current section in the document
    var currentSection: String? {
        get { self[stringStore: "section"] }
        set { self[stringStore: "section"] = newValue }
    }

    /// The progress in the current section
    var sectionProgress: Double? {
        get { self[doubleStore: "progress"] }
        set { self[doubleStore: "progress"] = newValue }
    }

    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let epub = try EPUB(data: data)
        self.epub = epub
    }

    var bookDefaultsKey: String {
        "book-" + (epub.opf.bookID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? epub.opf.bookID)
    }

    /// A persistent key for the UserDefaults for this particular book
    /// - Parameter name: the key name
    /// - Returns: the full defaults key for this book
    private var persistenceStore: NSMutableDictionary {
        get {
            (UserDefaults.standard.object(forKey: bookDefaultsKey) as? NSDictionary ?? NSDictionary()).mutableCopy() as? NSMutableDictionary ?? .init()
        }

        set {
            dbg("storing book:", bookDefaultsKey, "defaults:", newValue)
            UserDefaults.standard.set(newValue, forKey: bookDefaultsKey)
            self.objectWillChange.send()
        }
    }

    /// A persistent string value for the current book
    private subscript(stringStore key: String) -> String? {
        get {
            persistenceStore[key] as? String
        }

        set {
            let store = persistenceStore
            store[key] = newValue
            self.persistenceStore = store
        }
    }

    /// A persistent double value for the current book
    private subscript(doubleStore key: String) -> Double? {
        get {
            persistenceStore[key] as? Double
        }

        set {
            let store = persistenceStore
            store[key] = newValue
            self.persistenceStore = store
        }
    }

    /// Create the initial view state for the book
    @MainActor func createBookReaderState() -> BookReaderState {
        // possible optimization: the EPUBDocument document initializer loads the zip from the FileWrapper's `fileContents` data, which could mean the whole thing is loaded into memory; we could alternatively load it here from the configuration's `fileURL`, but this means that errors wouldn't be handled by the document's initializer. Profiling should be done on large documents, since it is possible that using mapped reads doesn't wind up loading the whole file in memory anyway

        // let url = file.fileURL

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = false
        prefs.preferredContentMode = .desktop

        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = prefs
        config.suppressesIncrementalRendering = true
        //config.limitsNavigationsToAppBoundDomains = true

        // configure loading epub:///file.xhtml directly from the epub zip file
        config.setURLSchemeHandler(EPUBSchemeHandler(epub: epub), forURLScheme: "epub")

        let controller = WKUserContentController()

        config.userContentController = controller

        return BookReaderState(initialRequest: nil, configuration: config)
    }

    /// The extract pages from the spine
    func spinePages() -> [URL] {
        epub.opf.spine.compactMap {
            epub.opf.manifest[$0.idref].flatMap {
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
        Form {
            Toggle(isOn: $store.smoothScrolling) {
                Text("Smooth scroll pages:", bundle: .module, comment: "toggle preference title for smooth scrolling of pages")
            }
            .toggleStyle(.switch)
            Toggle(isOn: $store.leadingTapAdvances) {
                Text("Left tap advances:", bundle: .module, comment: "toggle preference title for whehter a tap on the left side of the screen should advance")
            }
            .toggleStyle(.switch)
        }
        .padding()
    }
}
