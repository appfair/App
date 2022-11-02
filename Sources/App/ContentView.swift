import FairApp

/// The main content view for the app. This is the starting point for customizing you app's behavior.
struct ContentView: View {
    @EnvironmentObject var store: Store

    public var body: some View {
        NavigationView {
            JackScriptListView()
                .navigation(title: Text("SDUI", bundle: .module, comment: "header title for app"), subtitle: nil)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Store())
    }
}
