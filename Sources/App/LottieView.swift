import FairApp
import Lottie

public struct LottieView: View {
    let animation: Lottie.Animation
    fileprivate var _loopMode: Lottie.LottieLoopMode?
    fileprivate var _animationSpan: CGFloat?
    #if os(iOS)
    public typealias CMode = UXView.ContentMode
    #else
    public typealias CMode = LottieContentMode
    #endif


    fileprivate var _contentMode: CMode?

    public init(animation: Lottie.Animation) {
        self.animation = animation
    }

    public var body: some View {
        GeometryReader { proxy in
            LottieViewRepresentable(source: self)
                .frame(width: _animationSpan == nil ? nil : proxy.size.width * _animationSpan!)
        }
    }

    /// Changes the loop mode.
    public func loopMode(_ mode: Lottie.LottieLoopMode?) -> Self {
        var view = self
        view._loopMode = mode
        return view
    }

    /// Changes the loop mode.
    public func contentMode(_ mode: CMode?) -> Self {
        var view = self
        view._contentMode = mode
        return view
    }

    /// Changes the loop mode.
    public func animationSpan(_ span: CGFloat?) -> Self {
        var view = self
        view._animationSpan = span
        return view
    }
}

private struct LottieViewRepresentable : UXViewRepresentable {
    let source: LottieView
    //typealias UXViewType = AnimationView
    typealias UXViewType = UXView

    func makeUXView(context: Context) -> UXViewType {
        let container = UXView()
        #if os(macOS)
        container.autoresizingMask = [.height, .width]
        #else
        container.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        #endif
        container.translatesAutoresizingMaskIntoConstraints = true
        let animationView = makeAnimationView(context: context)
        container.addSubview(animationView)
        return container
    }

    func makeAnimationView(context: Context) -> AnimationView {
        let animationView = AnimationView()

        #if os(macOS)
        animationView.autoresizingMask = [.height, .width]
        #else
        animationView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        #endif
        animationView.translatesAutoresizingMaskIntoConstraints = true

        animationView.animation = source.animation

        if let loopMode = source._loopMode {
            animationView.loopMode = loopMode
        }
        if let contentMode = source._contentMode {
            animationView.contentMode = contentMode
        }

        animationView.play() // TODO: add start/stop controls

        return animationView
    }

    func updateUXView(_ view: UXViewType, context: Context) {
    }

    static func dismantleUXView(_ view: UXViewType, coordinator: ()) {
        //view.stop()
    }

//    func updateUIView(_ uiView: UXViewType, context: Context) {
//
//    }
}

struct AnimatedBannerItem : View {
    let item: BannerItem

    var body: some View {
        VStack {
            Text(atx: item.title)
                .font(.title)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding()
                .foregroundColor(item.foregroundColor?.systemColor)
            HStack(alignment: .top) {
                if item.subtitleTrailing != true, let subtitle = item.subtitle {
                    sub(subtitle, leading: true)
                }
                if let animation = item.animation {
                    LottieView(animation: animation)
                        .loopMode(.loop)
                        .contentMode(.scaleAspectFit)
                        //.animationSpan(0.3)
                        //.frame(width: 300)
                        //.frame(minHeight: 100)
                }
                if item.subtitleTrailing == true, let subtitle = item.subtitle {
                    sub(subtitle, leading: false)
                }
            }
            if let body = item.body {
                Text(atx: body)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .foregroundColor(item.foregroundColor?.systemColor)
            }
        }
    }

    private func sub(_ string: String, leading: Bool) -> some View {
        Text(atx: string)
            .multilineTextAlignment(!leading ? .leading : .trailing)
            .font(.title3)
            .foregroundColor(item.foregroundColor?.systemColor)
            .frame(maxWidth: .infinity)
            .frame(alignment: !leading ? .leading : .trailing)
    }

}

/// An item that contains a title, subtitle, and optional animation
public struct BannerItem : Codable, Identifiable {
    public var id: UUID
    public var title: String
    public var subtitle: String? = nil
    public var subtitleTrailing: Bool?
    public var foregroundColor: BannerColor? = nil
    public var backgroundColors: [BannerColor]? = nil
    public var animation: Lottie.Animation? = nil
    public var body: String? = nil

    public var background: some View {
        backgroundColors?.first?.systemColor
    }

    public func trailing(_ trailing: Bool) -> Self {
        var item = self
        item.subtitleTrailing = trailing
        return item
    }

    public struct BannerColor : Codable {
        public typealias HexString = String
        public let color: XOr<SystemColor>.Or<HexString>

        public init(_ color: SystemColor) {
            self.color = .init(color)
        }

        public var systemColor: SwiftUI.Color? {
            switch color {
            case .p(let color): return color.systemColor
            case .q(let hex): return HexColor(hexString: hex)?.sRGBColor()
            }
        }

        public enum SystemColor : String, Codable {
            case red
            case orange
            case yellow
            case green
            case mint
            case teal
            case cyan
            case blue
            case indigo
            case purple
            case pink
            case brown
            case white
            case gray
            case black
            case clear
            case primary
            case secondary

            public var systemColor: SwiftUI.Color {
                switch self {
                case .red: return .red
                case .orange: return .orange
                case .yellow: return .yellow
                case .green: return .green
                case .mint: return .mint
                case .teal: return .teal
                case .cyan: return .cyan
                case .blue: return .blue
                case .indigo: return .indigo
                case .purple: return .purple
                case .pink: return .pink
                case .brown: return .brown
                case .white: return .white
                case .gray: return .gray
                case .black: return .black
                case .clear: return .clear
                case .primary: return .primary
                case .secondary: return .secondary
                }
            }
        }

    }
}
