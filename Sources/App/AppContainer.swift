import FairApp
import UniformTypeIdentifiers

@available(macOS 12.0, iOS 15.0, *)
public struct ContentView: View {
    @Namespace var mainNamespace
    let document: Document
    @EnvironmentObject var appStore: Store
    @State var animationTime: TimeInterval = 0
    @State var searchString = ""

    public var body: some View {
        VStack {
            Text("Welcome to **\(Bundle.main.bundleName!)**")
                .font(.largeTitle)
            Text("(it doesn't do anything _yet_)")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// The shared app environment
@MainActor public final class Store: SceneManager {
    @AppStorage("someToggle") public var someToggle = false
}

public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        EBookScene()
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store: Store) -> some SwiftUI.View {
        AppSettingsView().environmentObject(store)
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct EBookScene : Scene {
    var body: some Scene {
        DocumentGroup(viewing: Document.self) { file in
            ContentView(document: file.document)
                .focusedSceneValue(\.document, file.document)
                //.environmentObject(file.document.sceneStore)
        }
//        .commands {
//            CommandGroup(after: .newItem) {
//                examplesMenu()
//            }
//        }
    }
}

extension FocusedValues {
    /// The store for the given scene
    var document: Document? {
        get { self[DocumentKey.self] }
        set { self[DocumentKey.self] = newValue }
    }

    private struct DocumentKey: FocusedValueKey {
        typealias Value = Document
    }
}

extension UTType {
    static var epub = UTType(importedAs: "app.Lex-Stanza.epub")
}

final class Document: ReferenceFileDocument {
    static let bundle = Bundle.module
    
    static var readableContentTypes: [UTType] {
        [
            UTType.epub,
            UTType.zip, // can also open epub zip files
        ]
    }
    static var writableContentTypes: [UTType] { [] }

    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        #warning("open and parse the book here")
    }

    func fileWrapper(snapshot: Void, configuration: WriteConfiguration) throws -> FileWrapper {
        throw AppError("Writing not yet supported")
    }

    func snapshot(contentType: UTType) throws -> Void {
        dbg("snapshot:", contentType)
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
