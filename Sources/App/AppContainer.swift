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

// The entry point to creating your app is the `AppContainer` type,
// which is a stateless enum declared in `AppMain.swift` and may not be changed.
// 
// App customization is done via extensions in `AppContainer.swift`,
// which enables customization of the root scene, app settings, and
// other features of the app.

struct MotionFile: FileDocument {
    var animation: Lottie.Animation

    static var readableContentTypes: [UTType] { [UTType.json] }
    static var writableContentTypes: [UTType] { [UTType.json] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.animation = try Lottie.Animation(json: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try FileWrapper(regularFileWithContents: animation.json())
    }
}

@available(macOS 12.0, iOS 15.0, *)
public struct ContentView: View {
    let document: MotionFile
    @State var playing = true
    @State var loopMode = LottieLoopMode.playOnce
    @State var animationSpeed = 1.0
    @State var animationTime: TimeInterval = 0
    @EnvironmentObject var store: Store

    public var body: some View {
        VStack {
            HStack(spacing: 20) {
                (playing ? Text("Pause") : Text("Play"))
                    .label(image: playing ? FairSymbol.pause_fill.image : FairSymbol.play_fill.image)
                    .font(.title)
                    .button {
                        playing.toggle()
                    }
                    .keyboardShortcut(KeyboardShortcut(.space))
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .help(playing ? Text("Pause the animation") : Text("Play the animation"))

                Slider(value: $animationTime, in: 0...document.animation.duration, label: {
                }, minimumValueLabel: {
                    Text(animationTime, format: .number.precision(.fractionLength(2)))
                }, maximumValueLabel: {
                    Text(document.animation.duration, format: .number.precision(.fractionLength(2)))
                }, onEditingChanged: { changed in
                    self.playing = false // pause when changing the slider
                })

                loopMode.textLabel
                    .font(.title)
                    .button {
                        if self.loopMode == .playOnce {
                            self.loopMode = .loop
                        } else {
                            self.loopMode = .playOnce
                        }
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .help(playing ? Text("Pause the animation") : Text("Play the animation"))
            }
            .padding()

            MotionEffectView(animation: document.animation, playing: $playing, loopMode: $loopMode, animationSpeed: $animationSpeed, animationTime: $animationTime)
                .frame(minWidth: 0, minHeight: 0)
        }
    }
}

extension LottieLoopMode {
    @ViewBuilder var textLabel: some View {
        switch self {
        case .playOnce: Text("Play Once").label(image: FairSymbol.repeat_1.image)
        case .loop: Text("Loop").label(image: FairSymbol.repeat.image)
        case .autoReverse: Text("Auto-Reverse").label(image: FairSymbol.arrow_up_circle)
        case .repeat(let count): Text("Repeat \(count)").label(image: FairSymbol.arrow_up_circle)
        case .repeatBackwards(let count): Text("Reversed \(count)").label(image: FairSymbol.arrow_up_circle)
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
public extension AppContainer {
    /// The body of your scene is provided by `AppContainer.scene`
    @SceneBuilder static func rootScene(store: Store) -> some SwiftUI.Scene {
        DocumentGroup(viewing: MotionFile.self) { file in
            ContentView(document: file.document)
        }
//        WindowGroup {
//            ContentView().environmentObject(store)
//        }
        .commands {
            CommandGroup(after: .newItem) {
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
            TextEditingCommands()
            TextFormattingCommands() // Next Edit is a plain text editor, but we need this for font sizxe increase & decrease
        }
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

@available(macOS 12.0, iOS 15.0, *)
public struct AppSettingsView : View {
    @EnvironmentObject var store: Store

    public var body: some View {
        EmptyView()
    }
}

