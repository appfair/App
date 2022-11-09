import Jack
import JackPot
import SwiftUI

public protocol JackPodView : View {
    associatedtype ViewModel : JackPod
    var viewModel: ViewModel { get }
    var script: String { get }
}

extension JackPodView {

//    @ViewBuilder public var body: some View {
//        switch Result(catching: { try evaluateView().anyView }) {
//        case .success(let success):
//            success
//        case .failure(let error):
//            TextEditor(text: .constant("ERROR: \(String(describing: error))"))
//                .foregroundColor(.red)
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//        }
//    }
}


struct JackScriptSampleView : JackPodView {
    @State var editing = false
    @StateObject var viewModel = ViewModel()

    class ViewModel: UIPod {
        // Read-Only variables

        @Stack var txt1 = "*Jack*"
        @Stack var txt2 = "**Pod**"

        @Stack var reversed = false

        // Read-write bindings exported as `this[$varName]`

        @Stack(bind: "$") var showHeader = true
        @Stack(bind: "$") var n1 = 0.0
        @Stack(bind: "$") var n2 = 0.5
        @Stack(bind: "$") var n3 = 1.0

        lazy var jacked = Result {
            try jack()
        }
    }

    @State var script = Self.defaultScript

    /// The default UI script
    private static let defaultScript = """
        // the average of the three jacked properties: n1, n2, and n3
        var avg = (this[$n1] + this[$n2] + this[$n3]) / 3.0

        VStack([
          Group([
            HStack(this[$showHeader] ? [
                Text(txt1).fontStyle('largeTitle'),
                Text(txt2).fontStyle('title2'),
            ] : [])
            .transition('slide')
            .opacity(avg),
            Spacer(),
            HStack([
                Toggle(Text("Show Header"), $showHeader),
                Button(Text('Swap'), () => {
                  // swap the two text pointers
                  txt2 = [txt1, txt1 = txt2][0];
                  this[$showHeader] = true; // make sure the header is visible
                })
            ]),
            Divider(),
          ]),
          Text(`Slider average: ${Math.round(avg * 100.0)}%`)
            .fontStyle('headline'),
          Group([
            Slider(Text('Slider 1'), $n1),
            Slider(Text('Slider 2'), $n2),
            Slider(Text('Slider 3'), $n3),
          ]),
          Group([
            Divider(),
            Button(Text('Shuffle'), () => {
              this[$n1] = Math.random();
              this[$n2] = Math.random();
              this[$n3] = Math.random();
            })
          ]),
          Spacer(),
          Divider(),
          Text('This script can be edited live with the Edit button').fontStyle('caption'),
        ])
        .padding()
        """

//    private static let defaultScript = """
//        var texts = [
//              Text('Large Title').fontStyle('largeTitle').id('v1'),
//              Text('Title').fontStyle('title').id('v2'),
//              Text('Title Two').fontStyle('title2').id('v3'),
//              Text('Title Three').fontStyle('title3').id('v4'),
//              Text('Sub Headline').fontStyle('subheadline').id('v5'),
//              Text('Callout').fontStyle('callout').id('v6'),
//              Text('Footnote').fontStyle('footnote').id('v7'),
//              Text('Caption').fontStyle('caption').id('v8'),
//              Text('Caption Two').fontStyle('caption2').id('v9'),
//            ];
//
//        if(reversed === true) {
//            texts.reverse();
//        }
//
//        VStack([
//          Group(texts),
//          Divider(),
//          Spacer(),
//          Button(Text('Reverse').fontStyle('largeTitle'), () => {
//            //reversed = reversed === true ? false : true;
//          })
//        ])
//        """

    func evaluateView() throws -> ViewTemplate {
        try viewModel.jacked.get().context.eval(script).convey()
        //try viewModel.jack().context.eval(script).convey()
    }

    @ViewBuilder var editorView: some View {
        TextEditor(text: $script)
            .font(.system(.callout, design: .monospaced))
    }

    @ViewBuilder var dynamicView: some View {
        switch Result(catching: { try evaluateView().anyView }) {
        case .success(let success):
            success
                .animation(.default, value: script)
        case .failure(let error):
            TextEditor(text: .constant("ERROR: \(String(describing: dump(error, name: "error in rendering view")))"))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    var saveEditButton: some View {
        Button {
            editing.toggle()
        } label: {
            editing ? Text("Save", bundle: .module, comment: "save button title") : Text("Edit", bundle: .module, comment: "edit button title")
        }
    }

    var resetButton: some View {
        Button {
            withAnimation {
                self.script = Self.defaultScript
                editing = false
            }
        } label: {
            Text("Reset", bundle: .module, comment: "reset the script to the default")
        }
    }


    var body: some View {
        #if os(macOS)
        HSplitView {
            editorView
            dynamicView
        }
        #else
        NavigationView {
            TabView(selection: $editing) {
                ScrollView {
                    dynamicView
                }
                .tag(false) // non-editing
                .tabItem {
                    Text("Execution", bundle: .module, comment: "tab title for execution")
                }

                editorView
                    .tag(true) // editing
                    .tabItem {
                        Text("Editor", bundle: .module, comment: "script editor title")
                    }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    resetButton
                        .buttonStyle(.bordered)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    saveEditButton
                        .buttonStyle(.borderedProminent)
                }
            }
            .tabViewStyle(.automatic)
        }
        #endif
    }
}
