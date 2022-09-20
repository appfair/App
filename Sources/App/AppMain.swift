import FairApp

/// The `FairContainer` for the current app is the entry point 
/// to the app's initial launch, both in CLI and GUI forms.
///
/// - Note: This source in `AppMain.swift` must not be modified; 
///         App customization should be done in `AppContainer.swift`
@available(macOS 12.0, iOS 15.0, *)
@main public enum AppContainer : FairApp.FairContainer {
    public static func main() async throws { try await launch(bundle: Bundle.module) }
}

// MARK: Parochial Conveniences

/// Work-in-Progress marker: returns the value unmodified, but raises a warning to revisit the code.
@available(*, deprecated, message: "work in progress")
@inlinable internal func wip<T>(_ value: T) -> T { value }

#if canImport(SwiftUI)
extension Text {
    /// Clients should use the localized form of `Text.init` in order
    /// to take advantage of the provided Localizable.strings localizations.
    @available(*, deprecated, renamed: "Text.init(_:bundle:comment:)")
    internal init(_ key: LocalizedStringKey) {
        self.init(key, bundle: .module, comment: "no comment")
    }
}
#endif

