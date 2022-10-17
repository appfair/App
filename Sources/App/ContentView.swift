import FairApp

/// The main content view for the app. This is the starting point for customizing you app's behavior.
struct ContentView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        VStack {
            Text("Welcome to \(Bundle.localizedAppName)!", bundle: .module, comment: "welcome title")
                .font(.title)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
