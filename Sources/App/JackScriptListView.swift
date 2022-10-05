import FairApp

/// The main content view for the app. This is the starting point for customizing you app's behavior.
public struct JackScriptListView: View {
    @EnvironmentObject var store: Store

    public var body: some View {
        List {
            ForEach(store.catalog?.apps ?? [], id: \.bundleIdentifier) { scriptItem in
                NavigationLink(destination: {
                    JackScriptView(scriptItem: scriptItem)
                }, label: {
                    Text(scriptItem.localizedDescription ?? scriptItem.name)
                })
            }
        }
        .refreshable {
            await store.loadCatalog()
        }
        .task {
            await store.loadCatalog()
        }
    }
}

/// The main content view for the app. This is the starting point for customizing you app's behavior.
public struct JackScriptView: View {
    @EnvironmentObject var store: Store
    let scriptItem: AppCatalogItem

    public var body: some View {
        Text(scriptItem.name)
    }
}
