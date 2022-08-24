import FairApp

/// The main content view for the app.
public struct ContentView: View {
    @EnvironmentObject var store: Store

    public var body: some View {
        VStack {
            Text("Welcome to **\(Bundle.main.bundleName!)**")
                .font(.largeTitle)
            Text("(it doesn't do anything _yet_)")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// The shared app environment containing static configuration and
/// global properties and defaults.
///
/// The singleton instance of Store is available throughout the app with:
/// ``@EnvironmentObject var store: Store```
@MainActor public final class Store: SceneManager {
    /// The shared static configuration for this app.
    ///
    /// Shared configuration parameters for the app are be stored in the `App.yml` file at the root of the package.
    ///
    /// - Note: Failure to parse the YAML source is fatal.
    public static let configuration: JSum = try! JSum.parse(yaml: String(data: Bundle.module.loadResource(named: "App.yml"), encoding: .utf8)!)

    /// Mutable persistent global state for the app using ``SwiftUI/AppStorage``.
    @AppStorage("someToggle") public var someToggle = false
}

public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        WindowGroup {
            ContentView().environmentObject(store)
        }
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store: Store) -> some SwiftUI.View {
        AppSettingsView().environmentObject(store)
    }
}

public struct AppSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Toggle(isOn: $store.someToggle) {
            Text("Toggle")
        }
        .padding()
    }
}
