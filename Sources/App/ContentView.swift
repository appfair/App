import FairApp

/// The main content view for the app. This is the starting point for customizing you app's behavior.
public struct ContentView: View {
    @EnvironmentObject var store: Store

    public var body: some View {
        NavigationView {
            JackScriptListView()
                .navigation(title: Text("Jack Scripts"), subtitle: nil)
        }
    }
}
