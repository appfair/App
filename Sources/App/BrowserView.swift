import SwiftUI
import FairApp

/// A browser component that contains a URL/search field and a WebView
struct BrowserView : View {
    @StateObject private var state = BrowserState()
    @EnvironmentObject private var store: Store
    @AppStorage("themeStyle") var themeStyle = ThemeStyle.system

    var body: some View {
        browserBody
            .focusedSceneValue(\.browserState, state)
            .onAppear {
                if !store.homePage.isEmpty, let url = URL(string: store.homePage) {
                    state.load(url)
                }
            }
            .preferredColorScheme(themeStyle.colorScheme)
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    readerViewCommand
                }
            }
//            .commands {
//                CommandGroup(after: CommandGroupPlacement.textFormatting) {
//                    readerViewCommand
//                }
//            }

    }

    var browserBody: some View {
        let content = WebView(state: state)
            .webViewNavigationPolicy(onAction: decidePolicy(for:state:))
            .alert(item: $externalNavigation, content: makeExternalNavigationAlert(_:))

        let urlField = ToolbarItem(placement: .principal) {
            urlTextField
        }

#if os(macOS)
        return content
            .edgesIgnoringSafeArea(.all)
            .navigationTitle(state.title.isEmpty ? "Net Skip" : state.title)
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    goBackCommand
                    goForwardCommand
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
                Button(action: state.stopLoading) {
                    Text("Stop Loading").label(image: FairSymbol.xmark)
                }
            } else {
                Button(action: state.reload) {
                    Text("Reload").label(image: FairSymbol.arrow_clockwise)
                }
                .disabled(state.url == nil)
            }
        }
    }

    private var readerViewCommand: some View {
        Text("Reader", bundle: .module, comment: "label for toolbar reader view")
            .label(image: FairSymbol.eyeglasses)
            .button {
                dbg("loading reader view for:", state.url)
                state.enterReaderView()
            }
            .disabled(state.canEnterReaderView != true)
    }

    private var goBackCommand: some View {
        Button(action: state.goBack) {
            Text("Back", bundle: .module, comment: "label for toolbar back button").label(image: FairSymbol.chevron_left)
                .frame(minWidth: 20)
        }
        .disabled(!state.canGoBack)
        .keyboardShortcut("[")
    }

    private var goForwardCommand: some View {
        Button(action: state.goForward) {
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

    private func decidePolicy(for action: NavigationAction, state: BrowserState) {
        if let externalURL = action.request.url, !WebView.canHandle(externalURL) {
            externalNavigation = ExternalURLNavigation(source: state.url ?? URL(string: "about:blank")!, destination: externalURL)
            action.decidePolicy(.cancel)
        } else {
            action.decidePolicy(.allow)
        }
    }

    private func makeExternalNavigationAlert(_ navigation: ExternalURLNavigation) -> Alert {
        Alert(title: Text("Allow “\(navigation.source.highLevelDomain)” to open “\(navigation.destination.scheme ?? "")”?"), primaryButton: .default(Text("Allow"), action: { openURL(navigation.destination) }), secondaryButton: .cancel())
    }
}

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
        let view = TextField("Search or website address", text: $text, onEditingChanged: onEditingChange(_:), onCommit: onCommit)
            .textFieldStyle(PlainTextFieldStyle())
            .focusable(true)
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
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                    if let window = NSApp.keyWindow,
                       let toolbar = window.toolbar {
                        dbg("attempt focus in:", toolbar, toolbar.visibleItems)
                        
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
                    }
                }
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
        } else if !string.contains(where: \.isWhitespace), string.contains("."), let url = URL(string: string) {
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

