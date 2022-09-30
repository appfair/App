import FairApp
import Jack

public protocol JackedPod : JackPod {
    var jxc: JXContext { get }
}

public protocol JackView : View {
    associatedtype ViewModel : JackedPod
    var viewModel: ViewModel { get }
    var script: String { get }
}

extension JackView {
    var bodyEval: Result<AnyView, Error> {
        Result { try viewModel.jxc.eval(script).convey(to: ViewProxy.self).anyView }
    }

    @ViewBuilder public var body: some View {
        switch bodyEval {
        case .success(let success):
            success
        case .failure(let error):
            Text(wip("ERROR: \(String(describing: error))"))
        }
    }
}

struct ForecastView : View {
    var body: some View {
        wip(SampleJackPodView())
    }
}

struct SampleJackPodView : JackView {
    @State var editing = false
    @StateObject var viewModel = ViewModel()
    class ViewModel: UIPod, JackedPod {
        @Jacked var txt = "*Jack***Pod**"
        @Jacked(bind: "$") var n1 = 0.0
        @Jacked(bind: "$") var n2 = 0.0
        @Jacked(bind: "$") var n3 = 0.0
        lazy var jxc = jack().env
    }

    @State var script = Self.defaultScript

    /// The default UI script
    private static let defaultScript = """
        VStack([
          Group([
            Text(`Sample ${txt}`).fontStyle('largeTitle'),
            Spacer(),
            Divider(),
          ]),
          Text(`Slider average: ${Math.round((this[$n1] + this[$n2] + this[$n3])/3.0 * 100)}%`)
            .fontStyle('headline'),
          Group([
            Slider(Text('Slider 1'), $n1),
            Slider(Text('Slider 2'), $n2),
            Slider(Text('Slider 3'), $n3),
          ]),
          Group([
            Divider(),
            HStack([
              Button(Text('Shuffle'), () => {
                this[$n1] = Math.random();
                this[$n2] = Math.random();
                this[$n3] = Math.random();
              }),
              Spacer(),
              Button(Text('Click Me!'), () => {
                // do something interesting here…
                txt = txt == '*Jack***Pod**' ? '**Jack***Pod*' : '*Jack***Pod**';
              }),
            ]),
          ]),
          Spacer(),
          Divider(),
          Text('This script can be edited live with the Edit button').fontStyle('caption'),
        ])
        //.padding()
        """

    var body: some View {
        NavigationView {
            TabView(selection: $editing) {
                ScrollView {
                    scriptView
                        .padding()
                }
                .tag(false) // non-editing
                .tabItem {
                    Text("Execution", bundle: .module, comment: "tab title for execution")
                }
                .toolbar {
                    #if !os(macOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            editing.toggle()
                        } label: {
                            Text("Edit", bundle: .module, comment: "edit button title")
                        }
                        .buttonStyle(.bordered)
                    }
                    #endif
                }

                TextEditor(text: $script)
                    .font(.system(.callout, design: .monospaced))
                    .tag(true) // editing
                    .tabItem {
                        Text("Editor", bundle: .module, comment: "script editor title")
                    }
                    .toolbar {
                        #if !os(macOS)
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                self.script = Self.defaultScript
                                editing.toggle()
                            } label: {
                                Text("Reset", bundle: .module, comment: "reset the script to the default")
                            }
                            .buttonStyle(.bordered)
                        }

                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                editing.toggle()
                            } label: {
                                Text("Save", bundle: .module, comment: "save button title")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        #endif
                    }
            }
            #if !os(macOS)
            .tabViewStyle(.page)
            #endif
        }
    }

    @ViewBuilder var scriptView: some View {
        switch bodyEval {
        case .success(let success):
            success
        case .failure(let error):
            Text(verbatim: "ERROR: \(String(describing: error))")
                .foregroundColor(.red)
        }
    }
}
