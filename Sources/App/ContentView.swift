import FairApp

/// The main content view for the app. This is the starting point for customizing you app's behavior.
public struct ContentView: View {
    @EnvironmentObject var store: Store

    public var body: some View {
        VStack {
            Text("Welcome to **\(store.appName)**", bundle: .module, comment: "welcome title")
                .font(.largeTitle)
            Text("(coming very soon)", bundle: .module, comment: "welcome subtitle")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
