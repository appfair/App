/**
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import FairApp
import UniformTypeIdentifiers
import Lottie
import SwiftUI

// The entry point to creating your app is the `AppContainer` type,
// which is a stateless enum declared in `AppMain.swift` and may not be changed.
// 
// App customization is done via extensions in `AppContainer.swift`,
// which enables customization of the root scene, app settings, and
// other features of the app.

final class MotionFile: ReferenceFileDocument {
    @Published var animation: Lottie.Animation
    @Published var sceneStore = SceneStore()

    static var readableContentTypes: [UTType] { [UTType.json] }
    static var writableContentTypes: [UTType] { [UTType.json] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.animation = try Lottie.Animation(json: data)
    }

    func fileWrapper(snapshot: Void, configuration: WriteConfiguration) throws -> FileWrapper {
        try FileWrapper(regularFileWithContents: animation.json())
    }

    func snapshot(contentType: UTType) throws -> Void {
    }
}

@available(macOS 12.0, iOS 15.0, *)
public struct ContentView: View {
    let document: MotionFile
    @EnvironmentObject var appStore: Store
    @EnvironmentObject var sceneStore: SceneStore
    @State var animationTime: TimeInterval = 0

    public var body: some View {
        VStack {
            MotionEffectView(animation: document.animation, playing: $sceneStore.playing, loopMode: $sceneStore.loopMode, animationSpeed: $sceneStore.animationSpeed, animationTime: $animationTime)
                .scaleEffect(sceneStore.viewScale)
                .frame(minWidth: 0, minHeight: 0)
            controlStrip()
                .background(Material.ultraThinMaterial)
        }
        .onChange(of: sceneStore.jumpTime) { _ in
            // storing the animationTime directly in the SceneStore is too slow (since a complete view re-build will occur whenever it changes), so instead we just store intentions to jump forward or backward by an offset
            if sceneStore.jumpTime != 0.0 {
                animationTime = max(min(animationTime + sceneStore.jumpTime, document.animation.duration), 0.0)
                // re-set to zero
                sceneStore.jumpTime = 0.0
            }
        }
    }

    /// Play/pause progress video controls
    @ViewBuilder func controlStrip() -> some View {
        HStack(spacing: 20) {
            sceneStore.playPauseCommand()
                .font(.title)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .help(sceneStore.playing ? Text("Pause the animation") : Text("Play the animation"))
                .keyboardShortcut(KeyboardShortcut(.space, modifiers: []))

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
                .help(sceneStore.playing ? Text("Pause the animation") : Text("Play the animation"))
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
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        DocumentGroup(viewing: MotionFile.self) { file in
            ContentView(document: file.document)
                .environmentObject(file.document.sceneStore)
                .focusedSceneValue(\.sceneStore, file.$document.sceneStore)
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
            ForEach((Bundle.module.urls(forResourcesWithExtension: "json", subdirectory: "Bundle") ?? []).sorting(by: \.lastPathComponent), id: \.self) { url in
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
    @FocusedBinding(\.sceneStore) var sceneStore

    var body : some Commands {
        CommandMenu(Text("Lottie")) {
            Button("TEST") {
                dbg("SCENE:", sceneStore)
            }

//                sceneStore.playPauseCommand()
//                    .keyboardShortcut(KeyboardShortcut(.space, modifiers: []))
//                sceneStore.jumpForwardCommand(1.0)
//                    .keyboardShortcut(KeyboardShortcut(.rightArrow, modifiers: []))
//                sceneStore.jumpForwardCommand(0.1)
//                    .keyboardShortcut(KeyboardShortcut(.rightArrow, modifiers: [.shift]))
//                sceneStore.jumpBackwardCommand(-1.0)
//                    .keyboardShortcut(KeyboardShortcut(.leftArrow, modifiers: []))
//                sceneStore.jumpBackwardCommand(-0.1)
//                    .keyboardShortcut(KeyboardShortcut(.leftArrow, modifiers: [.shift]))
//                sceneStore.zoomCommand(0.05)
//                    .keyboardShortcut(KeyboardShortcut(KeyEquivalent("="), modifiers: [.command]))
//                sceneStore.zoomCommand(-0.05)
//                    .keyboardShortcut(KeyboardShortcut(KeyEquivalent("-"), modifiers: [.command]))
//
//                // NavigationLink("Create Window", destination: Text("This opens in a new window!").padding())
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
public extension AppContainer {
    /// The body of your scene is provided by `AppContainer.scene`
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
    var sceneStore: Binding<SceneStore>? {
        get { self[SceneStoreKey.self] }
        set { self[SceneStoreKey.self] = newValue }
    }

    private struct SceneStoreKey: FocusedValueKey {
        typealias Value = Binding<SceneStore>
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

    /// The command to toggle play/pause
    func playPauseCommand() -> some View {
        (playing ? Text("Pause") : Text("Play"))
            .label(image: playing ? FairSymbol.pause_fill.image : FairSymbol.play_fill.image)
            .button {
                self.playing.toggle()
            }
    }

    /// The command to jump forward
    func jumpForwardCommand(_ amount: TimeInterval) -> Button<Label<Text, Image>> {
        Text("Jump Forward: \(amount)")
            .label(image: FairSymbol.forward_fill.image)
            .button { self.jumpTime = amount }
    }

    /// The command to jump backward
    func jumpBackwardCommand(_ amount: TimeInterval) -> Button<Label<Text, Image>> {
        Text("Jump Backward: \(amount)")
            .label(image: FairSymbol.backward_fill.image)
            .button { self.jumpTime = amount }
    }

    /// The command to zoom
    func zoomCommand(_ amount: Double) -> Button<Label<Text, Image>> {
        ((amount > 0 ? Text("Zoom In: ") : Text("Zoom Out: ")) + Text(amount, format: .percent))
            .label(image: amount > 0 ? FairSymbol.plus_magnifyingglass.image : FairSymbol.minus_magnifyingglass.image)
            .button {
                self.viewScale = max(0.01, self.viewScale + amount)
            }
    }

}

@available(macOS 12.0, iOS 15.0, *)
public struct AppSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        EmptyView()
    }
}

