import FairApp
import UniformTypeIdentifiers

public struct ContentView: View {
    @EnvironmentObject var store: Store
    let document: Document

    public var body: some View {
        NavigationView {
            sidebarView()
            canvasView()
        }
    }

    func sidebarView() -> some View {
        List {
            Section("Sections") {
                Text("Hex")
            }
        }
        .symbolRenderingMode(.multicolor)
        .listStyle(.automatic)
    }

    func canvasView() -> some View {
        Canvas(opaque: true, rendersAsynchronously: true) { context, size in
            let data = document.data
            let ratio = size.width / size.height
            let columns = ceil(sqrt(.init(data.count) * ratio))
            let span = size.width / columns

            for i in data.indices {
                let row = i / .init(columns)
                let origin = CGPoint(x: (.init(i) * span) - (.init(row) * columns * span), y: .init(row) * span)
                
                let size = CGSize(width: span, height: span)
                let rect = CGRect(origin: origin, size: size)
                let color = Color(hue: Double(data[i]) / Double(UInt8.max), saturation: 0.75, brightness: 0.75)

                context.fill(Path(rect), with: .color(color))
            }
        }
        .drawingGroup()
    }
}

/// The global app environment containing configuration metadata and shared defaults.
///
/// The shared instance of Store is available throughout the app with:
/// ``@EnvironmentObject var store: Store``
open class Store: SceneManager {
    /// The configuration metadata for the app from the `App.yml` file.
    public static let config: JSum = configuration(for: .module)

    /// Mutable persistent global state for the app using ``SwiftUI/AppStorage``.
    @AppStorage("someToggle") public var someToggle = false

    public required init() {
    }
}

public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        HexScene()
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store: Store) -> some SwiftUI.View {
        AppSettingsView().environmentObject(store)
    }
}

public struct AppSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Toggle(isOn: $store.someToggle) {
            Text("Toggle")
        }
        .padding()
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct HexScene : Scene {
    var body: some Scene {
        DocumentGroup(viewing: Document.self) { file in
            ContentView(document: file.document)
            //.focusedSceneValue(\.document, file.document)
            //.environmentObject(file.document.sceneStore)
        }
        .commands {
            HexCommandMenu()
        }
    }
}

struct HexCommandMenu : Commands {
    var body : some Commands {
        CommandMenu(Text("Hex")) {
            InfoCommand()
                .keyboardShortcut(KeyboardShortcut(.space, modifiers: []))
        }
    }
}

struct InfoCommand : View {
    //    @FocusedValue(\.document) var document
    //
    //    var body: some View {
    //    }

    var body: some View {
        Text("Info")
            .button {
                dbg(wip("InfoCommand"))
            }
    }
}

struct Document: FileDocument {
    var data: Data

    static var readableContentTypes: [UTType] {
        [
            UTType.data,
        ]
    }
    static var writableContentTypes: [UTType] { [] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
