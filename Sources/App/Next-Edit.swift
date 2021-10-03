import FairApp
import CodeEditor

@available(macOS 12.0, iOS 15.0, *)
struct CodeEditorView : View {
    @State var text = wip("Welcome to Next Edit!")

    var body: some View {
        CodeEditor(text: $text)
    }
}

/// Work-in-Progress marker
@available(*, deprecated, message: "work in progress")
internal func wip<T>(_ value: T) -> T { value }
