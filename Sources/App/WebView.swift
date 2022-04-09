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

/// A view that displays a web page.
public struct WebView : View {
    fileprivate var state: BrowserState
    @State private var defaultDialog: Dialog? = nil
    private var customDialog: Binding<Dialog?>? = nil
    fileprivate var dialog: Dialog? {
        get { (self.customDialog ?? self.$defaultDialog).wrappedValue }
        nonmutating set { (self.customDialog ?? self.$defaultDialog).wrappedValue = newValue }
    }
    private var useInternalDialogHandling = true

    public init(state: BrowserState, dialog: Binding<Dialog?>? = nil) {
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
        #if os(macOS)
        view.allowsMagnification = true
        #endif
        
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

extension WebViewRepresentable : UXViewRepresentable {
    func makeUXView(context: Context) -> WKWebView {
        makeView(coordinator: context.coordinator, environment: context.environment)
    }

    func updateUXView(_ uxView: WKWebView, context: Context) {
        updateView(uxView, coordinator: context.coordinator, environment: context.environment)
    }

    static func dismantleUXView(_ uxView: WKWebView, coordinator: Coordinator) {
        dismantleView(uxView, coordinator: coordinator)
    }
}

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

    subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<BrowserState, T>) -> T {
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
    public func webViewNavigationPolicy(onAction actionDecider: @escaping (NavigationAction, BrowserState) -> Void) -> some View {
        environment(\.navigationActionDecider, actionDecider)
    }

    public func webViewNavigationPolicy(onResponse responseDecider: @escaping (NavigationResponse, BrowserState) -> Void) -> some View {
        environment(\.navigationResponseDecider, responseDecider)
    }

    public func webViewNavigationPolicy(onAction actionDecider: @escaping (NavigationAction, BrowserState) -> Void, onResponse responseDecider: @escaping (NavigationResponse, BrowserState) -> Void) -> some View {
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
        static let defaultValue: ((NavigationAction, BrowserState) -> Void)? = nil
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
        static let defaultValue: ((NavigationResponse, BrowserState) -> Void)? = nil
    }
}

extension EnvironmentValues {
    var navigationActionDecider: ((NavigationAction, BrowserState) -> Void)? {
        get { self[NavigationAction.DeciderKey.self] }
        set { self[NavigationAction.DeciderKey.self] = newValue }
    }

    var navigationResponseDecider: ((NavigationResponse, BrowserState) -> Void)? {
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
