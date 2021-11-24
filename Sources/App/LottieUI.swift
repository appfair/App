//
//  File.swift
//  
//
//  Created by Marc Prud'hommeaux on 11/24/21.
//

import Foundation
import FairApp
import Lottie

struct MotionEffectView : UXViewRepresentable {
    typealias UXViewType = AnimationView
    let animation: Lottie.Animation
    @Binding var playing: Bool
    @Binding var loopMode: LottieLoopMode
    @Binding var animationSpeed: Double
    @Binding var animationTime: TimeInterval

    func makeUXView(context: Context) -> UXViewType {
        let view = AnimationView()
        view.animation = animation
        view.contentMode = .scaleAspectFit
        view.backgroundBehavior = .pauseAndRestore
        view.autoresizingMask = [.width, .height]

//        view.observe(\.currentTime) {
//
//        }
        return view
    }

    func updateUXView(_ view: UXViewType, context: Context) {
        view.loopMode = loopMode
        view.animationSpeed = animationSpeed
        view.currentTime = animationTime
        if view.isAnimationPlaying != playing {
            if playing {
                view.play()
            } else {
                view.pause()
            }
        }
    }

    static func dismantleUXView(_ view: UXViewType, coordinator: Coordinator) {
    }

    func makeCoordinator() -> MotionCoordinator {
        MotionCoordinator()
    }

    class MotionCoordinator {

    }
}
