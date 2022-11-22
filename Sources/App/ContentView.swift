import FairApp

/// The main content view for the app. This is the starting point for customizing you app's behavior.
struct ScriptEditorView: View {
    @EnvironmentObject var store: Store

    public var body: some View {
        NavigationView {
            JackScriptListView()
                .navigation(title: Text("Scripts", bundle: .module, comment: "header title for app"), subtitle: nil)
        }
    }
}

/// The main content view for the app. This is the starting point for customizing you app's behavior.
struct JackScriptNavView: View {
    @EnvironmentObject var store: Store

    public var body: some View {
        NavigationView {
            JackScriptListView()
                .navigation(title: Text("Scripts", bundle: .module, comment: "header title for app"), subtitle: nil)
        }
    }
}
