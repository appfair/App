import FairApp
import Jack

struct PodUIView : View {
    @EnvironmentObject var store: Store
    @StateObject var pod = WeatherFormPod()

    var body: some View {
        Text(pod.str)
            .onAppear {
                store.trying {
                    try pod.evalString()
                }
            }
    }
}

private var _allobs: [AnyObject] = wip([])

/// A proxy for a SwiftUI.Text object, containing all the modifiers needed to instantiate the view.
class TextProxy : JackedObject, JXConvertible {
    @Jacked var value = ""

    init(value: String) {
        self.value = value
        _allobs.append(self)
    }

    deinit {
        print("### DEINIT")
    }

    @Jumped("rnd") private var _rnd = rnd
    open func rnd() -> String {
        wip(UUID().uuidString) // FIXME: never called when returned through secondary object
    }

    @Jumped("lowercased") private var _lowercased = lowercased
    open func lowercased() -> TextProxy {
        self
        //TextProxy(value: value.lowercased())
    }

    @Jumped("lowercased2") private var _lowercased2 = lowercased2
    open func lowercased2(x: Bool) -> TextProxy {
        TextProxy(value: value.lowercased())
    }

    @Jumped("uppercased") private var _uppercased = uppercased
    open func uppercased() -> TextProxy {
        TextProxy(value: value.uppercased())
    }

    static func makeJX(from value: JXValue) throws -> Self {
        wip(fatalError())
    }

    func getJX(from context: JXContext) throws -> JXValue {
        //jack(into: context, as: id.uuidString)
        let obj = context.global
        dump(try inject(into: context.object()), name: wip("injected properties"))
        return obj
    }
}


open class WeatherFormPod : JackedObject {
    @Jacked var str = ""

    @Jumped("makeText") private var _makeText = makeText
    func makeText(value: String) -> TextProxy {
        TextProxy(value: value)
    }

    /// The script context to use for this app
    lazy var ctx = jack()

    init() {
    }

    func evalString() throws {
        try ctx.env.eval("""
        //str = makeText("abc").lowercased.toString();
        //str = makeText("abc").lowercased2.toString();
        //str = makeText("abc").lowercased().value;
        str = makeText("abc").rnd(); // never called!
        """)
    }

    func xxx() -> String {
        """

        //ctx.inject(NetPod.self, into: "net")
        //ctx.inject(UIPod.self, into: "ui")
        //ctx.inject(SQLPod.self, into: "sql")

        //var unit = await ui.request("Farenheit or Celsuis?", type: popup);

        ui.NavigationStack(
            ui.List(
                ui.ForEach(1...1000) (
                    NavigationLink(
                    )
                )
            )
        )

        var form = ui.Form(
            ui.TextField("Metric", $xxx),
            ui.Divider(),
            ui.Button("Submit", () => {
                print("submitted");
            });
        );
        let formData = await ui.request(form);

        var result = await net.fetch("https://www.myserive.com/hottake?temp=" + temperature + "&units=" + formData['']);


        """

    }
}
