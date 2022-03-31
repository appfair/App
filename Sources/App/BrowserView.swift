import SwiftUI
import FairApp

/// A browser component that contains a URL/search field and a WebView
struct BrowserView : View {
    @EnvironmentObject var store: Store
    @AppStorage("themeStyle") var themeStyle = ThemeStyle.system
    @StateObject private var state = WebViewContainer()

    var body: some View {
        browserBody
            .preferredColorScheme(themeStyle.colorScheme)
    }

    var browserBody: some View {
        let content = WebView(state: state)
            .webViewNavigationPolicy(onAction: decidePolicy(for:state:))
            .alert(item: $externalNavigation, content: makeExternalNavigationAlert(_:))

#if os(macOS)
        return content
            .edgesIgnoringSafeArea(.all)
            .navigationTitle(state.title.isEmpty ? "Net Skip" : state.title)
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    backItem
                    forwardItem
                }
                ToolbarItem(placement: .principal) {
                    urlTextField
                }
            }
#else
        return content
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    backItem.labelStyle(IconOnlyLabelStyle())
                    forwardItem.labelStyle(IconOnlyLabelStyle())
                }
                ToolbarItem(placement: .principal) {
                    urlTextField
                }
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

    private var backItem: some View {
        Button(action: state.goBack) {
            Text("Back").label(image: FairSymbol.chevron_left)
                .frame(minWidth: 20)
        }
        .disabled(!state.canGoBack)
    }

    private var forwardItem: some View {
        Button(action: state.goForward) {
            Text("Forward").label(image: FairSymbol.chevron_right)
                .frame(minWidth: 20)
        }
        .disabled(!state.canGoForward)
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

    private func decidePolicy(for action: NavigationAction, state: WebViewContainer) {
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
    @Environment(\.resetFocus) var resetFocus
    #endif
    @Namespace private var namespace

    @EnvironmentObject var store: Store

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
            .disableAutocorrection(true)

#if os(iOS)
        return view
            .textContentType(.URL)
            .autocapitalization(.none)
#else
        return view
            .prefersDefaultFocus(in: namespace) // doesn't seem to work
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

