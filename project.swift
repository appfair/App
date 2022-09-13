import App
import Foundation

/// This is the entry point for the app, which is defined in App.AppContainer.
/// It is the only code unit that is defined directly in project.xcodeproj
@available(macOS 12.0, iOS 15.0, *)
@main public enum App {
    public static func main() async throws {
        try await AppContainer.main()
    }
}
