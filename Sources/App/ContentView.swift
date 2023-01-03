import FairApp
import JXSwiftUI
import JXKit

/// The main content view for the app. This is the starting point for customizing you app's behavior.
struct ContentView: View {
    let context = JXContext()
    @EnvironmentObject var store: Store

    var body: some View {
        VStack {
//            let _ = JXView(content: context) { ctx in
//                try ctx.null()
//            }

            Text("Welcome to \(Locale.appName())!", bundle: .module, comment: "welcome title")
                .font(.title)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Store())
    }
}
