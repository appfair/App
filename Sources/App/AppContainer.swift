/**
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import FairApp
import UniformTypeIdentifiers

// The entry point to creating your app is the `AppContainer` type,
// which is a stateless enum declared in `AppMain.swift` and may not be changed.
// 
// App customization is done via extensions in `AppContainer.swift`,
// which enables customization of the root scene, app settings, and
// other features of the app.


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
        UTType.data,
        UTType(importedAs: "org.iso.sql"),
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
    /// The body of your scene is provided by `AppContainer.scene`
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        DocumentGroup(newDocument: TextFile()) { file in
            ContentView(document: file.$document)
        }
//        WindowGroup {
//            ContentView().environmentObject(store)
//        }
        .commands {
            TextEditingCommands()
            // TextFormattingCommands() // Next Edit is a plain text editor
        }
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store: Store) -> some SwiftUI.View {
        AppSettingsView().environmentObject(store)
    }
}

/// The shared app environment
@available(macOS 12.0, iOS 15.0, *)
@MainActor public final class Store: AppStoreObject {
    @AppStorage("someToggle") public var someToggle = false
}

@available(macOS 12.0, iOS 15.0, *)
public struct ContentView: View {
    @EnvironmentObject var store: Store
    @Binding var document: TextFile

    public var body: some View {
        CodeEditorView(text: $document.text)
    }
}

@available(macOS 12.0, iOS 15.0, *)
public struct AppSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        EmptyView()
    }
}

