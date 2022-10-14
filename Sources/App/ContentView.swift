import FairApp

/// The main content view for the app. This is the starting point for customizing you app's behavior.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct ContentView: View {
    @EnvironmentObject var store: Store
    var body: some View {
        // assign an ID to allow re-setting the game's state from the settings
        GameView().id(store.gameID)
    }
}

/// The main content view for the app. This is the starting point for customizing you app's behavior.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct GameView: View {
    /// The elements that will be displayed in the grid
    @State var elements = [0]
    @State var tapCount = 0
    @State var currentScore = 0

    @Environment(\.locale) var locale
    @Environment(\.sizeCategory) var sizeCategory
    @Environment(\.accessibilityInvertColors) var invertColors
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityShowButtonShapes) var showButtonShapes
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor

    @EnvironmentObject var store: Store

    var body: some View {
        GeometryReader(content: gameGrid(withGeometry:))
            .edgesIgnoringSafeArea(.all)
            .animatingVectorOverlay(for: Double(currentScore), alignment: .top) { score in
                Text(score: score, locale: store.currencyScore ? locale : nil)
                    .font(.largeTitle.monospacedDigit().weight(.semibold))
                    .padding(.trailing)
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

    var dotCount: Int {
        ((tapCount * tapCount) + 2)
    }

    func gameGrid(withGeometry proxy: GeometryProxy) -> some View {
        // the fixed size of the dots
        let span = 80.0

        return ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: span, maximum: span))], alignment: .center) {
                ForEach(aligning(elements, to: dotCount), id: \.self, content: target(at:))
            }
        }
        .refreshable { // only seems to work on iOS 16+
            dbg("refresh")
            if tapCount > 0 {
                withAnimation {
                    shuffle()
                    tapCount -= 1
                    updateCurrentScore()
                }
            }
        }

        func target(at i: Int) -> some View {
            Button(action: tapSpecial) {
                Circle()
                    .fill((i == 0) == invertColors ? hue(for: i) : .accentColor)
                    .overlay(i == 0 ? Bundle.fairIconView(color: .accentColor).mask(Circle()) : nil)
            }
            .frame(width: span, height: span)
            .zIndex(i == 0 ? 1 : 0) // tappable always on top
            .disabled(i != 0)
            .allowsHitTesting(i == 0)
            #if os(iOS)
            .hoverEffect(.highlight)
            #endif
            .buttonStyle(.zoomable(level: min(1.5, sqrt(Double(tapCount + 2)))))
            .transition(.scale)
            .help(i > 0 ? Text("Find the Cloud Cuckoo among the Shapes", bundle: .module, comment: "help text") : Text("Keep tapping the Cuckoo Bird!", bundle: .module, comment: "help text"))
        }

        func shuffle(ensureSpecialMoved: Bool = true) {
            let specialIndex = ensureSpecialMoved ? elements.firstIndex(of: 0) : nil
            elements = (0..<dotCount).shuffled()
            while let specialIndex = specialIndex, elements.firstIndex(of: 0) == specialIndex {
                // keep shuffling until the special moves
                elements = (0..<dotCount).shuffled()
            }
        }

        func updateCurrentScore() {
            // similar to `withAnimation(.easeOut)`, but with a very long trail-off
            withAnimation(.interactiveSpring(response: 3, dampingFraction: 3, blendDuration: 30.0)) {
                currentScore = tapCount * tapCount
            }
        }

        func tapSpecial() {
            withAnimation(reduceMotion ? .none : .interpolatingSpring(mass: 1.0, stiffness: .init(1 + tapCount), damping: 1.0)) {
                shuffle()
                tapCount += 1
            }

            updateCurrentScore()

            withAnimation(.none) {
                if currentScore > store.highScore {
                    store.highScore = currentScore
                }
            }
        }

        func hue(for index: Int) -> Color {
            Color(hue: .init(index) / .init(dotCount), saturation: 1.0, brightness: 1.0, opacity: index == 0 ? 1.0 : 0.5)
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

extension Text {
    init(score number: Double, locale: Locale?) {
        if let code = locale?.currencyCode {
            self = Text(Double(number), format: .currency(code: code))
        } else {
            self = Text(Int64(number), format: .number)
        }
    }
}
