import SwiftUI
import Lottie
import FairApp

public struct MotionViewInfo {
}

/// A view that displays a Lottie Animation
public struct MotionEffectView : View {
    let animation: LottieAnimation
    @Binding var playing: Bool
    @Binding var loopMode: LottieLoopMode
    @Binding var animationSpeed: Double
    @Binding var animationTime: TimeInterval

    public init(animation: LottieAnimation, playing: Binding<Bool>, loopMode: Binding<LottieLoopMode> = .constant(.loop), animationSpeed: Binding<Double> = .constant(1.0), animationTime: Binding<TimeInterval> = .constant(0.0)) {
        self.animation = animation
        self._playing = playing
        self._loopMode = loopMode
        self._animationSpeed = animationSpeed
        self._animationTime = animationTime
    }

    public var body: some View {
        debuggingViewChanges()
        return MotionEffectViewRepresentable(animation: animation, playing: $playing, loopMode: $loopMode, animationSpeed: $animationSpeed, animationTime: $animationTime)
    }
}


/// A view that displays a Lottie Animation
struct MotionEffectViewRepresentable : UXViewRepresentable {
    typealias UXViewType = UXView
    let animation: LottieAnimation
    @Binding var playing: Bool
    @Binding var loopMode: LottieLoopMode
    @Binding var animationSpeed: Double
    @Binding var animationTime: TimeInterval

    func makeUXView(context: Context) -> UXViewType {
        context.coordinator.animationView
    }

    func updateUXView(_ view: UXViewType, context: Context) {
        let animationView = context.coordinator.animationView
        animationView.loopMode = loopMode
        animationView.animationSpeed = animationSpeed
        animationView.currentTime = animationTime
        if animationView.isAnimationPlaying != playing {
//            Task {
                if playing {
                    context.coordinator.displayLink?.start()
                    animationView.play()
                } else {
                    context.coordinator.displayLink?.stop()
                    animationView.pause()
                }
//            }
        }
    }

    static func dismantleUXView(_ view: UXViewType, coordinator: Coordinator) {
    }

    func makeCoordinator() -> MotionCoordinator {
        MotionCoordinator(animation: animation) { currentTime in
            //dbg(currentTime)
            animationTime = currentTime
        }
    }

    final class MotionCoordinator {
        let animationView: LottieAnimationView
        var displayLink: DisplayLink?

        init(animation: LottieAnimation, update: @escaping (TimeInterval) -> ()) {
            self.animationView = LottieAnimationView(animation: animation)
            //animationView.contentMode = .scaleAspectFit
            animationView.backgroundBehavior = .pauseAndRestore

            self.displayLink = DisplayLink(update: { [weak self] in
                if let self = self {
                    func updateMain() {
                        if let animation = self.animationView.animation, self.animationView.isAnimationPlaying {
                            update(self.animationView.realtimeAnimationProgress * animation.duration)
                        }
                    }

                    if Thread.isMainThread {
                        updateMain()
                    } else {
                        DispatchQueue.main.async { // called from background thread: CVDisplayLink (6)
                            updateMain()
                        }
                    }
                }
            })
        }
    }
}

/// Cross-platform `CADisplayLink`/`CVDisplayLink` interface.
public final class DisplayLink {
    private let callback: () -> Void
    private var displayLink: PlatformDisplayLink?

    public init(update: @escaping () -> Void) {
        self.callback = update
        createDisplayLink()
    }

    private func update() {
        callback()
    }

    func invalidate() {
        displayLink?.invalidate()
    }

    func stop() {
        displayLink?.stop()
    }

    func start() {
        displayLink?.start()
    }

    var isPaused: Bool = false {
        didSet {
            isPaused ? displayLink?.stop() : displayLink?.start()
        }
    }
}

extension DisplayLink {
#if os(macOS)
    func createDisplayLink() {
        func callback(link: CVDisplayLink, inNow: UnsafePointer<CVTimeStamp>, inOutputTime: UnsafePointer<CVTimeStamp>, flagsIn: CVOptionFlags, flagsOut: UnsafeMutablePointer<CVOptionFlags>, displayLinkContext: UnsafeMutableRawPointer?) -> CVReturn {
            unsafeBitCast(displayLinkContext, to: DisplayLink.self).update()
            return kCVReturnSuccess
        }

        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        guard let displayLink = displayLink else {
            fatalError("cannot create CVDisplayLink")
        }
        CVDisplayLinkSetOutputCallback(displayLink, callback, unsafeBitCast(self, to: UnsafeMutableRawPointer.self))
        CVDisplayLinkStart(displayLink)
    }
#else
    func createDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(newFrame(_:)))
        displayLink?.add(to: .main, forMode: RunLoop.Mode.common)
    }

    @objc private func newFrame(_ displayLink: CADisplayLink) {
        update()
    }
#endif
}

#if os(macOS)
typealias PlatformDisplayLink = CVDisplayLink
extension CVDisplayLink {
    func invalidate() {
        stop()
    }

    func start() {
        CVDisplayLinkStart(self)
    }

    func stop() {
        CVDisplayLinkStop(self)
    }
}
#else
typealias PlatformDisplayLink = CADisplayLink
extension CADisplayLink {
    func start() {
        isPaused = false
    }

    func stop() {
        isPaused = true
    }
}
#endif

