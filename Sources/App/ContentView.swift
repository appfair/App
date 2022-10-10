import FairApp

/// The main content view for the app. This is the starting point for customizing you app's behavior.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct ContentView: View {
    /// The elements that will be displayed in the grid
    @State var elements = [0]
    @State var tapCount = 0
    @State var currentScore = 0
    @State var hovering = 0

    @Environment(\.locale) var locale
    @Environment(\.sizeCategory) var sizeCategory
    @Environment(\.accessibilityInvertColors) var invertColors
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityShowButtonShapes) var showButtonShapes
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor

    @EnvironmentObject var store: Store

    var body: some View {
        GeometryReader(content: contentView(withGeometry:))
            .animatingVectorOverlay(for: Double(currentScore), alignment: .topTrailing) { number in
                if store.showScore {
                    Text(Int64(number), format: .number)
                        .font(.largeTitle.monospacedDigit().bold())
                        .padding(.trailing)
                }
            }
    }

    func aligning(_ elements: [Int], to size: Int) -> [Int] {
        var elements = elements
        while elements.count > size {
            let max = elements.max() // trim out the max item
            elements.removeAll(where: { $0 == max })
        }
        while elements.count < size { elements.append(elements.count) }
        return elements
    }

    func contentView(withGeometry proxy: GeometryProxy) -> some View {
        let size = proxy.size
        let (width, height) = (size.width * 0.9, size.height * 0.9)
        let buttonSize = 44 * itemScale
        let (rows, columns) = (Int(floor(height / buttonSize)), Int(floor(width / buttonSize)))
        let (bwidth, bheight) = (height / .init(rows), width / .init(columns))
        let bspan = min(bwidth, bheight)

        let shuffle = { elements = (0..<rows*columns).shuffled() }

        func tapSpecial() {
            withAnimation(reduceMotion ? .none : .interpolatingSpring(mass: 1.0, stiffness: .init(1 + tapCount), damping: 0.4)) {
                shuffle()
                tapCount += 1
            }
            withAnimation(.easeOut(duration: 30)) {
                currentScore = tapCount * tapCount
            }
            withAnimation(.none) {
                if currentScore > store.highScore {
                    store.highScore = currentScore
                }
            }
        }

        func hue(for index: Int) -> Color {
            Color(hue: .init(index) / .init(rows * columns), saturation: 1.0, brightness: hovering == index ? 1.0 : 0.9, opacity: index == 0 ? 1.0 : 0.5)
        }

        func target(at i: Int) -> some View {
            Circle()
                .fill((i == 0) == invertColors ? hue(for: i) : .accentColor)
                .onTapGesture(count: 1, perform: tapSpecial)
                .disabled(i != 0)
                .zIndex(i == 0 ? 0 : 1) // tappable always on bottom
                .allowsHitTesting(i == 0)
                .frame(width: bspan, height: bspan)
                .overlay(i == 0 ? Bundle.fairIconView(color: .accentColor).mask(Circle()).allowsHitTesting(false) : nil)
                .padding(.vertical, 2)
                .whenHovering { if $0 { self.hovering = i } }
                .help(i > 0 ? Text("Find the Cloud Cuckoo among the Shapes", bundle: .module, comment: "help text") : Text("Keep tapping the Cuckoo Bird!", bundle: .module, comment: "help text"))
        }

        return LazyVGrid(columns: Array(repeating: GridItem(.fixed(bwidth)), count: columns), alignment: .center) {
            ForEach(aligning(elements, to: rows*columns), id: \.self, content: target(at:))
        }
    }

    private var itemScale: CGFloat {
        switch sizeCategory {
        case .extraSmall: return 0.6
        case .small: return 0.8
        case .medium, .accessibilityMedium: return 1.0
        case .large, .accessibilityLarge: return 1.2
        case .extraLarge, .accessibilityExtraLarge: return 1.4
        case .extraExtraLarge, .accessibilityExtraExtraLarge: return 1.6
        case .extraExtraExtraLarge, .accessibilityExtraExtraExtraLarge: return 1.8
        @unknown default: return 1.0
        }
    }
}

extension View {
    /// Install a hover action on platforms that support it
    func whenHovering(perform action: @escaping (Bool) -> ()) -> some View {
        #if os(macOS) || os(iOS)
        return self.onHover(perform: action)
        #else
        return self
        #endif
    }
}


