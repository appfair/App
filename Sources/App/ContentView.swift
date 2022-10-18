import FairApp

/// The main content view for the app. This is the starting point for customizing you app's behavior.
struct ContentView: View {
    @EnvironmentObject var store: Store

    public var body: some View {
        TuneOutView()
    }
}
