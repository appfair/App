import FairApp
import SwiftUI

#if !canImport(Runestone)
typealias CodeEditor = TextEditor

extension CodeEditor {
    // No-op language constants
    enum Language {
        case javaScript
    }

    init(language: Language, text: Binding<String>) {
        self.init(text: text)
    }
}

#else
import Runestone
import TreeSitterJavaScriptRunestone
import TreeSitterJSONRunestone
import TreeSitterHTMLRunestone
import TreeSitterYAMLRunestone
import TreeSitterSwiftRunestone
import TreeSitterMarkdownRunestone
import TreeSitterTypeScriptRunestone

struct CodeEditor : View {
    let language: TreeSitterLanguage
    @Binding var text: String

    var body: some View {
        CodeView(language: language, text: $text, model: CodeEditorModel(editorFontSize: 12))
    }
}

private class CodeEditorModel : ObservableObject {
    @Published var editorFontSize: Double = 12

    init(editorFontSize: Double = 12) {
        self.editorFontSize = editorFontSize
    }
}

private struct CodeView: UXViewControllerRepresentable {
    let language: TreeSitterLanguage
    @Binding var text: String
    @ObservedObject var model: CodeEditorModel

    typealias UXViewControllerType = CodeEditorViewController

    func makeUXViewController(context: Context) -> CodeEditorViewController {
        let viewController = CodeEditorViewController(languageMode: TreeSitterLanguageMode(language: language, languageProvider: nil))
        viewController.sourceCode = text
        viewController.textView.editorDelegate = context.coordinator

        return viewController
    }

    func updateUXViewController(_ uxViewController: CodeEditorViewController, context: Context) {
        uxViewController.sourceCode = text
        //uxViewController.editorFontSize = model.editorFontSize
    }

    static func dismantleUXViewController(_ controller: CodeEditorViewController, coordinator: CodeEditorDelegate) {

    }

    func makeCoordinator() -> CodeEditorDelegate {
        CodeEditorDelegate(text: $text)
    }
}

private class CodeEditorDelegate : NSObject, TextViewDelegate {
    @Binding var text: String

    init(text: Binding<String>) {
        self._text = text
    }

    func textViewDidChange(_ textView: TextView) {
        if self.text != textView.text {
            self.text = textView.text
        }
    }
}

private class CodeEditorViewController: UXViewController {
    let textView = TextView()
    let languageMode: TreeSitterLanguageMode

    var sourceCode = "" {
        didSet {
            textView.text = sourceCode
        }
    }

    var theme: Theme? {
        didSet {
            resetState()
        }
    }

//    var editorFontSize = 14.0 {
//        didSet {
//            let theme = wip(DefaultTheme())
//            let state =
//            textView.setState(state)
//        }
//    }

    internal init(languageMode: TreeSitterLanguageMode, sourceCode: String = "", theme: Theme? = nil) {
        self.languageMode = languageMode
        self.sourceCode = sourceCode
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func resetState() {
        textView.setState(TextViewState(text: sourceCode, theme: theme ?? DefaultTheme(), language: languageMode.language))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.scrollEdgeAppearance = UINavigationBarAppearance()
        textView.text = sourceCode
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.backgroundColor = .systemBackground
        setCustomization(on: textView)
        textView.setLanguageMode(languageMode)
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setCustomization(on textView: TextView) {
        textView.lineHeightMultiplier = 1.3
        textView.showLineNumbers = true
//        textView.showSpaces = true
//        textView.showLineBreaks = true
        textView.isLineWrappingEnabled = true
        textView.isEditable = true
        textView.lineBreakMode = .byWordWrapping
    }
}

#endif
