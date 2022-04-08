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

public class BrowserStateBase : ObservableObject {
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

    private var webViewObservations: [NSKeyValueObservation] = []

    /// Sends an `objectWillChange` whenever an observed value changes
    func webView<Value>(_: WKWebView, didChangeKeyPath change: NSKeyValueObservedChange<Value>) where Value : Equatable {
        if change.isPrior && change.oldValue != change.newValue {
            objectWillChange.send()
        }
    }


}

@MainActor public final class BrowserState : BrowserStateBase {
    var initialRequest: URLRequest?
    @Published public var errors: [NSError] = []

    public convenience init(initialURL: URL? = nil, configuration: WKWebViewConfiguration = .init()) {
        self.init(initialRequest: initialURL.map { URLRequest(url: $0) }, configuration: configuration)
    }

    public init(initialRequest: URLRequest?, configuration: WKWebViewConfiguration = .init()) {
        self.initialRequest = initialRequest
    }

    public var canGoBack: Bool { webView?.canGoBack ?? false }
    public var canGoForward: Bool { webView?.canGoForward ?? false }
    public var title: String { webView?.title ?? "" }
    public var url: URL? { webView?.url }
    public var isLoading: Bool { webView?.isLoading ?? false }
    public var estimatedProgress: Double? { isLoading ? webView?.estimatedProgress : nil }
    public var hasOnlySecureContent: Bool { webView?.hasOnlySecureContent ?? false }

    public var canEnterReaderView: Bool {
        url != nil && isLoading == false
    }

    /// Register that an error occurred with the app manager
    func reportError(_ error: Error) {
        errors.append(error as NSError)
    }

    /// Attempts to perform the given action and adds any errors to the error list if they fail.
    func trying(block: () async throws -> ()) async {
        do {
            try await block()
        } catch {
            reportError(error)
        }
    }

    @discardableResult func js(_ script: String) async throws -> Any? {
        try await webView?.callAsyncJavaScript(script, contentWorld: WKContentWorld.defaultClient)
    }

    public func enterReaderView() async {
        dbg()
        await self.trying {
            let readability = try Bundle.module.loadBundleResource(named: "Readability.js")
            dbg("loading readability library:", ByteCountFormatter().string(fromByteCount: .init(readability.count)))
            // load the readbility script
            try await js(readability.utf8String ?? "")

            // invoke the parser
            let result = try await js("new Readability(document).parse()")

            dbg("result:", result)
        }
    }

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
