import FairApp
import UniformTypeIdentifiers
import LottieUI
import SwiftUI

extension UTType {
    static var lottieJSON = UTType(importedAs: "app.Lottie-Motion.lottie-json")
}

final class MotionFile: ReferenceFileDocument {
    @Published var animation: LottieUI.Animation
    @Published var sceneStore = SceneStore()

    static var readableContentTypes: [UTType] {
        [
            UTType.lottieJSON,
            UTType.json, // most lottie files are just ".json"
        ]
    }
    static var writableContentTypes: [UTType] { [] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.animation = try LottieUI.Animation(json: data)
    }

    func fileWrapper(snapshot: Void, configuration: WriteConfiguration) throws -> FileWrapper {
        try FileWrapper(regularFileWithContents: animation.json())
    }

    func snapshot(contentType: UTType) throws -> Void {
    }
}

@available(macOS 12.0, iOS 15.0, *)
public struct ContentView: View {
    @Namespace var mainNamespace
    let document: MotionFile
    @EnvironmentObject var appStore: Store
    @EnvironmentObject var sceneStore: SceneStore
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
            PlayPauseCommand()
                .font(.title)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .help(sceneStore.playing ? Text("Pause the animation") : Text("Play the animation"))

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
                .help(Text("Toggle playback looping"))
        }
        .padding()
    }
}

extension LottieLoopMode {
    @ViewBuilder var textLabel: some View {
        switch self {
        case .playOnce:
            Text("Play Once").label(image: FairSymbol.repeat_1.image)
        case .loop:
            Text("Loop").label(image: FairSymbol.repeat.image)
        case .autoReverse:
            Text("Auto-Reverse").label(image: FairSymbol.arrow_up_circle)
        case .repeat(let count):
            Text("Repeat \(count)").label(image: FairSymbol.arrow_up_circle)
        case .repeatBackwards(let count):
            Text("Reversed \(count)").label(image: FairSymbol.arrow_up_circle)
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct MotionScene : Scene {
    var body: some Scene {
        DocumentGroup(viewing: MotionFile.self) { file in
            ContentView(document: file.document)
                .environmentObject(file.document.sceneStore)
                .focusedSceneValue(\.sceneStore, file.document.sceneStore)
        }
        .commands {
            CommandGroup(after: .newItem) {
                examplesMenu()
            }
            LottieCommandMenu()
        }
    }

    /// For each example in the module's bundle, create a menu item that will open the file
    func examplesMenu() -> Menu<Text, ForEach<[URL], URL, Button<Text>>> {
        Menu {
            ForEach((Bundle.module.urls(forResourcesWithExtension: "lottie.json", subdirectory: "Bundle") ?? []).sorting(by: \.lastPathComponent), id: \.self) { url in
                Text(url.deletingPathExtension().lastPathComponent)
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
        CommandMenu(Text("Lottie")) {
            PlayPauseCommand()
                .keyboardShortcut(KeyboardShortcut(.space, modifiers: []))

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

@available(macOS 12.0, iOS 15.0, *)
public extension AppContainer {
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        MotionScene()
    }

    /// The app-wide settings view
    @ViewBuilder static func settingsView(store: Store) -> some SwiftUI.View {
        AppSettingsView().environmentObject(store)
    }
}

/// The shared app environment
@available(macOS 12.0, iOS 15.0, *)
@MainActor public final class Store: SceneManager {
    @AppStorage("someToggle") public var someToggle = false
}


extension FocusedValues {
    /// The store for the given scene
    var sceneStore: SceneStore? {
        get { self[SceneStoreKey.self] }
        set { self[SceneStoreKey.self] = newValue }
    }

    private struct SceneStoreKey: FocusedValueKey {
        typealias Value = SceneStore
    }
}

extension FocusedValues {
    /// The store for the given scene
    var document: ObservedObject<MotionFile>.Wrapper? {
        get { self[MotionFileKey.self] }
        set { self[MotionFileKey.self] = newValue }
    }

    private struct MotionFileKey: FocusedValueKey {
        typealias Value = ObservedObject<MotionFile>.Wrapper
    }
}

struct PlayPauseCommand : View {
    @FocusedValue(\.sceneStore) var sceneStore

    var body: some View {
        (sceneStore == nil ? Text("Play/Pause") : sceneStore?.playing == false ? Text("Pause") : Text("Play"))
            .label(image: sceneStore?.playing == true ? FairSymbol.pause_fill.image : FairSymbol.play_fill.image)
            .button {
                sceneStore?.playing.toggle()
            }
            .disabled(sceneStore == nil)
    }
}

struct ZoomCommand : View {
    @FocusedValue(\.sceneStore) var sceneStore
    let amount: Double

    var body: some View {
        ((amount > 0 ? Text("Zoom In: ") : Text("Zoom Out: ")) + Text(amount, format: .percent))
            .label(image: amount > 0 ? FairSymbol.plus_magnifyingglass.image : FairSymbol.minus_magnifyingglass.image)
            .button {
                if let sceneStore = sceneStore {
                    withAnimation {
                        sceneStore.viewScale = max(0.01, sceneStore.viewScale + amount)
                    }
                }
            }
            .disabled(sceneStore == nil)
    }
}

struct JumpCommand : View {
    @FocusedValue(\.sceneStore) var sceneStore
    let amount: Double

    var body: some View {
        ((amount > 0 ? Text("Jump Forward: ") : Text("Zoom Backward: ")) + Text(amount, format: .number))
            .label(image: amount > 0 ? FairSymbol.forward_fill.image : FairSymbol.backward_fill.image)
            .button {
                if let sceneStore = sceneStore {
                    sceneStore.jumpTime = amount
                }
            }
            .disabled(sceneStore == nil)
    }
}

/// The shared scene environment
@available(macOS 12.0, iOS 15.0, *)
final class SceneStore: ObservableObject {
    @Published var playing = false
    @Published var loopMode = LottieLoopMode.loop
    @Published var animationSpeed = 1.0
    @Published var jumpTime: TimeInterval = 0.0
    @Published var viewScale: Double = 1.0
}

@available(macOS 12.0, iOS 15.0, *)
public struct AppSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        Toggle(isOn: $store.someToggle) {
            Text("Toggle")
        }
        .padding()
    }
}
