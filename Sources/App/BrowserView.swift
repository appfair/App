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
import WebKit

/// A browser component that contains a URL/search field and a WebView
struct BrowserView : View {
    @StateObject private var state: BrowserState = BrowserState(initialRequest: nil)
    @EnvironmentObject private var store: Store

    var body: some View {
        VStack(spacing: 0) {
            findBar
            browserBody
        }
            .focusedSceneValue(\.browserState, state)
            .onAppear {
                if !store.homePage.isEmpty, let url = URL(string: store.homePage) {
                    state.load(url)
                }
            }
            .preferredColorScheme(store.themeStyle.colorScheme)
            .toolbar(id: "ReaderToolbar") {
                ToolbarItem(id: "ReaderCommand", placement: .automatic, showsByDefault: true) {
                    BrowserState.readerViewCommand(state, brief: true)
                }
            }
            .alertingError($state.errors)
    }

    var findBar: some View {
        #if os(macOS)
        HStack {
            Spacer()
            FindBarView()
                .environmentObject(state)
        }
        #else
        EmptyView()
        #endif
    }

    var browserBody: some View {
        let content = WebView(state: state)
            .webViewNavigationPolicy(onAction: decidePolicy(for:state:))
            .alert(item: $externalNavigation, content: makeExternalNavigationAlert(_:))

        let urlField = ToolbarItem(id: "URLField", placement: .principal, showsByDefault: true) {
            urlTextField
        }

#if os(macOS)
        return content
            .edgesIgnoringSafeArea(.all)
            .navigationTitle(state.title.isEmpty ? "Net Skip" : state.title)
            .toolbar(id: "NavigationToolbar") {
                ToolbarItem(id: "ForwardBackward", placement: .navigation, showsByDefault: true) {
                    HStack { // we'd rather use a ToolbarItemGroup(placement: .navigation) here, but it doesn't seem to work with customizable toolbars
                        goBackCommand
                        goForwardCommand
                    }
                }
                urlField
            }
#elseif os(iOS)
        return content
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    goBackCommand.labelStyle(IconOnlyLabelStyle())
                    goForwardCommand.labelStyle(IconOnlyLabelStyle())
                }
                urlField
            }
#endif
    }

    private var urlTextField: some View {
        URLTextField(url: state.url, isSecure: state.hasOnlySecureContent, loadingProgress: state.estimatedProgress, onNavigate: onNavigate(to:)) {
            if state.isLoading {
                WebViewState.stopCommand(state, brief: true)
            } else {
                WebViewState.reloadCommand(state, brief: true)
            }
        }
    }

    private var goBackCommand: some View {
        Button(action: { state.goBack() }) {
            Text("Back", bundle: .module, comment: "label for toolbar back button").label(image: FairSymbol.chevron_left)
                .frame(minWidth: 20)
        }
        .disabled(!state.canGoBack)
        .keyboardShortcut("[")
    }

    private var goForwardCommand: some View {
        Button(action: { state.goForward() }) {
            Text("Forward", bundle: .module, comment: "label for toolbar forward button").label(image: FairSymbol.chevron_right)
                .frame(minWidth: 20)
        }
        .disabled(!state.canGoForward)
        .keyboardShortcut("]")
    }

    func searchTermURL(_ searchTerm: String) -> URL? {
        let searchHost = store.searchHost
        var components = URLComponents(string: "https://\(searchHost)/")
        components?.queryItems = [ URLQueryItem(name: "q", value: searchTerm) ]
        return components?.url
    }

    private func onNavigate(to string: String) {
        switch UserInput(string: string) {
        case .search(let term):
            state.load(searchTermURL(term))
        case .url(let url):
            state.load(url)
        case .invalid:
            break
        }
    }

    @State private var externalNavigation: ExternalURLNavigation?
    @Environment(\.openURL) private var openURL

    private func decidePolicy(for action: NavigationAction, state: WebViewState) {
        if let externalURL = action.request.url,
            !WebView.canHandle(externalURL) {
            dbg(externalURL)
            externalNavigation = ExternalURLNavigation(source: state.url ?? URL(string: "about:blank")!, destination: externalURL)
            action.decidePolicy(.cancel)
        } else {
            action.decidePolicy(.allow)
        }
    }

    private func makeExternalNavigationAlert(_ navigation: ExternalURLNavigation) -> Alert {
        Alert(title: Text("Allow “\(navigation.source.highLevelDomain)” to open “\(navigation.destination.scheme ?? "")”?", bundle: .module, comment: "alert for whether to permit external navigation"), primaryButton: .default(Text("Allow", bundle: .module, comment: "button text for allow text in dialog asking whether to permit external navigation"), action: { openURL(navigation.destination) }), secondaryButton: .cancel())
    }
}

class BrowserState : WebViewState {
    override func createWebView() -> WKWebView {
        let view = super.createWebView()
        #if os(macOS)
        view.allowsMagnification = true
        finder.client = view
        #endif
        return view
    }

    #if canImport(AppKit)
    let finder: NSTextFinder = {
        let finder = NSTextFinder()
        finder.isIncrementalSearchingEnabled = true
        finder.incrementalSearchingShouldDimContentView = true
        return finder
    }()
    #endif

    public func enterReaderView() async {
        dbg()
        await self.trying {
            let readability = try Bundle.module.loadBundleResource(named: "Readability.js")
            dbg("loading readability library:", ByteCountFormatter().string(fromByteCount: .init(readability.count)))

            // load the readbility script
            try await js((readability.utf8String ?? ""))

            // invoke the parser
            let result = try await js("new Readability(document.cloneNode(true)).parse()")

            dbg("result:", result)
            if let dict = result as? NSDictionary,
                let content = dict["content"] as? String {
                dbg("content:", ByteCountFormatter().string(fromByteCount: .init(content.count)))
                await webView?.loadHTMLString(content, baseURL: webView?.url)
            }
        }
    }

    static func readerViewCommand(_ state: BrowserState?, brief: Bool) -> some View {
        (brief ? Text("Reader", bundle: .module, comment: "label for brief reader command") : Text("Show Reader", bundle: .module, comment: "label for non-brief reader command"))
            .label(image: FairSymbol.eyeglasses)
            .button {
                dbg("loading reader view for:", state?.url)
                Task {
                    await state?.enterReaderView()
                }
            }
            //.disabled(state?.canEnterReaderView != true)
    }
}

#if os(macOS)

struct FindBarView : UXViewRepresentable {
    @EnvironmentObject var state: BrowserState

    func makeUXView(context: Context) -> NSStackView {
        state.finder.findBarContainer = context.coordinator
        return context.coordinator.findBarContainer
    }

    func updateUXView(_ view: NSStackView, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    static func dismantleUXView(_ view: NSStackView, coordinator: Coordinator) {
    }

    @objc class Coordinator : NSObject, NSTextFinderBarContainer {
        let findBarContainer = NSStackView()
        var isFindBarVisible: Bool = true
        let heightConstraint: NSLayoutConstraint

        override init() {
            self.heightConstraint = NSLayoutConstraint(item: findBarContainer, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1.0, constant: 0.0)
            findBarContainer.addConstraint(heightConstraint)
            super.init()
        }

        @objc var findBarView: NSView? {
            didSet {
                dbg("set findBarView:", findBarView)
                if let findBarView = findBarView {
                    findBarContainer.setViews([findBarView], in: .trailing)
                } else {
                    findBarContainer.setViews([], in: .trailing)
                }
//                if let findBarView = findBarView {
//                    findBarView.frame = NSMakeRect(0, self.view.bounds.height - findBarView.frame.height, self.view.bounds.width, findBarView.frame.height)
//                }
            }
        }

        func findBarViewDidChangeHeight() {
            dbg(findBarView?.frame.height)
            if let findBarView = findBarView {
                self.heightConstraint.constant = findBarView.frame.height
            }
        }
    }
}

#endif

struct URLTextField<Accessory> : View where Accessory : View {
    private var loadingProgress: Double?
    private var onNavigate: (String) -> Void
    private var trailingAccessory: Accessory
    private var url: URL?
    private var urlIsSecure: Bool

    @State private var isEditing = false
    @State private var text: String = ""

    #if os(macOS)
    //@Environment(\.resetFocus) var resetFocus
    #endif
    @Namespace private var namespace

    @EnvironmentObject var store: Store
    enum FocusField: Hashable {
      case field
    }

    @FocusState private var focusedField: FocusField?

    init(url: URL?, isSecure: Bool = false, loadingProgress: Double? = nil, onNavigate: @escaping (String) -> Void, @ViewBuilder accessory: () -> Accessory) {
        self.trailingAccessory = accessory()
        self.loadingProgress = loadingProgress
        self.onNavigate = onNavigate
        self.url = url
        self.urlIsSecure = isSecure

        if let url = url {
            text = url.absoluteString
        }
    }

    var body: some View {
        let content = HStack {
            leadingAccessory
            textField
            if !isEditing {
                trailingAccessory
                    .labelStyle(IconOnlyLabelStyle())
            }
        }
        .buttonStyle(PlainButtonStyle())
        .font(.body)
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(URLFieldBackground(loadingProgress: loadingProgress))
        .frame(minWidth: 200, idealWidth: 400, maxWidth: 600)
        .onChange(of: url, perform: { _ in urlDidChange() })

#if os(macOS)
        return content
            .focusScope(namespace)
            .overlay(RoundedRectangle(cornerRadius: 6)
            .stroke(Color.accentColor, lineWidth: 2))
#else
        return content
#endif
    }

    var urlIsWebSeach: Bool {
        url?.host?.contains(store.searchHost) == true
    }

    @ViewBuilder
    private var leadingAccessory: some View {
        if isEditing {
            FairSymbol.globe.foregroundColor(.secondary)
        } else if urlIsWebSeach {
            FairSymbol.magnifyingglass.foregroundColor(.orange)
        } else if urlIsSecure {
            FairSymbol.lock_fill.foregroundColor(.green)
        } else {
            FairSymbol.globe.foregroundColor(.secondary)
        }
    }

    private var textField: some View {
        let view = TextField("Search or enter website name", text: $text, onEditingChanged: onEditingChange(_:), onCommit: onCommit)
            .textFieldStyle(PlainTextFieldStyle())
            .disableAutocorrection(true)

#if os(iOS)
        return view
            .textContentType(.URL)
            .autocapitalization(.none)
#elseif os(macOS)
        return view
            .prefersDefaultFocus(true, in: namespace) // doesn't seem to work
            .focused($focusedField, equals: .field) // also doesn't work
            .onAppear {
                dbg("focusing on URL field")
                self.focusedField = .field // doesn't work…
                // …so we hack it in (also doesn't work)
//                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
//                    if let window = NSApp.keyWindow,
//                       let toolbar = window.toolbar {
//                        dbg("attempt focus in:", toolbar, toolbar.visibleItems)
                        
//                        if let searchField = toolbar.visibleItems?.compactMap({ $0.view }).last {
//                            dbg("searchField:", searchField, searchField.subviews)
//                            for sub in searchField.subviews {
//                                window.makeFirstResponder(sub)
//                                for sub2 in sub.subviews {
//                                    if sub2 is UXTextField {
//                                        dbg("found searchField:", sub2)
//                                        window.makeFirstResponder(sub2)
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
            }

#endif
    }

    private func urlDidChange() {
        if !isEditing {
            text = url?.absoluteString ?? ""
        }
    }

    private func onEditingChange(_ isEditing: Bool) {
        self.isEditing = isEditing
//        if !isEditing {
//            urlDidChange()
//        }
    }

    private func onCommit() {
        dbg("committing URL text:", text)
        onNavigate(text)
    }
}

private struct URLFieldBackground : View {
    var loadingProgress: Double?

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .foregroundColor(Color.platformBackground)
            .overlay(progress)
    }

    private var progress: some View {
        GeometryReader { proxy in
            if let loadingProgress = loadingProgress {
                ProgressView(value: loadingProgress)
                    .offset(y: proxy.size.height - 4)
            }
        }
    }
}


private enum UserInput {
    case search(String)
    case url(URL)
    case invalid

    init(string str: String) {
        let string = str.trimmingCharacters(in: .whitespaces)

        if string.isEmpty {
            self = .invalid
        } else if !string.contains(where: \.isWhitespace),
                    string.contains("."),
                    var url = URL(string: string) {
            if url.scheme == nil { // replace an empty scheme with https
                url = URL(string: "https://" + string) ?? url
            }
            self = .url(url)
        } else {
            self = .search(string)
        }
    }
}

private struct ExternalURLNavigation : Identifiable, Hashable {
    var source: URL
    var destination: URL

    var id: Self { self }
}

extension URL {
    var highLevelDomain: String {
        guard let host = host else {
            return ""
        }

        for prefix in ["www"] where host.hasPrefix("\(prefix).") {
            let indexAfterPrefix = host.index(host.startIndex, offsetBy: prefix.count + 1)
            return String(host[indexAfterPrefix...])
        }

        return host
    }
}

