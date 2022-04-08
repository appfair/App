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
