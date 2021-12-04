import FairApp
import UniformTypeIdentifiers

/// The main content view for the app.
public struct ContentView: View {
    @EnvironmentObject var store: Store

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

//extension UTType {
//    static var exampleText: UTType {
//        UTType(importedAs: "com.example.plain-text")
//    }
//}

struct TextFile: FileDocument {
    var text: String

    init(text: String = "") {
        self.text = text
    }

    static var readableContentTypes: [UTType] { [
        UTType.text,
        UTType.plainText,
        UTType.tabSeparatedText,
        UTType.delimitedText,
        UTType.commaSeparatedText,
        UTType.data,
        //UTType(importedAs: "org.iso.sql"),
    ] }

    static var writableContentTypes: [UTType] { [
        UTType.plainText, // needed to default to .txt extension
        //UTType.text,
        //UTType.data,
        //UTType(importedAs: "org.iso.sql"),
    ] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return .init(regularFileWithContents: data)
    }
}

@available(macOS 12.0, iOS 15.0, *)
public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        DocumentGroup(newDocument: TextFile()) { file in
            ContentView(document: file.$document)
        }
//        WindowGroup {
//            ContentView().environmentObject(store)
//        }
        .commands {
            TextEditingCommands()
            TextFormattingCommands() // Next Edit is a plain text editor, but we need this for font sizxe increase & decrease
        }
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
