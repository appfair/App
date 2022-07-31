import App
import Foundation

/// This is the entry point for the app, which is defined in App.AppContainer.
/// It is the only code unit that is defined directly in project.xcodeproj
@main public enum App {
    public static func main() async throws {
        try await AppContainer.main()
    }
}
