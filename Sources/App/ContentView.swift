import FairApp
import UniformTypeIdentifiers
import Lottie

@available(macOS 12.0, iOS 15.0, *)
public struct ContentView: View {
    @Namespace var mainNamespace
    let document: Document
    @EnvironmentObject var appStore: Store
    @State var sceneStore: SceneStore = SceneStore()
    @State var animationTime: TimeInterval = 0
    @State var searchString = ""

    public var body: some View {
        VStack {
            MotionEffectView(animation: document.animation, playing: $sceneStore.playing, loopMode: $sceneStore.loopMode, animationSpeed: $sceneStore.animationSpeed, animationTime: $animationTime)
                .animation(.linear, value: animationTime) // ideally this would cause changes to the animationTime to animate through intervening values, but it seems to not work
                .scaleEffect(sceneStore.viewScale)
                .frame(minWidth: 0, minHeight: 0)
            controlStrip()
                .background(Material.ultraThinMaterial)
                //.focusable(true)
                //.searchable(text: $searchString) // attempt to work around broken focusedSceneValue as per https://developer.apple.com/forums/thread/693580
        }
        .onChange(of: sceneStore.jumpTime) { _ in
            // storing the animationTime directly in the SceneStore is too slow (since a complete view re-build will occur whenever it changes), so instead we just store the *intention* to jump forward or backward by an offset
            let jt = sceneStore.jumpTime
            if jt != 0.0 {
                // withAnimation { // animating jumps seem to not work
                    animationTime = max(min(animationTime + jt, document.animation.duration), 0.0)
                    sceneStore.jumpTime = 0.0 // re-set to zero
                // }
            }
        }
    }

    /// Play/pause progress video controls
    @ViewBuilder func controlStrip() -> some View {
        HStack(spacing: 20) {
            PlayPauseCommand(sceneStore: sceneStore)
                .font(.title)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .help(sceneStore.playing ? Text("Pause the animation", bundle: .module, comment: "button text for pausing animation") : Text("Play the animation", bundle: .module, comment: "button text for playing animation"))

            Slider(value: $animationTime, in: 0...document.animation.duration, label: {
            }, minimumValueLabel: {
                Text(animationTime, format: .number.precision(.fractionLength(2)))
            }, maximumValueLabel: {
                Text(document.animation.duration, format: .number.precision(.fractionLength(2)))
            }, onEditingChanged: { changed in
                sceneStore.playing = false // pause when changing the slider
            })

            sceneStore.loopMode.textLabel
                .font(.title)
                .button {
                    switch sceneStore.loopMode {
                    case .playOnce: sceneStore.loopMode = .loop
                    case .loop: sceneStore.loopMode = .playOnce
                    //case .autoReverse: self.loopMode = .playOnce
                    case _: sceneStore.loopMode = .playOnce
                    }
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .help(Text("Toggle playback looping", bundle: .module, comment: "help text for toggling play loop"))
        }
        .padding()
    }
}

extension LottieLoopMode {
    @ViewBuilder var textLabel: some View {
        switch self {
        case .playOnce:
            Text("Play Once", bundle: .module, comment: "loop mode description").label(image: FairSymbol.repeat_1.image)
        case .loop:
            Text("Loop", bundle: .module, comment: "loop mode description").label(image: FairSymbol.repeat.image)
        case .autoReverse:
            Text("Auto-Reverse", bundle: .module, comment: "loop mode description").label(image: FairSymbol.arrow_up_circle)
        case .repeat(let count):
            Text("Repeat \(count)", bundle: .module, comment: "loop mode description").label(image: FairSymbol.arrow_up_circle)
        case .repeatBackwards(let count):
            Text("Reversed \(count)", bundle: .module, comment: "loop mode description").label(image: FairSymbol.arrow_up_circle)
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct MotionScene : Scene {
    var body: some Scene {
        DocumentGroup(newDocument: createSampleDocument) { file in
            ContentView(document: file.document)
                .focusedSceneValue(\.document, file.document)
        }
//        DocumentGroup(viewing: Document.self) { file in
//            ContentView(document: file.document)
//                .focusedSceneValue(\.document, file.document)
//        }
        .commands {
            CommandGroup(after: .newItem) {
                examplesMenu()
            }
            LottieCommandMenu()
        }
    }

    private func createSampleDocument() -> Document {
        let url = Store.exampleURLs!.shuffled().first!
        let data = try! Data(contentsOf: url)
        let animation = try! LottieAnimation(json: data)
        return Document(animation: animation)
    }

    /// For each example in the module's bundle, create a menu item that will open the file
    func examplesMenu() -> Menu<Text, ForEach<[URL], URL, Button<Text>>> {
        Menu {
            ForEach((Store.exampleURLs ?? []).sorting(by: \.lastPathComponent), id: \.self) { url in
                Text(url.deletingPathExtension().lastPathComponent)
                    // .label(image: Image(uxImage: NSWorkspace.shared.icon(forFile: url.path))) // doesn't work; label images aren't rendered on macOS
                    .button {
                        #if os(macOS)
                        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { doc, success, error in
                            dbg("opening sample:", url.lastPathComponent, "success:", success, "error:", error)
                        }
                        #endif

                        #if os(iOS)
                        // TODO
                        #endif
                    }
            }
        } label: {
            Text("Open Example")
        }
    }
}

/// Broken in Monterey – cannot associated focused bindings:
/// https://developer.apple.com/forums/thread/682503
struct LottieCommandMenu : Commands {
    var body : some Commands {
        CommandMenu(Text("Lottie", bundle: .module, comment: "command menu name")) {
//            PlayPauseCommand()
//                .keyboardShortcut(KeyboardShortcut(.space, modifiers: []))

            JumpCommand(amount: 1.0)
                .keyboardShortcut(KeyboardShortcut(.rightArrow, modifiers: []))
            JumpCommand(amount: 0.1)
                .keyboardShortcut(KeyboardShortcut(.rightArrow, modifiers: [.shift]))
            JumpCommand(amount: -1.0)
                .keyboardShortcut(KeyboardShortcut(.leftArrow, modifiers: []))
            JumpCommand(amount: -0.1)
                .keyboardShortcut(KeyboardShortcut(.leftArrow, modifiers: [.shift]))

            ZoomCommand(amount: 0.05)
                .keyboardShortcut(KeyboardShortcut(KeyEquivalent("="), modifiers: [.command]))
            ZoomCommand(amount: -0.05)
                .keyboardShortcut(KeyboardShortcut(KeyEquivalent("-"), modifiers: [.command]))

//                // NavigationLink("Create Window", destination: Text("This opens in a new window!").padding())
        }

    }
}

