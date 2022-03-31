import SwiftUI
import WebKit

/// A view that displays a web page.
public struct WebView : View {
    fileprivate var state: WebViewContainer
    @State private var defaultDialog: Dialog? = nil
    private var customDialog: Binding<Dialog?>? = nil
    fileprivate var dialog: Dialog? {
        get { (self.customDialog ?? self.$defaultDialog).wrappedValue }
        nonmutating set { (self.customDialog ?? self.$defaultDialog).wrappedValue = newValue }
    }
    private var useInternalDialogHandling = true

    public init(state: WebViewContainer, dialog: Binding<Dialog?>? = nil) {
        self.state = state
        self.customDialog = dialog
        self.useInternalDialogHandling = dialog == nil
    }

    public var body: some View {
        WebViewRepresentable(owner: self)
            .overlay(dialogView)
    }

    @ViewBuilder
    private var dialogView: some View {
        if useInternalDialogHandling, let configuration = dialog?.configuration {
            switch configuration {
            case let .javaScriptAlert(message, completion):
                JavaScriptAlert(message: message, completion: {
                    dialog = nil
                    completion()
                })
            case let .javaScriptConfirm(message, completion):
                JavaScriptConfirm(message: message, completion: {
                    dialog = nil
                    completion($0)
                })
            case let .javaScriptPrompt(message, defaultText, completion):
                JavaScriptPrompt(message: message, defaultText: defaultText, completion: {
                    dialog = nil
                    completion($0)
                })
            }
        } else {
            EmptyView().hidden()
        }
    }

    /// Checks whether or not WebView can handle the given URL by default.
    public static func canHandle(_ url: URL) -> Bool {
        return url.scheme.map(WKWebView.handlesURLScheme(_:)) ?? false
    }
}

private struct WebViewRepresentable {
    let owner: WebView

    func makeView(coordinator: Coordinator, environment: EnvironmentValues) -> WKWebView {
        let view = WKWebView()
        view.navigationDelegate = coordinator
        view.uiDelegate = coordinator
        coordinator.webView = view
        coordinator.environment = environment

        if let request = coordinator.initialRequest {
            view.load(request)
        }

        return view
    }

    func updateView(_ view: WKWebView, coordinator: Coordinator, environment: EnvironmentValues) {
        coordinator.environment = environment

        if let flag = environment.allowsBackForwardNavigationGestures {
            view.allowsBackForwardNavigationGestures = flag
        }
    }

    static func dismantleView(_ view: WKWebView, coordinator: Coordinator) {
        coordinator.webView = nil
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(owner: owner)
    }
}

#if os(macOS)
extension WebViewRepresentable : NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView {
        makeView(coordinator: context.coordinator, environment: context.environment)
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        updateView(nsView, coordinator: context.coordinator, environment: context.environment)
    }

    static func dismantleNSView(_ nsView: WKWebView, coordinator: Coordinator) {
        dismantleView(nsView, coordinator: coordinator)
    }
}
#else
extension WebViewRepresentable : UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        makeView(coordinator: context.coordinator, environment: context.environment)
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        updateView(uiView, coordinator: context.coordinator, environment: context.environment)
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        dismantleView(uiView, coordinator: coordinator)
    }
}
#endif

@dynamicMemberLookup
private final class Coordinator : NSObject, WKNavigationDelegate, WKUIDelegate {
    private var owner: WebView
    fileprivate var environment: EnvironmentValues?

    init(owner: WebView) {
        self.owner = owner
    }

    var webView: WKWebView? {
        get { owner.state.webView }
        set { owner.state.webView = newValue }
    }

    subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<WebViewContainer, T>) -> T {
        get { owner.state[keyPath: keyPath] }
        set { owner.state[keyPath: keyPath] = newValue }
    }

    // MARK: Navigation

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        if let decider = environment?.navigationActionDecider {
            let action = NavigationAction(
                navigationAction, webpagePreferences: preferences, reply: decisionHandler)
            decider(action, owner.state)
        } else {
            decisionHandler(.allow, preferences)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let decider = environment?.navigationResponseDecider {
            let response = NavigationResponse(navigationResponse, reply: decisionHandler)
            decider(response, owner.state)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        owner.dialog = .javaScriptAlert(message, completion: completionHandler)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        owner.dialog = .javaScriptConfirm(message, completion: completionHandler)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        owner.dialog = .javaScriptPrompt(
            prompt, defaultText: defaultText ?? "", completion: completionHandler)
    }
}

public struct Dialog : Identifiable, Hashable {
    public var id = ID()

    public var configuration: Configuration

    public init(id: ID = ID(), _ configuration: Configuration) {
        self.id = id
        self.configuration = configuration
    }

    public static func javaScriptAlert(id: ID = ID(), _ message: String, completion: @escaping () -> Void) -> Self {
        Dialog(id: id, .javaScriptAlert(message, completion))
    }

    public static func javaScriptConfirm(id: ID = ID(), _ message: String, completion: @escaping (Bool) -> Void
    ) -> Self {
        Dialog(id: id, .javaScriptConfirm(message, completion))
    }

    public static func javaScriptPrompt(id: ID = ID(), _ message: String, defaultText: String = "", completion: @escaping (String?) -> Void) -> Self {
        Dialog(id: id, .javaScriptPrompt(message, defaultText: defaultText, completion))
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Dialog, rhs: Dialog) -> Bool {
        lhs.id == rhs.id
    }

    public struct ID : Hashable {
        private var rawValue = UUID()

        public init() {
        }
    }

    public enum Configuration {
        case javaScriptAlert(String, () -> Void)
        case javaScriptConfirm(String, (Bool) -> Void)
        case javaScriptPrompt(String, defaultText: String, (String?) -> Void)
    }
}

private struct DialogHost<Contents, Actions> : View where Contents : View, Actions : View {
    var contents: Contents
    var actions: Actions

    init(@ViewBuilder contents: () -> Contents, @ViewBuilder actions: () -> Actions) {
        self.contents = contents()
        self.actions = actions()
    }

    var body: some View {
        ZStack {
            Color(white: 0, opacity: 0.15)

            VStack(spacing: 0) {
                VStack(alignment: .leading) {
                    contents
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

                Divider()

                HStack(spacing: 12) {
                    Spacer()
                    actions
                        .buttonStyle(_LinkButtonStyle())
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .frame(maxWidth: 300)
            .background(RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color.platformBackground)
                            .shadow(radius: 12))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.platformSeparator))
        }
    }
}

#if os(macOS)
private typealias _LinkButtonStyle = LinkButtonStyle
#else
private struct _LinkButtonStyle : ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.blue)
    }
}
#endif

/// A view providing the WebKit-default UI for a JavaScript alert.
struct JavaScriptAlert : View {
    private var message: String
    private var completion: () -> Void

    init(message: String, completion: @escaping () -> Void) {
        self.message = message
        self.completion = completion
    }

    var body: some View {
        DialogHost {
            Text(message)
        } actions: {
            Button("OK", action: completion)
                .keyboardShortcut(.return)
        }
    }
}

/// A view providing the WebKit-default UI for a JavaScript alert.
struct JavaScriptConfirm : View {
    private var message: String
    private var completion: (Bool) -> Void

    init(message: String, completion: @escaping (Bool) -> Void) {
        self.message = message
        self.completion = completion
    }

    var body: some View {
        DialogHost {
            Text(message)
        } actions: {
            Button("Cancel", action: { completion(false) })
                .keyboardShortcut(".")
            Button("OK", action: { completion(true) })
                .keyboardShortcut(.return)
        }
    }
}

/// A view providing the WebKit-default UI for a JavaScript alert.
struct JavaScriptPrompt : View {
    private var message: String
    private var completion: (String?) -> Void
    @State private var text: String

    init(message: String, defaultText: String = "", completion: @escaping (String?) -> Void) {
        self.message = message
        self._text = State(wrappedValue: defaultText)
        self.completion = completion
    }

    var body: some View {
        DialogHost {
            Text(message)
            TextField("Your Response", text: $text, onCommit: { completion(text) })
        } actions: {
            Button("Cancel", action: { completion(nil) })
                .keyboardShortcut(".")
            Button("OK", action: { completion(text) })
                .keyboardShortcut(.return)
        }
    }
}

extension View {
    public func webViewNavigationPolicy(onAction actionDecider: @escaping (NavigationAction, WebViewContainer) -> Void) -> some View {
        environment(\.navigationActionDecider, actionDecider)
    }

    public func webViewNavigationPolicy(onResponse responseDecider: @escaping (NavigationResponse, WebViewContainer) -> Void) -> some View {
        environment(\.navigationResponseDecider, responseDecider)
    }

    public func webViewNavigationPolicy(onAction actionDecider: @escaping (NavigationAction, WebViewContainer) -> Void, onResponse responseDecider: @escaping (NavigationResponse, WebViewContainer) -> Void) -> some View {
        environment(\.navigationActionDecider, actionDecider)
            .environment(\.navigationResponseDecider, responseDecider)
    }
}

/// Contains information about an action that may cause a navigation, used for making
/// policy decisions.
@dynamicMemberLookup
public struct NavigationAction {
    public typealias Policy = WKNavigationActionPolicy

    private var action: WKNavigationAction
    private var reply: (WKNavigationActionPolicy, WKWebpagePreferences) -> Void

    public private(set) var webpagePreferences: WKWebpagePreferences

    init(_ action: WKNavigationAction, webpagePreferences: WKWebpagePreferences, reply: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        self.action = action
        self.reply = reply
        self.webpagePreferences = webpagePreferences
    }

    public func decidePolicy(_ policy: Policy, webpagePreferences: WKWebpagePreferences? = nil) {
        reply(policy, webpagePreferences ?? self.webpagePreferences)
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<WKNavigationAction, T>) -> T {
        action[keyPath: keyPath]
    }

    fileprivate struct DeciderKey : EnvironmentKey {
        static let defaultValue: ((NavigationAction, WebViewContainer) -> Void)? = nil
    }
}

@dynamicMemberLookup
public struct NavigationResponse {
    public typealias Policy = WKNavigationResponsePolicy

    private var response: WKNavigationResponse
    private var reply: (Policy) -> Void

    init(_ response: WKNavigationResponse, reply: @escaping (Policy) -> Void) {
        self.response = response
        self.reply = reply
    }

    public func decidePolicy(_ policy: Policy) {
        reply(policy)
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<WKNavigationResponse, T>) -> T {
        response[keyPath: keyPath]
    }

    fileprivate struct DeciderKey : EnvironmentKey {
        static let defaultValue: ((NavigationResponse, WebViewContainer) -> Void)? = nil
    }
}

extension EnvironmentValues {
    var navigationActionDecider: ((NavigationAction, WebViewContainer) -> Void)? {
        get { self[NavigationAction.DeciderKey.self] }
        set { self[NavigationAction.DeciderKey.self] = newValue }
    }

    var navigationResponseDecider: ((NavigationResponse, WebViewContainer) -> Void)? {
        get { self[NavigationResponse.DeciderKey.self] }
        set { self[NavigationResponse.DeciderKey.self] = newValue }
    }
}

extension Color {
    static var platformSeparator: Color {
#if os(macOS)
        return Color(NSColor.separatorColor)
#else
        return Color(UIColor.separator)
#endif
    }

    static var platformBackground: Color {
#if os(macOS)
        return Color(NSColor.windowBackgroundColor)
#else
        return Color(UIColor.systemBackground)
#endif
    }
}

extension View {
    public func webViewAllowsBackForwardNavigationGestures(_ allowed: Bool) -> some View {
        environment(\.allowsBackForwardNavigationGestures, allowed)
    }
}

private struct WebViewAllowsBackForwardNavigationGesturesKey : EnvironmentKey {
    static let defaultValue: Bool? = nil
}

extension EnvironmentValues {
    var allowsBackForwardNavigationGestures: Bool? {
        get { self[WebViewAllowsBackForwardNavigationGesturesKey.self] }
        set { self[WebViewAllowsBackForwardNavigationGesturesKey.self] = newValue }
    }
}

public final class WebViewContainer : ObservableObject {
    var initialRequest: URLRequest?
    var webViewObservations: [NSKeyValueObservation] = []
    var webView: WKWebView? {
        didSet {
            webViewObservations.forEach { $0.invalidate() }
            guard let webView = webView else {
                webViewObservations.removeAll()
                return
            }

            func register<T>(_ keyPath: KeyPath<WKWebView, T>) -> NSKeyValueObservation where T : Equatable {
                webView.observe(keyPath, options: [.prior, .old, .new], changeHandler: webView(_:didChangeKeyPath:))
            }

            webViewObservations = [
                register(\.canGoBack),
                register(\.canGoForward),
                register(\.title),
                register(\.url),
                register(\.isLoading),
                register(\.estimatedProgress),
            ]
        }
    }

    public convenience init(initialURL: URL? = nil, configuration: WKWebViewConfiguration = .init()) {
        self.init(initialRequest: initialURL.map { URLRequest(url: $0) }, configuration: configuration)
    }

    public init(initialRequest: URLRequest?, configuration: WKWebViewConfiguration = .init()) {
        self.initialRequest = initialRequest
    }

    func webView<Value>(_: WKWebView, didChangeKeyPath change: NSKeyValueObservedChange<Value>) where Value : Equatable {
        if change.isPrior && change.oldValue != change.newValue {
            objectWillChange.send()
        }
    }

    public var canGoBack: Bool { webView?.canGoBack ?? false }
    public var canGoForward: Bool { webView?.canGoForward ?? false }
    public var title: String { webView?.title ?? "" }
    public var url: URL? { webView?.url }
    public var isLoading: Bool { webView?.isLoading ?? false }
    public var estimatedProgress: Double? { isLoading ? webView?.estimatedProgress : nil }
    public var hasOnlySecureContent: Bool { webView?.hasOnlySecureContent ?? false }

    public func load(_ url: URL?) {
        if let url = url {
            load(URLRequest(url: url))
        }
    }

    public func load(_ request: URLRequest) {
        webView?.load(request)
    }

    public func goBack() {
        webView?.goBack()
    }

    public func goForward() {
        webView?.goForward()
    }

    public func reload() {
        webView?.reload()
    }

    public func stopLoading() {
        webView?.stopLoading()
    }

    func createPDF(configuration: WKPDFConfiguration = .init(), completion: @escaping (Result<Data, Error>) -> Void) {
        if let webView = webView {
            webView.createPDF(configuration: configuration, completionHandler: completion)
        } else {
            completion(.failure(WKError(.unknown)))
        }
    }
}
