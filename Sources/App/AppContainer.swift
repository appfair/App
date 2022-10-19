import FairKit
import UniformTypeIdentifiers
import Lottie
import SwiftUI

extension UTType {
    static var lottieJSON = UTType(importedAs: "app.Lottie-Motion.lottie-json")
}

final class Document: ReferenceFileDocument {
    @Published var animation: LottieAnimation

    static var readableContentTypes: [UTType] {
        [
            UTType.lottieJSON,
            UTType.json, // most lottie files are just ".json"
        ]
    }
    static var writableContentTypes: [UTType] { [] }

    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.animation = try LottieAnimation(json: data)
    }

    func fileWrapper(snapshot: Void, configuration: WriteConfiguration) throws -> FileWrapper {
        try FileWrapper(regularFileWithContents: animation.json())
    }

    func snapshot(contentType: UTType) throws -> Void {
        dbg("snapshot:", contentType)
    }
}

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
        DocumentGroup(viewing: Document.self) { file in
            ContentView(document: file.document)
                .focusedSceneValue(\.document, file.document)
        }
        .commands {
            CommandGroup(after: .newItem) {
                examplesMenu()
            }
            LottieCommandMenu()
        }
    }

    private static let exampleURLs = Bundle.module.urls(forResourcesWithExtension: "lottie.json", subdirectory: "Bundle")

    /// For each example in the module's bundle, create a menu item that will open the file
    func examplesMenu() -> Menu<Text, ForEach<[URL], URL, Button<Text>>> {
        Menu {
            ForEach((Self.exampleURLs ?? []).sorting(by: \.lastPathComponent), id: \.self) { url in
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

///// The shared app environment
//@available(macOS 12.0, iOS 15.0, *)
//@MainActor public final class Store: SceneManager {
//    /// The configuration metadata for the app from the `App.yml` file.
//    public static let config: JSum = configuration(for: .module)
//
//    @AppStorage("someToggle") public var someToggle = false
//
//    public init() {
//    }
//}


extension FocusedValues {
    /// The store for the given scene
    var document: Document? {
        get { self[DocumentKey.self] }
        set { self[DocumentKey.self] = newValue }
    }

    private struct DocumentKey: FocusedValueKey {
        typealias Value = Document
    }
}

struct PlayPauseCommand : View {
    @FocusedValue(\.document) var document
    @ObservedObject var sceneStore: SceneStore

    var body: some View {
        (sceneStore.playing == false
         ? Text("Pause", bundle: .module, comment: "play pause button text")
         : Text("Play", bundle: .module, comment: "play pause button text"))
            .label(image: sceneStore.playing == true ? FairSymbol.pause_fill.image : FairSymbol.play_fill.image)
            .button {
                sceneStore.playing.toggle()
            }
            //.disabled(sceneStore == nil)
    }
}

struct ZoomCommand : View {
    @FocusedValue(\.document) var document
    let amount: Double

    var body: some View {
        (amount > 0
            ? Text("Zoom In: \(Text(amount, format: .percent))", bundle: .module, comment: "zoom command description")
            : Text("Zoom Out: \(Text(amount, format: .percent))", bundle: .module, comment: "zoom command description"))
            .label(image: amount > 0 ? FairSymbol.plus_magnifyingglass.image : FairSymbol.minus_magnifyingglass.image)
            .button {
//                if let sceneStore = document?.sceneStore {
//                    withAnimation {
//                        sceneStore.viewScale = max(0.01, sceneStore.viewScale + amount)
//                    }
//                }
            }
            //.disabled(document?.sceneStore == nil)
    }
}

struct JumpCommand : View {
    @FocusedValue(\.document) var document
    let amount: Double

    var body: some View {
        ((amount > 0
          ? Text("Jump Forward: \(Text(amount, format: .number))", bundle: .module, comment: "jump command description")
          : Text("Zoom Backward: \(Text(amount, format: .number))", bundle: .module, comment: "jump command description")))
            .label(image: amount > 0 ? FairSymbol.forward_fill.image : FairSymbol.backward_fill.image)
            .button {
//                if let sceneStore = document?.sceneStore {
//                    sceneStore.jumpTime = amount
//                }
            }
            //.disabled(document?.sceneStore == nil)
    }
}

/// The shared scene environment
@available(macOS 12.0, iOS 15.0, *)
final class SceneStore: ObservableObject {
    @Published var playing = true
    @Published var loopMode = LottieLoopMode.loop
    @Published var animationSpeed = 1.0
    @Published var jumpTime: TimeInterval = 0.0
    @Published var viewScale: Double = 1.0
}
