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
                        LazyView(view: { SliderView() })
                    }
                    NavigationLink("Update State") {
                        LazyView(view: { UpdateStateView() })
                    }
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




struct SliderView: View {
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
            return try context.new("LargeVStackView")
        }
        .navigationTitle("Update State")
    }

    struct PerformanceTestModule: JXModule {
        var namespace: JXNamespace = JXNamespace("perftest")

        func register(with registry: JXRegistry) throws {
            try registry.register(JXSwiftUI())
        }

        func initialize(in context: JXContext) throws {
            try context.eval(js)
        }
    }

    private static let js = """
    jx.import(swiftui)

    class TextSliderView extends JXView {
        constructor(text) {
            super();
            this.text = text;
            this.state.sliderValue = 0.5;
        }

        body() {
            return VStack([
                Text(this.text),
                Slider(this.state.$sliderValue),
                Text(`Value: ${this.state.sliderValue.toFixed(4)}`).font(swiftui.Font.body.monospacedDigit())
            ])
            .padding()
        }
    }

    class LargeVStackView extends JXView {
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
                ])
            )
        }
    }
    """

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
            return try context.new("LargeVStackView")
        }
        .navigationTitle("Update State")
    }

    struct PerformanceTestModule: JXModule {
        var namespace: JXNamespace = JXNamespace("perftest")

        func register(with registry: JXRegistry) throws {
            try registry.register(JXSwiftUI())
        }

        func initialize(in context: JXContext) throws {
            try context.eval(js)
        }
    }

    private static let js = """
    jx.import(swiftui)

    class TextSliderView extends JXView {
        constructor(text) {
            super();
            this.text = text;
            this.state.sliderValue = 0.5;
        }

        body() {
            return VStack([
                Text(this.text),
                Slider(this.state.$sliderValue),
                Text(`Value: ${this.state.sliderValue.toFixed(4)}`).font(swiftui.Font.body.monospacedDigit())
            ])
            .padding()
        }
    }

    class LargeVStackView extends JXView {
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


}



#endif
