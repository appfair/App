import FairApp
import JackPot
import FairKit

/// A list of sections of available files
public struct JackScriptListView: View {
    @EnvironmentObject var store: Store

    public var body: some View {
        List {
            JackScriptFileListView()
            JackScriptCatalogListView()
        }
        .refreshable {
            await store.loadFileStore(reload: true)
            await store.loadCatalog(reload: true)
        }
        #if os(macOS)
        .listStyle(.sidebar)
        #endif
    }
}

/// A list of files available to the user
public struct JackScriptFileListView: View {
    @EnvironmentObject var store: Store
    @State var fileOpen = false

    public var body: some View {
        Section {
            ForEach(store.fileStore?.apps ?? [], id: \.downloadURL) { scriptItem in
                NavigationLink(destination: {
                    JackScriptView(scriptItem: scriptItem)
                }, label: {
                    VStack(alignment: .leading) {
                        Text(scriptItem.localizedDescription ?? scriptItem.name)
                        Text(scriptItem.downloadURL.deletingLastPathComponent().lastPathComponent)
                            .truncationMode(.head)
                            .font(.subheadline)
                    }
                })
            }
        } header: {
            Text("File List", bundle: .module, comment: "header title for jackscript file list")
        }
        .toolbar {
            ToolbarItem {
                openFileButton
            }
        }
        .fileImporter(isPresented: $fileOpen, allowedContentTypes: [.item], onCompletion: openFile)
        .task {
            await store.loadFileStore()
        }
    }

    func openFile(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                try loadFile(url: url)
            } catch {
                store.addError(error)
            }
        case .failure(let error):
            store.addError(error)
        }
    }

    func loadFile(url: URL) throws {
        let data = try Data(contentsOf: url)
        let app = AppCatalogItem(name: url.lastPathComponent, bundleIdentifier: url.lastPathComponent, downloadURL: url)
        let catalog = AppCatalog(name: wip("File Store"), identifier: wip("World-Fair.local"), apps: [app])
        store.catalog = catalog
    }

    var openFileButton: some View {
        Button {
            dbg("opening files")
            fileOpen = true
        } label: {
            Text("Open", bundle: .module, comment: "button title for opening a script")
                .label(image: FairSymbol.plus)
                .labelStyle(.iconOnly)
        }
    }
}


/// The main content view for the app. This is the starting point for customizing you app's behavior.
public struct JackScriptCatalogListView: View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Section {
            ForEach(store.catalog?.apps ?? [], id: \.downloadURL) { scriptItem in
                NavigationLink(destination: {
                    JackScriptView(scriptItem: scriptItem)
                }, label: {
                    VStack(alignment: .leading) {
                        Text(scriptItem.localizedDescription ?? scriptItem.name)
                        Text(scriptItem.downloadURL.deletingLastPathComponent().lastPathComponent)
                            .truncationMode(.head)
                            .font(.subheadline)
                    }
                })
            }
        } header: {
            Text("GitHub Forks", bundle: .module, comment: "header title for jackscript forks")
        }
        .task {
            await store.loadCatalog()
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
            ScrollView {
                if editing {
                    editorView
                } else {
                    dynamicView
                }
            }
//            .tag(false) // non-editing
//            .tabItem {
//                Text("Execution", bundle: .module, comment: "tab title for execution")
//            }
        }
        .navigation(title: Text(scriptItem.localizedDescription ?? ""), subtitle: nil)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                reloadButton
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                saveEditButton
            }
            #endif
            #if os(macOS)
            ToolbarItem {
                reloadButton
                    .keyboardShortcut("R")
            }
            ToolbarItem {
                saveEditButton
                    .keyboardShortcut(.return)
            }
            #endif
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
            .font(.system(.body, design: .monospaced))
            #if os(iOS)
            .autocorrectionDisabled(true)
            .autocapitalization(.none)
            #endif
    }

    @ViewBuilder var dynamicView: some View {
        switch Result(catching: { try evaluateView().anyView }) {
        case .success(let success):
            success
                .animation(.default, value: script)
        case .failure(let error):
            Spacer()
            Text("ERROR: \(String(describing: dump(error, name: "error in rendering view")))")
                .textSelection(.enabled)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Spacer()
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
