import FairApp
import UniformTypeIdentifiers
import JXPod
import JXKit
import JXBridge
import JXSwiftUI
import Runestone

@MainActor class ProjectScriptManager : ObservableObject {
    @Published var projectURL: URL?
    @Published var fileNode: FileNode? = nil
    let context = JXContext()

    init() {
    }

    func load(projectURL url: URL?) throws {
        self.fileNode = nil
        if let url = projectURL {
            dbg("opening:", url.path)
            self.fileNode = FileNode(name: url.lastPathComponent, url: url, wrapper: try FileWrapper(url: url))
        }
    }

    func setupContent(context: JXContext) throws -> JXValue {
        try context.registry.register(ScriptManagerModule())
        return try context.new("wf.MyView")
    }

    struct ScriptManagerModule: JXModule {
        var namespace: JXNamespace = JXNamespace("wf")

        func register(with registry: JXRegistry) throws {
            try registry.register(JXSwiftUI())
            try registry.registerModuleScript("""
            jxswiftui.import();

            class TextSliderView extends View {
                constructor(text) {
                    super();
                    this.text = text;
                    this.state.sliderValue = 0.5;
                }

                body() {
                    return VStack([
                        Text(this.text),
                        Slider(this.state.$sliderValue),
                        Text('Value: ' + this.state.sliderValue.toFixed(4))
                    ])
                    .padding()
                }
            }

            exports.MyView = class extends View {
                constructor() {
                    super();
                    this.state.sliderValue = 0.5
                }

                body() {
                    let i = 0;
                    return ScrollView(
                        VStack([
                            Group([
                                Text('Master view:'),
                                Slider(this.state.$sliderValue).padding(),
                                new TextSliderView('Updating child view: ' + this.state.sliderValue.toFixed(4)),
                            ]),
                            Group([
                                new TextSliderView('View ' + (i++)),
                                new TextSliderView('View ' + (i++)),
                            ]),
                        ])
                    )
                }
            }
            """, namespace: namespace)
        }
    }

}

struct ScriptNavigatorView : View {
    @EnvironmentObject var store: Store
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @StateObject var projectScriptManager = ProjectScriptManager()

    @State var sidebarVisible: NavigationSplitViewVisibility = .all

    @State var createProject: Bool = false
    @State var openProject: Bool = false

    @State var selection: URL? = nil
    @State var selectionContents = ""

    var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisible, sidebar: sidebarView, detail: detailSplitView /* content: codeEditorView, detail: detailView */)
            .navigationSplitViewStyle(.automatic)
            .fileImporter(isPresented: $openProject, allowedContentTypes: [.folder], onCompletion: openFolder)
            .fileExporter(isPresented: $createProject, document: Doc(), contentType: .folder, onCompletion: openFolder)
            .onChange(of: projectScriptManager.projectURL, perform: openProjectURL)
            .task(id: selection) {
                await loadSelectionContents()
            }
            .onAppear {
                openProjectURL(url: projectScriptManager.projectURL)
            }
    }

    func loadSelectionContents() async {
        await store.trying {
            selectionContents = ""
            if let selection = selection {
                var encoding: String.Encoding = .utf8
                self.selectionContents = try String(contentsOf: selection, usedEncoding: &encoding)
            }
        }
    }

    func openProjectURL(url: URL?) {
        dbg(url?.path)

        store.trying {
            try projectScriptManager.load(projectURL: url)
        }
    }

    @ViewBuilder func sidebarView() -> some View {
        if let fileNode = projectScriptManager.fileNode {
            List(selection: $selection) {
                OutlineGroup(fileNode.fileChildren ?? [], id: \.url, children: \.fileChildren, content: outlineLabel)
            }
        } else {
            emptySidebarView()
        }
    }

    func outlineLabel(node: FileNode) -> some View {
        NavigationLink(value: node.url) {
            //TextField("", text: .constant(node.name))
            Text(node.name)
                .label(image: node.wrapper.isDirectory ? FairSymbol.folder : info(for: node.url).icon)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    private func createTemplateWrapper() -> Doc {
        return Doc()
    }

    private struct Doc : FileDocument {
        static var readableContentTypes: [UTType] {
            [.folder]
        }

        init() {
        }

        init(configuration: ReadConfiguration) throws {
        }

        func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            try ScriptTemplateManager.shared.createTemplateWrapper()
        }
    }

    func openFolder(result: Result<URL, Error>) {
        store.trying {
            projectScriptManager.projectURL = try result.get()
        }
    }

    func emptySidebarView() -> some View {
        VStack {
            Spacer()
            Button {
                self.openProject = true
            } label: {
                Text("Open Project", bundle: .module, comment: "button text for opening a project")
                    .label(image: FairSymbol.doc_text)
                    //.keyboardShortcut("O") // ⌘-O
            }
            Button {
                self.createProject = true
            } label: {
                Text("Create Project", bundle: .module, comment: "button text for creating a new project")
                    .label(image: FairSymbol.pencil_and_outline)
            }
            Spacer()
        }
    }

    @ViewBuilder func codeEditorView() -> some View {
        Group {
            if let url = self.selection {
                if let lang = info(for: url).lang {
                    CodeEditor(language: lang, text: $selectionContents)
                        .id(url)
                } else {
                    Text(url.lastPathComponent)
                        .frame(maxWidth: .infinity)
                        .font(.title2.monospaced())
                }
            } else {
                Text("No Selection", bundle: .module, comment: "placeholder text for content split when no item is selected")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
            }
        }
        //.frame(width: 800)
    }

//    @ViewBuilder func detailView() -> some View {
//        if let url = self.projectURL {
//
//        } else {
//            Text("No Project", bundle: .module, comment: "placeholder text for detail split when no projecy is selected")
//                .font(.title2)
//        }
//    }


    @ViewBuilder func detailSplitView() -> some View {
        if horizontalSizeClass == .compact {
            previewView()
        } else {
            HStack {
                codeEditorView()
                Divider()
                previewView()
            }
        }
    }

    @ViewBuilder func previewView() -> some View {
        if let url = projectScriptManager.projectURL {
            ProjectPreviewView()
                .environmentObject(projectScriptManager)
        } else {
            Text("Empty Preview", bundle: .module, comment: "placeholder text for preview when no item is selected")
                .font(.title2)
                .frame(maxWidth: .infinity)
        }
    }

    func info(for url: URL) -> (icon: FairSymbol, lang: Runestone.TreeSitterLanguage?) {
        switch url.pathExtension {
        case "png", "jpg", "jpeg": return (.photo, nil)
        case "json": return (.square_fill_text_grid_1x2, .json)
        case "js", "javascript": return (.cube, .javaScript)
        case "swift": return (FairSymbol(rawValue: "swift"), .swift)
        case "md": return (.doc_richtext, .markdown)
        default: return (.doc, nil)
        }
    }
}

struct ProjectPreviewView : View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var projectScriptManager: ProjectScriptManager

    var body: some View {
        JXView(context: projectScriptManager.context, errorHandler: scriptError, content: projectScriptManager.setupContent)
    }

    func scriptError(error: Error) {
        dbg(error)
        store.addError(error)
    }
}


class FileNode {
    let name: String
    let url: URL
    let wrapper: FileWrapper

    init(name: String, url: URL, wrapper: FileWrapper) {
        self.name = name
        self.url = url
        self.wrapper = wrapper
    }

    var fileChildren: [FileNode]? {
        if !wrapper.isDirectory {
            return nil
        }

        guard let wrappers = wrapper.fileWrappers else {
            return nil
        }

        let sorted = wrappers.sorted { kv1, kv2 in
            if kv1.value.isDirectory != kv2.value.isDirectory {
                return kv2.value.isDirectory
            } else {
                return kv1.key.localizedStandardCompare(kv2.key) == .orderedAscending
            }
        }

        return sorted.map({ name, wrapper in
            FileNode(name: name, url: url.appendingPathComponent(name, isDirectory: wrapper.isDirectory), wrapper: wrapper)
        })
    }
}

//extension URL {
//    var children: [URL]? {
//        contentsOf(url: self)
//    }
//
//    private func contentsOf(url: URL) -> [URL]? {
//        do {
//            let dir = FileManager.default.isDirectory(url: url)
//            if dir != true {
//                return nil
//            }
//
//            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .includesDirectoriesPostOrder)
//            return contents
//        } catch {
//            dbg("error getting contents of:", url.path, error)
//            return nil
//        }
//    }
//}
