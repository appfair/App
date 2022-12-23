#if canImport(JXSwiftUI)
import SwiftUI
import JXBridge
import JXKit
import JXSwiftUI

struct JXSwiftUINavView : View {
    var body: some View {
        NavigationView {
            List {
                Section("Performance Tests") {
                    NavigationLink("Simple Slider") {
                        LazyView(view: { UpdateStateView() })
                    }
//                    NavigationLink("Update State") {
//                        LazyView(view: { UpdateStateView() })
//                    }
                }
            }
            .navigationTitle("JXPlayground")
        }
    }

}

private struct LazyView<V: View>: View {
    let view: () -> V

    var body: some View {
        view()
    }
}

struct UpdateStateView: View {
    let context: JXContext

    init(context: JXContext = JXContext()) {
        self.context = context
        do {
            try context.registry.register(PerformanceTestModule())
        } catch {
            print("UpdateStateView: \(error)")
        }
    }

    var body: some View {
        JXView(context: context) { context in
            return try context.new("perftest.LargeVStackView")
        }
        .navigationTitle("Update State")
    }
}

extension JXNamespace {
    static let perftest = JXNamespace("perftest")
}

struct PerformanceTestModule: JXModule {
    var namespace: JXNamespace = .perftest

    func register(with registry: JXRegistry) throws {
        try registry.register(JXSwiftUI())
        try registry.registerModuleScript(js, namespace: namespace)
    }
}

private let js = """
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

exports.LargeVStackView = class extends View {
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
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                ]),
                Group([
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                ]),
                Group([
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                ]),
                Group([
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                ]),
                Group([
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                ]),
                Group([
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                ]),
                Group([
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                ]),
                Group([
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                    new TextSliderView('View ' + (i++)),
                ]),
            ])
        )
    }
}
"""


#endif
