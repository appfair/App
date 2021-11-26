import FairApp
import SyntaxEditor

@available(macOS 12.0, iOS 15.0, *)
struct SyntaxEditorView : View {
    @Binding var text: String

    var body: some View {
        SyntaxEditor(text: $text)
    }
}

/// Work-in-Progress marker
@available(*, deprecated, message: "work in progress")
internal func wip<T>(_ value: T) -> T { value }
