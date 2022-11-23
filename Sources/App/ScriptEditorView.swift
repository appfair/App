import FairApp
import JXPod
import JXKit

/// A script editor / preview
struct ScriptEditorView: View {
    @EnvironmentObject var store: Store
    @AppStorage("scriptContents") var scriptContents = """
    (async () => {
        var timeThen = Date();
        await time.sleep(1.0);
        var timeNow = Date();
        return { "then": timeThen, "now": timeNow };
    })()
    """
    @State var selection: Selection = .editor
    @State var scriptResult: Result<JXValue, Error>?

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
                        self.scriptResult = nil
                    }
            case .preview:
                previewView()
                    .task(id: self.scriptContents) {
                        do {
                            self.scriptResult = .success(try await executeScript())
                        } catch {
                            self.scriptResult = .failure(error)
                        }
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
        TextEditor(text: $scriptContents)
            .font(.body.monospaced())
    }

    func scriptResultString() -> String {
        switch scriptResult {
        case .none:
            return "running…"
        case .failure(let error):
            return "Execution error: \(error)"
        case .success(let value):
            do {
                return try value.toJSON(indent: 2)
            } catch {
                return "Conversion error: \(error)"
            }
        }
    }

    func previewView() -> some View {
        TextEditor(text: .constant(scriptResultString()))
            .background(Color.white)
            .font(.body.monospaced())
            .foregroundColor(scriptResult?.failureValue != nil ? .red : .gray)
            .textSelection(.enabled)
    }

    func executeScript() async throws -> JXValue {
        // TODO: rather than being re-created each time, the JXContent should probably live in either the Store, or in some document-specific view model
        let jxc = JXContext()

        // register all the pods we will be using here…
        try jxc.registry.register(TimePod())

        dbg("evaluating:", scriptContents)
        return try await jxc.eval(scriptContents, priority: .high)
    }
}
