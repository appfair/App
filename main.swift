import App
import Foundation

///
/// **DO NOT MODIFY**
///
/// This is the entry point for the app, which is defined in App.AppContainer.
/// It is the **only** code that may be included in the Xcode `project.xcodeproj`,
/// and it must remain unmodified on order to the app to be eligable for App Fair distribution.
@available(macOS 12.0, iOS 15.0, *)
@main public enum App {
    public static func main() async throws {
        try await AppContainer.main()
    }
}
