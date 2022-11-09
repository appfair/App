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
    static var writableContentTypes: [UTType] {
        [
            UTType.lottieJSON,
            //UTType.json, // most lottie files are just ".json"
        ]
    }

    init(animation: LottieAnimation) {
        self.animation = animation
    }

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
