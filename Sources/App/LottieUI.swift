import FairApp
import Lottie

public struct MotionEffectView : UXViewRepresentable {
    public typealias UXViewType = UXView
    let animation: Lottie.Animation
    @Binding var playing: Bool
    @Binding var loopMode: LottieLoopMode
    @Binding var animationSpeed: Double
    @Binding var animationTime: TimeInterval

    public func makeUXView(context: Context) -> UXViewType {
        context.coordinator.animationView
    }

    public func updateUXView(_ view: UXViewType, context: Context) {
        let animationView = context.coordinator.animationView
        animationView.loopMode = loopMode
        animationView.animationSpeed = animationSpeed
        animationView.currentTime = animationTime
        if animationView.isAnimationPlaying != playing {
            if playing {
                context.coordinator.displayLink?.start()
                animationView.play()
            } else {
                context.coordinator.displayLink?.stop()
                animationView.pause()
            }
        }
    }

    public static func dismantleUXView(_ view: UXViewType, coordinator: Coordinator) {
    }

    public func makeCoordinator() -> MotionCoordinator {
        MotionCoordinator(animation: animation) { currentTime in
            //dbg(currentTime)
            animationTime = currentTime
        }
    }

    @MainActor public final class MotionCoordinator {
        public let animationView: AnimationView
        var displayLink: DisplayLink?

        public init(animation: Lottie.Animation, update: @escaping (TimeInterval) -> ()) {
            self.animationView = AnimationView(animation: animation)
            animationView.contentMode = .scaleAspectFit
            animationView.backgroundBehavior = .pauseAndRestore

            self.displayLink = DisplayLink(update: { [weak self] in
                if let self = self {
                    assert(self.animationView.animation != nil)
                    //dbg(self.animationView.realtimeAnimationFrame)
                    update(self.animationView.currentTime) // FIXME: only seems to update at the start & end
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


// MARK: Parochial (package-local) Utilities

/// Returns the localized string for the current module.
///
/// - Note: This is boilerplate package-local code that could be copied
///  to any Swift package with localized strings.
internal func loc(_ key: String, tableName: String? = nil, comment: String? = nil) -> String {
    // TODO: use StringLocalizationKey
    NSLocalizedString(key, tableName: tableName, bundle: .module, comment: comment ?? "")
}

/// Work-in-Progress marker
@available(*, deprecated, message: "work in progress")
internal func wip<T>(_ value: T) -> T { value }

/// Intercept `LocalizedStringKey` constructor and forward it to ``SwiftUI.Text/init(_:bundle)``
@usableFromInline internal func Text(_ string: LocalizedStringKey) -> SwiftUI.Text {
    SwiftUI.Text(string, bundle: .module)
}
