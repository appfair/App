import SwiftUI
import Lottie

/// A view that displays a Lottie Animation
public struct MotionEffectView : View {
    let animation: Lottie.Animation
    @Binding var playing: Bool
    @Binding var loopMode: LottieLoopMode
    @Binding var animationSpeed: Double
    @Binding var animationTime: TimeInterval

    public init(animation: Lottie.Animation, playing: Binding<Bool>, loopMode: Binding<LottieLoopMode> = .constant(.loop), animationSpeed: Binding<Double> = .constant(1.0), animationTime: Binding<TimeInterval> = .constant(0.0)) {
        self.animation = animation
        self._playing = playing
        self._loopMode = loopMode
        self._animationSpeed = animationSpeed
        self._animationTime = animationTime
    }

    public var body: some View {
        MotionEffectViewRepresentable(animation: animation, playing: $playing, loopMode: $loopMode, animationSpeed: $animationSpeed, animationTime: $animationTime)
    }
}


/// A view that displays a Lottie Animation
struct MotionEffectViewRepresentable : UXViewRepresentable {
    typealias UXViewType = UXView
    let animation: Lottie.Animation
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
            if playing {
                context.coordinator.displayLink?.start()
                animationView.play()
            } else {
                context.coordinator.displayLink?.stop()
                animationView.pause()
            }
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

    @MainActor final class MotionCoordinator {
        let animationView: AnimationView
        var displayLink: DisplayLink?

        init(animation: Lottie.Animation, update: @escaping (TimeInterval) -> ()) {
            self.animationView = AnimationView(animation: animation)
            //animationView.contentMode = .scaleAspectFit
            animationView.backgroundBehavior = .pauseAndRestore

            self.displayLink = DisplayLink(update: { [weak self] in
                if let self = self {
                    DispatchQueue.main.async { // called from background thread: CVDisplayLink (6)
                        if let animation = self.animationView.animation, self.animationView.isAnimationPlaying {
                            update(self.animationView.realtimeAnimationProgress * animation.duration)
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



#if canImport(UIKit)
import UIKit
typealias UXView = UIView
typealias UXViewController = UIViewController
typealias UXViewRepresentableContext = UIViewRepresentableContext
typealias UXHostingController = UIHostingController
#elseif canImport(AppKit)
import AppKit
typealias UXView = NSView
typealias UXViewController = NSViewController
typealias UXViewRepresentableContext = NSViewRepresentableContext
typealias UXHostingController = NSHostingController
#endif


#if canImport(AppKit)
/// AppKit adapter for `NSViewRepresentable`
protocol UXViewRepresentable : NSViewRepresentable {
    associatedtype UXViewType : NSView
    func makeUXView(context: Self.Context) -> Self.UXViewType
    func updateUXView(_ view: Self.UXViewType, context: Self.Context)
    static func dismantleUXView(_ view: Self.UXViewType, coordinator: Self.Coordinator)
}
#elseif canImport(UIKit)
/// UIKit adapter for `UIViewRepresentable`
protocol UXViewRepresentable : UIViewRepresentable {
    associatedtype UXViewType : UIView
    func makeUXView(context: Self.Context) ->  Self.UXViewType
    func updateUXView(_ view:  Self.UXViewType, context: Self.Context)
    static func dismantleUXView(_ view:  Self.UXViewType, coordinator: Self.Coordinator)
}
#endif

extension UXViewRepresentable {

    #if canImport(UIKit)
    // MARK: UIKit UIViewRepresentable support

    func makeUIView(context: Self.Context) -> Self.UXViewType {
        return makeUXView(context: context)
    }

    func updateUIView(_ uiView: Self.UXViewType, context: Self.Context) {
        updateUXView(uiView, context: context)
    }

    static func dismantleUIView(_ uiView: Self.UXViewType, coordinator: Self.Coordinator) {
        Self.dismantleUXView(uiView, coordinator: coordinator)
    }
    #endif

    #if canImport(AppKit)
    // MARK: AppKit NSViewRepresentable support

    func makeNSView(context: Self.Context) -> Self.UXViewType {
        return makeUXView(context: context)
    }

    func updateNSView(_ nsView: Self.UXViewType, context: Self.Context) {
        updateUXView(nsView, context: context)
    }

    static func dismantleNSView(_ nsView: Self.UXViewType, coordinator: Self.Coordinator) {
        Self.dismantleUXView(nsView, coordinator: coordinator)
    }
    #endif
}

// MARK: ViewControllerRepresentable

#if canImport(AppKit)
/// AppKit adapter for `NSViewControllerRepresentable`
protocol UXViewControllerRepresentable : NSViewControllerRepresentable {
    associatedtype UXViewControllerType : NSViewController
    func makeUXViewController(context: Self.Context) -> Self.UXViewControllerType
    func updateUXViewController(_ controller: Self.UXViewControllerType, context: Self.Context)
    static func dismantleUXViewController(_ controller: Self.UXViewControllerType, coordinator: Self.Coordinator)
}
#elseif canImport(UIKit)
/// UIKit adapter for `UIViewControllerRepresentable`
protocol UXViewControllerRepresentable : UIViewControllerRepresentable {
    associatedtype UXViewControllerType : UIViewController
    func makeUXViewController(context: Self.Context) ->  Self.UXViewControllerType
    func updateUXViewController(_ controller:  Self.UXViewControllerType, context: Self.Context)
    static func dismantleUXViewController(_ controller:  Self.UXViewControllerType, coordinator: Self.Coordinator)
}
#endif


extension UXViewControllerRepresentable {

    #if canImport(UIKit)
    // MARK: UIKit UIViewControllerRepresentable support

    func makeUIViewController(context: Self.Context) -> Self.UXViewControllerType {
        return makeUXViewController(context: context)
    }

    func updateUIViewController(_ uiViewController: Self.UXViewControllerType, context: Self.Context) {
        updateUXViewController(uiViewController, context: context)
    }

    static func dismantleUIViewController(_ uiViewController: Self.UXViewControllerType, coordinator: Self.Coordinator) {
        Self.dismantleUXViewController(uiViewController, coordinator: coordinator)
    }
    #elseif canImport(AppKit)
    // MARK: AppKit NSViewControllerRepresentable support

    func makeNSViewController(context: Self.Context) -> Self.UXViewControllerType {
        return makeUXViewController(context: context)
    }

    func updateNSViewController(_ nsViewController: Self.UXViewControllerType, context: Self.Context) {
        updateUXViewController(nsViewController, context: context)
    }

    static func dismantleNSViewController(_ nsViewController: Self.UXViewControllerType, coordinator: Self.Coordinator) {
        Self.dismantleUXViewController(nsViewController, coordinator: coordinator)
    }
    #endif
}

