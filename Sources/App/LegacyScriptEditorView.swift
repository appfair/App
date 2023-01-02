import FairApp
import JXPod
import JXKit
import JXBridge

/// A script editor / preview
struct LegacyScriptEditorView: View {
    @EnvironmentObject var store: Store
    @AppStorage("scriptContents") var scriptContents = """
    var timeThen = new Date().getTime();
    await time.sleep(0.1);
    _cb.callback("Tick");
    await time.sleep(0.7);
    _cb.callback("Tock");
    await time.sleep(0.9);
    var timeNow = new Date().getTime();
    return { "then": timeThen, "now": timeNow };
    """
    @State var selection: Selection = .editor
    @State var scriptResults: [Result<JXValue, Error>] = []
    @State var running: Bool = false

    enum Selection : Hashable, Identifiable, CaseIterable {
        case editor
        case preview
        var id: Self { self }
    }

    public var body: some View {
        VStack {
            Picker("", selection: $selection) {
                Text("Editor", bundle: .module, comment: "tab label for editor")
                    .tag(Selection.editor)
                Text("Preview", bundle: .module, comment: "tab label for preview")
                    .tag(Selection.preview)
            }
            .pickerStyle(.segmented)

            switch selection {
            case .editor:
                editorView()
                    .onAppear {
                        // clear the result each time we show
                        self.scriptResults = []
                    }
            case .preview:
                previewView()
                    .task(id: self.scriptContents) {
                        await performScript()
                    }
            }
        }
        .toolbar(id: "editorToolbar") {
            ToolbarItem(id: "cycleTabs") {
                Text("Cycle Tabs", bundle: .module, comment: "toolbar button title for changing tabs")
                    .label(image: FairSymbol.app)
                    .keyboardShortcut("s") // not working?
                    .button {
                        cycleTabs()
                    }
            }
        }
    }

    func cycleTabs() {
        self.selection = self.selection == .preview ? .editor : .preview
    }

    func editorView() -> some View {
        CodeEditor(language: .javaScript, text: $scriptContents)
            .autocorrectionDisabled(true)
            .font(.body.monospaced())
    }

    func scriptResultString(for result: Result<JXValue, Error>) -> String {
        switch result {
        case .failure(let error):
            return "Execution error: \(error)"
        case .success(let value):
            do {
                return try value.toJSON(indent: 0)
            } catch {
                return "Conversion error: \(error)"
            }
        }
    }

    func previewView() -> some View {
        List {
            Section {
                ForEach(enumerated: scriptResults) { index, result in
                    Text(scriptResultString(for: result))
                        .font(.body.monospaced())
                        .foregroundColor(result.failureValue != nil ? .red : nil)
                        .textSelection(.enabled)

                }
            } header: {
                HStack {
                    Text("Script Results", bundle: .module, comment: "list header string")
                    Spacer()
                    if running == true {
                        ProgressView()
                    } else if scriptResults.contains(where: { $0.failureValue != nil }) {
                        Image("exclamationmark.octagon.fill")
                    } else {
                        Image("checkmark.square.fill")
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshableIfSupported {
            // re-execute the script
            await performScript()
        }
    }

    @MainActor func performScript() async {
        self.running = true
        defer { self.running = false }

        self.scriptResults.removeAll()
        do {
            self.scriptResults.append(.success(try await executeScript()))
        } catch {
            self.scriptResults.append(.failure(error))
        }
    }

    func executeScript() async throws -> JXValue {
        // TODO: rather than being re-created each time, the JXContent should probably live in either the Store, or in some document-specific view model
        let jxc = JXContext()

        // register all the pods we will be using here…
        try jxc.registry.register(TimePod())
        try jxc.registry.register(CallbackPod(callback: { value in
            dbg("callback:", value)
            self.scriptResults.append(.success(value))
        }))

        // wrap the script contents in an async block so await can be used fluently
        let script = """
        (async () => {
        \(scriptContents)
        })()
        """

        dbg("evaluating:", script)
        return try await jxc.eval(script, priority: .high)
    }
}

import JXBridge

/// Simple callback interface for the sample script
class CallbackPod: JXPod, JXModule, JXBridging {
    let block: (JXValue) -> ()

    init(callback block: @escaping (JXValue) -> ()) {
        self.block = block
    }

    var metadata: JXPodMetaData {
        JXPodMetaData(homePage: URL(string: "https://www.example.com")!)
    }

    let namespace: JXNamespace = "_cb"

    func register(with registry: JXRegistry) throws {
        try registry.registerBridge(for: self, namespace: namespace)
    }

    func initialize(in context: JXContext) throws {
        try context.global.integrate(self)
    }

    @JXFunc var jxcallback = callback
    func callback(value: JXValue) async throws {
        self.block(value)
    }
}
