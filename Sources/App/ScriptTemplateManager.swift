import FairApp
import JXPod
import JXKit
import JXBridge
import MiniApp

class ScriptTemplateManager {
    public static let shared = ScriptTemplateManager()

    private init() {
    }

    func createTemplateWrapper() throws -> FileWrapper {
        var manifest = MiniAppManifest(name: "App Name", app_id: "org.example.miniapp")
        manifest.lang = "en-US"
        manifest.icons = [ImageResource(src: "common/icons/icon.png", sizes: "48x48", label: "App Icon")]

        let file = { FileWrapper(regularFileWithContents: $0) }
        let dir = { FileWrapper(directoryWithFileWrappers: $0) }

        let metadataJSON = try manifest.json(outputFormatting: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes ])

        let appJS = scriptTemplate.utf8Data

        let base = dir([
            "manifest.json": file(metadataJSON),
            "app.js": file(appJS),
            "i18n" : dir([
                "en-US.json" : file(#"{ "Hello": "Hello" }"#.utf8Data),
                "fr-FR.json" : file(#"{ "Hello": "bonjour" }"#.utf8Data),
                "zh-Hans.json" : file(#"{ "Hello": "你好" }"#.utf8Data),
            ]),
            "common" : dir([
                "shared.js" : file("// shared utils".utf8Data),
                "icons": dir([
                    "icon.png": file(Data())
                ])
            ]),
        ])
        return base
    }
}

let scriptTemplate = """
/**
 * App.js – this is your app
 **/
jxswiftui.import();

exports.PetListView = class extends View {
    constructor(model) {
        super();
        this.observed.model = model;
    }

    body() {
        const model = this.observed.model;
        return VStack([
            Button("New Pet", () => { withAnimation(() => model.addPet()) }),
            List([
                ForEach(model.pets, (pet) => {
                    return pet.id;
                }, (pet) => {
                    return NavigationLink(() => {
                        return new PetDetailView(pet)
                    }, new PetRow(pet, () => {
                        withAnimation(() => model.sellPet(pet.id));
                    }))
                })
            ])
        ])
        .navigationTitle('Pet Store')
    }
}

class PetRow extends View {
    constructor(pet, sellAction) {
        super();
        this.pet = pet;
        this.sellAction = sellAction;
    }

    body() {
        return HStack([
            new petstore.PetView(this.pet),
            Spacer(),
            Text('Sell')
                .onTapGesture(() => {
                    this.sellAction();
                })
        ])
    }
}

class PetDetailView extends View {
    constructor(pet) {
        super();
        this.pet = pet;
        this.state.sliderValue = 0.0
    }

    body() {
        return Form([
            Section('Inventory info', [
                Text(this.pet.animal),
                Text("$" + this.pet.price)
                    .font(Font.title.monospaced().bold())
                    .foregroundColor(Color.blue)
                    .background(Color.yellow)
            ]),
            Section('Pet info', [
                Text('Slider value: ' + this.state.sliderValue),
                Slider(this.state.$sliderValue)
            ])
        ])
        .navigationTitle('Pet')
    }
}
"""
