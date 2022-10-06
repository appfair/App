import FairApp
import JackPot


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
        .task {
            await store.loadCatalog()
        }
        .refreshable {
            await store.loadCatalog(reload: true)
        }
    }
}

/// The main content view for the app. This is the starting point for customizing you app's behavior.
public struct JackScriptView: View {
    let scriptItem: AppCatalogItem
    @State var script = ""
    @State var editing = false
    @StateObject var viewModel = ViewModel()
    @EnvironmentObject var store: Store

    class ViewModel: UIPod {
        lazy var jacked = Result { try jack() }
    }


    public var body: some View {
        Group {
            if editing {
                editorView
                    .padding()
            } else {
                ScrollView {
                    dynamicView
                }
            }
//            .tag(false) // non-editing
//            .tabItem {
//                Text("Execution", bundle: .module, comment: "tab title for execution")
//            }
        }
        .navigation(title: Text(scriptItem.localizedDescription ?? ""), subtitle: nil)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                reloadButton
                    .buttonStyle(.bordered)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                saveEditButton
                    .buttonStyle(.borderedProminent)
            }
        }
        .task {
            await loadScriptContents()
        }
        .refreshable {
            await loadScriptContents(reload: true)
        }
    }

    func evaluateView() throws -> ViewTemplate {
        try viewModel.jacked.get().ctx.eval(script).convey()
        //try viewModel.jack().ctx.eval(script).convey()
    }

    @ViewBuilder var editorView: some View {
        TextEditor(text: $script)
            .font(.system(.callout, design: .monospaced))
//            .autocorrectionDisabled(true)
//            .autocapitalization(.none)
    }

    @ViewBuilder var dynamicView: some View {
        switch Result(catching: { try evaluateView().anyView }) {
        case .success(let success):
            success
                .animation(.default, value: script)
        case .failure(let error):
            TextEditor(text: .constant("ERROR: \(String(describing: dump(error, name: "error in rendering view")))"))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    var saveEditButton: some View {
        Button {
            editing.toggle()
        } label: {
            editing ? Text("Preview", bundle: .module, comment: "preview button title") : Text("Edit", bundle: .module, comment: "edit button title")
        }
    }

    var reloadButton: some View {
        Button {
            Task.detached(priority: .userInitiated) {
                //withAnimation {
                    await loadScriptContents(reload: true)
                //}
            }
        } label: {
            Text("Reload", bundle: .module, comment: "reset the script to the default")
                .label(symbol: "arrow.triangle.2.circlepath")
                .labelStyle(.iconOnly)
        }
    }

    func loadScriptContents(reload: Bool = false) async {
        do {
            var urlString = scriptItem.downloadURL.absoluteString
            urlString = urlString.replacingOccurrences(of: "https://github.com", with: "https://raw.githubusercontent.com")
            guard let url = URL(string: urlString) else {
                return dbg("bad url")
            }

            let scriptURL = url.appendingPathComponent("main/Jack.javascript")
            let (data, _) = try await URLSession.shared.fetch(request: URLRequest(url: scriptURL, cachePolicy: reload ? .reloadIgnoringLocalAndRemoteCacheData : .useProtocolCachePolicy))
            let script = String(data: data, encoding: .utf8) ?? ""
            dbg("loaded script:", script)
            self.script = script
        } catch {
            store.addError(error)
        }
    }
}
